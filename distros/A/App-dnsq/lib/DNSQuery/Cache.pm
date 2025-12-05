package DNSQuery::Cache;
use strict;
use warnings;
use Time::HiRes qw(time);
use Storable qw(store retrieve);
use File::Spec;
use POSIX qw(mkfifo);

our $VERSION = '1.1.0';

=head1 NAME

DNSQuery::Cache - DNS query cache with TTL support and disk persistence

=head1 SYNOPSIS

    use DNSQuery::Cache;
    
    my $cache = DNSQuery::Cache->new(
        max_size => 100,
        persist => 1,
        cache_file => '/tmp/dnsq_cache.dat',
    );
    
    $cache->set($key, $value, $ttl);
    my $value = $cache->get($key);
    $cache->clear();

=head1 DESCRIPTION

Provides an LRU cache with TTL support and optional disk persistence.

=cut

sub new {
    my ($class, %opts) = @_;
    
    my $self = bless {
        cache => {},
        max_size => $opts{max_size} || 100,
        persist => $opts{persist} || 0,
        cache_file => $opts{cache_file} || File::Spec->catfile(
            File::Spec->tmpdir(), 
            "dnsq_cache_$<.dat"
        ),
        stats => {
            hits => 0,
            misses => 0,
            evictions => 0,
        },
    }, $class;
    
    # Load from disk if persistence is enabled
    if ($self->{persist} && -f $self->{cache_file}) {
        $self->_load_from_disk();
    }
    
    return $self;
}

=head2 get($key)

Retrieve a value from cache. Returns undef if not found or expired.

=cut

sub get {
    my ($self, $key) = @_;
    
    return undef unless defined $key;
    
    my $entry = $self->{cache}{$key};
    
    unless ($entry) {
        $self->{stats}{misses}++;
        return undef;
    }
    
    # Check if expired
    my $now = time();
    if ($now > $entry->{expires_at}) {
        delete $self->{cache}{$key};
        $self->{stats}{misses}++;
        return undef;
    }
    
    # Update access time for LRU
    $entry->{last_access} = $now;
    $self->{stats}{hits}++;
    
    return $entry->{value};
}

=head2 set($key, $value, $ttl)

Store a value in cache with the specified TTL (in seconds).
If TTL is not provided, uses a default of 60 seconds.

=cut

sub set {
    my ($self, $key, $value, $ttl) = @_;
    
    return unless defined $key && defined $value;
    
    $ttl ||= 60;  # Default TTL
    my $now = time();
    
    $self->{cache}{$key} = {
        value => $value,
        expires_at => $now + $ttl,
        last_access => $now,
        created_at => $now,
    };
    
    # Enforce size limit with LRU eviction
    $self->_enforce_size_limit();
    
    # Persist to disk if enabled
    $self->_save_to_disk() if $self->{persist};
    
    return 1;
}

=head2 delete($key)

Remove a specific entry from cache.

=cut

sub delete {
    my ($self, $key) = @_;
    
    return unless defined $key;
    
    delete $self->{cache}{$key};
    $self->_save_to_disk() if $self->{persist};
    
    return 1;
}

=head2 clear()

Clear all entries from cache.

=cut

sub clear {
    my ($self) = @_;
    
    $self->{cache} = {};
    $self->{stats} = {
        hits => 0,
        misses => 0,
        evictions => 0,
    };
    
    # Remove cache file if it exists
    if ($self->{persist} && -f $self->{cache_file}) {
        unlink $self->{cache_file};
    }
    
    return 1;
}

=head2 size()

Return the current number of entries in cache.

=cut

sub size {
    my ($self) = @_;
    return scalar keys %{$self->{cache}};
}

=head2 get_stats()

Return cache statistics.

=cut

sub get_stats {
    my ($self) = @_;
    
    my $total = $self->{stats}{hits} + $self->{stats}{misses};
    my $hit_rate = $total > 0 ? ($self->{stats}{hits} / $total) * 100 : 0;
    
    return {
        %{$self->{stats}},
        size => $self->size(),
        max_size => $self->{max_size},
        hit_rate => $hit_rate,
    };
}

=head2 cleanup_expired()

Remove all expired entries from cache.

=cut

sub cleanup_expired {
    my ($self) = @_;
    
    my $now = time();
    my $removed = 0;
    
    foreach my $key (keys %{$self->{cache}}) {
        if ($now > $self->{cache}{$key}{expires_at}) {
            delete $self->{cache}{$key};
            $removed++;
        }
    }
    
    $self->_save_to_disk() if $self->{persist} && $removed > 0;
    
    return $removed;
}

# Private methods

sub _enforce_size_limit {
    my ($self) = @_;
    
    my $cache = $self->{cache};
    my $max_size = $self->{max_size};
    
    while (keys %$cache > $max_size) {
        # Find least recently accessed entry
        my $lru_key;
        my $lru_time = time();
        
        foreach my $key (keys %$cache) {
            if ($cache->{$key}{last_access} < $lru_time) {
                $lru_time = $cache->{$key}{last_access};
                $lru_key = $key;
            }
        }
        
        delete $cache->{$lru_key} if $lru_key;
        $self->{stats}{evictions}++;
    }
}

sub _save_to_disk {
    my ($self) = @_;
    
    return unless $self->{persist};
    
    eval {
        # Clean up expired entries before saving
        $self->cleanup_expired();
        
        store($self->{cache}, $self->{cache_file});
    };
    
    warn "Failed to save cache to disk: $@" if $@;
}

sub _load_from_disk {
    my ($self) = @_;
    
    return unless -f $self->{cache_file};
    
    eval {
        my $loaded = retrieve($self->{cache_file});
        
        if ($loaded && ref($loaded) eq 'HASH') {
            $self->{cache} = $loaded;
            
            # Clean up expired entries after loading
            $self->cleanup_expired();
        }
    };
    
    if ($@) {
        warn "Failed to load cache from disk: $@";
        $self->{cache} = {};
    }
}

sub DESTROY {
    my ($self) = @_;
    
    # Save cache on destruction if persistence is enabled
    $self->_save_to_disk() if $self->{persist};
}

1;

__END__

=head1 AUTHOR

DNSQuery Project

=head1 LICENSE

MIT License

=cut
