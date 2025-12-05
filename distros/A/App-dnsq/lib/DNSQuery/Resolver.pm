package DNSQuery::Resolver;
use strict;
use warnings;
use Net::DNS;
use Time::HiRes qw(time);
use DNSQuery::Validator qw(:all);
use DNSQuery::Constants qw(:all);
use DNSQuery::Cache;

our $VERSION = '1.1.0';

sub new {
    my ($class, $config) = @_;
    
    # Validate configuration using Validator module
    my ($valid, $error);
    
    ($valid, $error) = validate_port($config->{port});
    die "Invalid port: $error\n" unless $valid;
    
    ($valid, $error) = validate_timeout($config->{timeout});
    die "Invalid timeout: $error\n" unless $valid;
    
    ($valid, $error) = validate_retries($config->{retries});
    die "Invalid retries: $error\n" unless $valid;
    
    my %resolver_opts = (
        port        => $config->{port},
        tcp_timeout => $config->{timeout},
        udp_timeout => $config->{timeout},
        retry       => $config->{retries},
        usevc       => ($config->{protocol} eq 'tcp') ? 1 : 0,
        recurse     => $config->{recurse},
        dnssec      => $config->{dnssec},
    );
    
    # Validate and set nameserver if provided
    if ($config->{server}) {
        my ($valid_ip) = validate_ip($config->{server});
        my ($valid_domain) = validate_domain($config->{server});
        
        die "Invalid server address: $config->{server}\n" 
            unless $valid_ip || $valid_domain;
        
        $resolver_opts{nameservers} = [$config->{server}];
    }
    
    my $resolver = Net::DNS::Resolver->new(%resolver_opts);
    
    # Initialize cache with TTL support and optional persistence
    my $cache = DNSQuery::Cache->new(
        max_size => $config->{cache_size} || $MAX_CACHE_SIZE,
        persist => $config->{cache_persist} || 0,
    );
    
    return bless {
        resolver => $resolver,
        config   => $config,
        cache    => $cache,
        stats    => {    # Query statistics
            total_queries => 0,
            cache_hits => 0,
            failed_queries => 0,
            total_time_ms => 0,
        },
    }, $class;
}

# Validation functions moved to DNSQuery::Validator module

sub query {
    my ($self, $domain, $type, $class) = @_;
    
    # Trim whitespace
    $domain =~ s/^\s+|\s+$//g if defined $domain;
    
    $type ||= $self->{config}{qtype};
    $class ||= $self->{config}{qclass};
    
    # Normalize type
    $type = uc($type) if defined $type;
    
    # Validate inputs using Validator module
    my ($valid, $error);
    
    ($valid, $error) = validate_domain($domain);
    return { error => $error } unless $valid;
    
    ($valid, $error) = validate_query_type($type);
    return { error => $error } unless $valid;
    
    ($valid, $error) = validate_query_class($class);
    return { error => $error } unless $valid;
    
    $self->{stats}{total_queries}++;
    
    # Check cache (now with TTL support)
    my $cache_key = "$domain:$type:$class";
    if (my $cached = $self->{cache}->get($cache_key)) {
        $self->{stats}{cache_hits}++;
        return { %$cached, cached => 1 };
    }
    
    # Query with retry and exponential backoff
    my $result = eval { $self->_query_with_retry($domain, $type, $class) };
    
    if ($@) {
        my $error = $@;
        chomp $error;
        $self->{stats}{failed_queries}++;
        return {
            packet => undef,
            query_time => 0,
            error => "Query failed: $error",
            attempts => 1,
        };
    }
    
    # Update statistics
    if ($result->{error}) {
        $self->{stats}{failed_queries}++;
    } elsif ($result->{query_time}) {
        $self->{stats}{total_time_ms} += $result->{query_time};
    }
    
    # Cache successful results with TTL from DNS response
    if ($result->{packet}) {
        my $ttl = $self->_get_min_ttl($result->{packet}) || $DEFAULT_CACHE_TTL;
        $self->{cache}->set($cache_key, $result, $ttl);
    }
    
    return $result;
}

