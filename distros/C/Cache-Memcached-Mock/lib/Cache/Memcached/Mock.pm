# ABSTRACT: A mock class for Cache::Memcached
package Cache::Memcached::Mock;

use strict;
use warnings;
use bytes;
use Storable ();

our $VERSION = '0.07';

sub VALUE ()     {0}
sub TIMESTAMP () {1}
sub REFERENCE () {2}

# All instances share the memory space
our %MEMCACHE_STORAGE = ();

sub add {
    my ($self, $key, $value, $expiry_time) = @_;
    if (exists $MEMCACHE_STORAGE{$key}) {
        return;
    }
    return $self->set($key, $value, $expiry_time);
}

sub new {

    my ($class, $options) = @_;

    $class = ref $class || $class;

    $options ||= {};

    # Default memcached size limit
    $options->{size_limit} ||= 1024 * 1024;

    # Default unsigned integer bit width when incrementing/decrementing.
    $options->{bit_width} ||= 32;

    my $self = { %{$options} };

    bless $self, $class;
    $self->flush_all();

    return $self;
}

sub delete {
    my ($self, $key) = @_;
    if (!exists $MEMCACHE_STORAGE{$key}) {
        return;
    }
    delete $MEMCACHE_STORAGE{$key};
    return 1;
}

sub disconnect_all {
    return    # noop
}

sub flush_all {
    %MEMCACHE_STORAGE = ();
    return;
}

sub get {
    my ($self, $key) = @_;
    return $self->get_multi($key)->{$key};
}

sub get_multi {
    my ($self, @keys) = @_;
    my %pairs;

    for my $key (@keys) {
        if (exists $MEMCACHE_STORAGE{$key}) {

            # Check if value had an expire time
            my $struct      = $MEMCACHE_STORAGE{$key};
            my $expiry_time = $struct->[TIMESTAMP];

            if (defined $expiry_time && (time > $expiry_time)) {
                delete $MEMCACHE_STORAGE{$key};
            }
            else {
                $pairs{$key}
                  = $struct->[REFERENCE]
                  ? Storable::thaw($struct->[VALUE])
                  : $struct->[VALUE];
            }
        }
    }

    return \%pairs;
}

sub replace {
    my ($self, $key, $value, $expiry_time) = @_;
    if (!exists $MEMCACHE_STORAGE{$key}) {
        return;
    }
    return $self->set($key, $value, $expiry_time);
}

sub set {
    my ($self, $key, $value, $expiry_time) = @_;
    my $size_limit = $self->_size_limit();
    my $is_ref     = 0;

    if (ref $value) {
        $is_ref = 1;
        $value  = Storable::nfreeze($value);
    }

    # Can't store values longer than (default) 1Mb limit
    if (defined $value and bytes::length($value) > $size_limit) {
        return;
    }

    if ($expiry_time) {
        $expiry_time += time();
    }
    else {
        $expiry_time = undef;
    }

    $MEMCACHE_STORAGE{$key} = [ $value, $expiry_time, $is_ref ];

    return 1;
}

sub set_servers {
    my ($self, $servers) = @_;
    return ($self->{servers} = $servers);
}

sub set_compress_threshold {
    my ($self, $comp_thr) = @_;
    return ($self->{compress_threshold} = $comp_thr - 0);
}

# XXX NIY
#sub set_readonly {
#    my ($self, $readonly) = @_;
#    return ($self->{readonly} = $readonly);
#}

sub incr {
    my ($self, $key, $offset) = @_;
    return $self->_incr_or_decr($key, $offset, '_add');
}

sub decr {
    my ($self, $key, $offset) = @_;
    return $self->_incr_or_decr($key, $offset, '_subtract');
}

sub _add {
    my ($self, $x, $y) = @_;
    my $result = $self->_to_uint($x) + $self->_to_uint($y);
    
    return $result % (2 ** $self->_bit_width());
}

sub _bit_width {
    my ($self) = @_;
    return $self->{bit_width};
}

sub _incr_or_decr {
    my ($self, $key, $offset, $operation) = @_;
    return unless exists $MEMCACHE_STORAGE{$key};
    
    $offset = 1 unless defined $offset;
    my $new_val = $self->$operation($MEMCACHE_STORAGE{$key}->[VALUE], $offset);
    
    return ($MEMCACHE_STORAGE{$key}->[VALUE] = $new_val);
}

sub _size_limit {
    my ($self) = @_;
    return $self->{size_limit};
}

sub _subtract {
    my ($self, $x, $y) = @_;
    my $result = $self->_to_uint($x) - $self->_to_uint($y);
    
    return $result <= 0 ? 0 : $result % (2 ** $self->_bit_width());
}

sub _to_uint {
    my ($self, $n) = @_;
    return $n & (2 ** $self->_bit_width() - 1);
}

1;

__END__

=pod

=head1 NAME

Cache::Memcached::Mock - A mock class for Cache::Memcached

=head1 VERSION

version 0.07

=head1 SYNOPSIS

Supports only a subset of L<Cache::Memcached> functionality.

    my $cache = Cache::Memcached::Mock->new();

    # You can also set the limit for the size of the values
    # Default real memcached limit is 1Mb
    $cache = Cache::Memcached::Mock->new({ size_limit => 65536 }); # bytes

    # Or the default bit width when incrementing/decrementing unsigned integers.
    $cache = Cache::Memcached::Mock->new({ bit_width => 32 });

    # Values are stored in a process global hash
    my $value = $cache->get('somekey');
    my $set_ok = $cache->set('someotherkey', 'somevalue');
    $set_ok = $cache->set('someotherkey', 'somevalue', 60);  # seconds

    my $ok = $cache->add('another_key', 'another_value');
    $ok = $cache->replace('another_key', 'another_value');

    $cache->incr('some-counter');
    $cache->decr('some-counter');
    $cache->incr('some-counter', 2);

    # new() also flushes all values
    $cache->flush_all();

    my $pairs = $cache->get_multi('key1', 'key2', '...');

=head1 DESCRIPTION

This class can be used to mock the real L<Cache::Memcached> object when you don't have
a memcached server running (and you don't want to run one actually), but you need
the functionality to be there.

I used it in unit tests, where I had to perform several tests against a given
memcached instance, to see that certain values were really created or deleted.

Instead of having a memcached instance running for every server where I need
unit tests running, or using a centralized memcached daemon, I can just pass
a L<Cache::Memcached::Mock> instance wherever a L<Cache::Memcached> one is required.

This is an example of how you would use this mock class:

    # Use the "Mock" one instead of C::MC
    my $memc = Cache::Memcached::Mock->new();

    my $business_object = My::Business->new({
        memcached_instance => $memc
    });

    $business_object->do_something_that_involves_caching();

In short, this allows you to avoid setting up a real memcached instance
whenever you don't necessarily need one, for example unit testing.

=head1 NAME

Cache::Memcached::Mock - A mock class for Cache::Memcached

=head1 VERSION

version 0.06

=head1 AUTHOR

  Cosimo Streppone <cosimo@opera.com>
  Márcio Faustino <marciof@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Opera Software ASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Cosimo Streppone <cosimo@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Opera Software ASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