sub _query_with_retry {
    my ($self, $domain, $type, $class) = @_;
    
    my $retries = $self->{config}{retries};
    my $backoff = 1;
    
    for my $attempt (0 .. $retries) {
        my $start_time = time();
        my $packet = eval { $self->{resolver}->send($domain, $type, $class) };
        my $query_time = int((time() - $start_time) * 1000);
        
        if ($packet) {
            return {
                packet     => $packet,
                query_time => $query_time,
                error      => undef,
                attempts   => $attempt + 1,
            };
        }
        
        # Don't sleep on last attempt
        if ($attempt < $retries) {
            select(undef, undef, undef, $backoff);
            $backoff *= 2;  # Exponential backoff
        }
    }
    
    return {
        packet     => undef,
        query_time => 0,
        error      => $self->{resolver}->errorstring || "Query failed after $retries retries",
        attempts   => $retries + 1,
    };
}

sub trace {
    my ($self, $domain) = @_;
    
    my ($valid, $error) = validate_domain($domain);
    unless ($valid) {
        warn "Trace: $error\n";
        return [];
    }
    
    my @root_servers = qw(
        198.41.0.4 199.9.14.201 192.33.4.12 199.7.91.13
        192.203.230.10 192.5.5.241 192.112.36.4 198.97.190.53
    );
    
    my @trace_results;
    my $current_server = $root_servers[0];
    my @labels = split(/\./, $domain);
    my $query_name = '';
    my $max_hops = 20;  # Prevent infinite loops
    my $hop_count = 0;
    
    for (my $i = $#labels; $i >= 0; $i--) {
        last if ++$hop_count > $max_hops;
        
        $query_name = $labels[$i] . ($query_name ? ".$query_name" : '');
        
        my $resolver = Net::DNS::Resolver->new(
            nameservers => [$current_server],
            recurse => 0,
            udp_timeout => $self->{config}{timeout},
            tcp_timeout => $self->{config}{timeout},
        );
        
        my $packet = eval { $resolver->send($query_name, 'NS') };
        
        push @trace_results, {
            server => $current_server,
            query  => $query_name,
            packet => $packet,
            error  => $packet ? undef : ($resolver->errorstring || $@),
        };
        
        last unless $packet;
        
        # Find next server from additional section first (more efficient)
        my $next_server;
        if ($i > 0) {
            foreach my $rr ($packet->additional) {
                if ($rr->type eq 'A' && $rr->can('address')) {
                    $next_server = $rr->address;
                    last;
                }
            }
            
            # Fallback: resolve NS from authority section
            unless ($next_server) {
                foreach my $rr ($packet->authority) {
                    if ($rr->type eq 'NS' && $rr->can('nsdname')) {
                        my $ns_name = $rr->nsdname;
                        my $ns_resolver = Net::DNS::Resolver->new(
                            udp_timeout => $self->{config}{timeout},
                        );
                        my $ns_packet = eval { $ns_resolver->send($ns_name, 'A') };
                        if ($ns_packet && $ns_packet->header->ancount > 0) {
                            my ($ns_rr) = $ns_packet->answer;
                            if ($ns_rr && $ns_rr->can('address')) {
                                $next_server = $ns_rr->address;
                                last;
                            }
                        }
                    }
                }
            }
            
            last unless $next_server;
            $current_server = $next_server;
        }
    }
    
    return \@trace_results;
}

sub get_stats {
    my ($self) = @_;
    
    # Merge resolver stats with cache stats
    my $cache_stats = $self->{cache}->get_stats();
    
    return {
        %{$self->{stats}},
        cache_size => $cache_stats->{size},
        cache_max_size => $cache_stats->{max_size},
        cache_hit_rate => $cache_stats->{hit_rate},
        cache_evictions => $cache_stats->{evictions},
    };
}

sub reset_stats {
    my ($self) = @_;
    $self->{stats} = {
        total_queries => 0,
        cache_hits => 0,
        failed_queries => 0,
        total_time_ms => 0,
    };
}

sub clear_cache {
    my ($self) = @_;
    $self->{cache}->clear();
}

sub _get_min_ttl {
    my ($self, $packet) = @_;
    
    return undef unless $packet;
    
    my $min_ttl;
    
    eval {
        foreach my $rr ($packet->answer) {
            next unless $rr && $rr->can('ttl');
            my $ttl = $rr->ttl;
            $min_ttl = $ttl if !defined($min_ttl) || $ttl < $min_ttl;
        }
    };
    
    return $min_ttl;
}

1;
