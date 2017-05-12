package Cache::Elasticache::Memcache;

use strict;
use warnings;

=pod

=for HTML <a href="https://travis-ci.org/zebardy/cache-elasticache-memcache"><img src="https://travis-ci.org/zebardy/cache-elasticache-memcache.svg?branch=master"></a>

=head1 NAME

Cache::Elasticache::Memcache - A wrapper for L<Cache::Memacached::Fast> with support for AWS's auto reconfiguration mechanism

=head1 SYNOPSIS

    use Cache::Elasticache::Memcache;

    my $memd = new Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar',
        update_period => 180,
        # All other options are passed on to Cache::Memcached::Fast
        ...
    });

    # Will update the server list from the configuration endpoint
    $memd->updateServers();

    # Will update the serverlist from the configuration endpoint if the time since
    # the last time the server list was checked is greater than the update period
    # specified when the $memd object was created.
    $memd->checkServers();

    # Class method to retrieve a server list from a configuration endpoint.
    Cache::Elasticache::Memcache->getServersFromEndpoint('foo.bar');

    # All other supported methods are handled by Cache::Memcached::Fast

    # N.B. This library is currently under development

=head1 DESCRIPTION

A wrapper for L<Cache::Memacached::Fast> with support for AWS's auto reconfiguration mechanism. It makes use of an AWS elasticache memcached cluster's configuration endpoint to discover the memcache servers in the cluster and periodically check the current server list to adapt to a changing cluster.

=head1 UNDER DEVELOPMENT DISCALIMER

N.B. This module is still under development. It should work, but things may change under the hood. I plan to imporove the resiliance with better timeout handling of communication when updating the server list. I'm toying with the idea of making the server list lookup asyncronus, however that may add a level of complexity not worth the benefits. Also I'm investigating switching to Dist::Milla. I'm open to suggestions, ideas and pull requests.

=cut

use Carp;
use IO::Socket::IP;
use IO::Socket::Timeout;
use Cache::Memcached::Fast;
use Try::Tiny;
use Scalar::Util qw(blessed);

our $VERSION = '0.0.5';

=pod

=head1 CONSTRUCTOR

    Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar',
        update_period => 180,
        ...
    })

=head2 Constructor parameters

=over

=item config_endpoint

AWS elasticache memcached cluster config endpoint location

=item update_period

The minimum period (in seconds) to wait between updating the server list. Defaults to 180 seconds

=back

=cut

sub new {
    my $class = shift;
    my ($conf) = @_;
    my $self = bless {}, $class;

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args

    croak "config_endpoint must be speccified" if (!defined $args->{'config_endpoint'});
    croak "servers is not a valid constructors parameter" if (defined $args->{'servers'});

    $self->{'config_endpoint'} = delete @{$args}{'config_endpoint'};

    $args->{servers} = $self->getServersFromEndpoint($self->{'config_endpoint'}) if(defined $self->{'config_endpoint'});
    $self->{_last_update} = time;

    $self->{update_period} = exists $args->{update_period} ? $args->{update_period} : 180;

    $self->{'_args'} = $args;
    $self->{_memd} = Cache::Memcached::Fast->new($args);
    $self->{servers} = $args->{servers};

    return $self;
}

=pod

=head1 METHODS

=over

=item Supported Cache::Memcached::Fast methods

These methods can be called on a Cache::Elasticache::Memcache object. The object will call checkServers, then the call will be passed on to the appropriate L<Cache::Memcached::Fast> code. Please see the L<Cache::Memcached::Fast> documentation for further details regarding these methods.

    $memd->enable_compress($enable)
    $memd->namespace($string)
    $memd->set($key, $value)
    $memd->set_multi([$key, $value],[$key, $value, $expiration_time])
    $memd->cas($key, $cas, $value)
    $memd->cas_multi([$key, $cas, $value],[$key, $cas, $value])
    $memd->add($key, $value)
    $memd->add_multi([$key, $value],[$key, $value])
    $memd->replace($key, $value)
    $memd->replace_multi([$key, $value],[$key, $value])
    $memd->append($key, $value)
    $memd->append_multi([$key, $value],[$key, $value])
    $memd->prepend($key, $value)
    $memd->prepend_multi([$key, $value],[$key, $value])
    $memd->get($key)
    $memd->get_multi(@keys)
    $memd->gets($key)
    $memd->gets_multi(@keys)
    $memd->incr($key)
    $memd->incr_multi(@keys)
    $memd->decr($key)
    $memd->decr_multi(@keys)
    $memd->delete($key)
    $memd->delete_multi(@keys)
    $memd->touch($key, $expiration_time)
    $memd->touch_multi([$key],[$key, $expiration_time])
    $memd->flush_all($delay)
    $memd->nowait_push()
    $memd->server_versions()
    $memd->disconnect_all()

=cut

my @methods = qw(
enable_compress
namespace
set
set_multi
cas
cas_multi
add
add_multi
replace
replace_multi
append
append_multi
prepend
prepend_multi
get
get_multi
gets
gets_multi
incr
incr_multi
decr
decr_multi
delete
delete_multi
touch
touch_multi
flush_all
nowait_push
server_versions
disconnect_all
);

foreach my $method (@methods) {
    my $method_name = "Cache::Elasticache::Memcache::$method";
    no strict 'refs';
    *$method_name = sub {
        my $self = shift;
        $self->checkServers;
        return $self->{'_memd'}->$method(@_);
    };
}

=pod

=item checkServers

    my $memd = Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar'
    })

    ...

    $memd->checkServers();

Trigger the the server list to be updated if the time passed since the server list was last updated is greater than the update period (default 180 seconds).

=cut

sub checkServers {
    my $self = shift;
    $self->{_current_update_period} = (defined $self->{_current_update_period}) ? $self->{_current_update_period}: $self->{update_period} - rand(10);
    if ( defined $self->{'config_endpoint'} && (time - $self->{_last_update}) > $self->{_current_update_period} ) {
        $self->updateServers();
        $self->{_current_update_period} = undef;
    }
}

=pod

=item updateServers

    my $memd = Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar'
    })

    ...

    $memd->updateServers();

This method will update the server list regardles of how much time has passed since the server list was last checked.

=cut

sub updateServers {
    my $self = shift;

    my $servers = $self->getServersFromEndpoint($self->{'config_endpoint'});

    ## Cache::Memcached::Fast does not support updating the server list after creation
    ## Therefore we must create a new object.

    if ( $self->_hasServerListChanged($servers) ) {
        $self->{_args}->{servers} = $servers;
        $self->{_memd} = Cache::Memcached::Fast->new($self->{'_args'});
    }

    $self->{servers} = $servers;
    $self->{_last_update} = time;
}

sub _hasServerListChanged {
    my $self = shift;
    my $servers = shift;

    return 1 unless (scalar(@$servers) == scalar(@{$self->{'servers'}}));

    return 1 unless (join('|',sort(@$servers)) eq join('|',sort(@{$self->{'servers'}})));

    return 0;
}

=pod

=back

=head1 CLASS METHODS

=over

=item getServersFromEndpoint

    Cache::Elasticache::Memcache->getServersFromEndpoint('foo.bar');

This class method will retrieve the server list for a given configuration endpoint.

=cut

sub getServersFromEndpoint {
    my $invoker = shift;
    my $config_endpoint = shift;
    my $data = "";
    # TODO: make use of "connect_timeout" (default 0.5s) and "io_timeout" (default 0.2s) constructor parameters
    # my $args = shift;
    # $connect_timeout = exists $args->{connect_timeout} ? $args->{connect_timeout} : $class::default_connect_timeout;
    # $io_timeout = exists $args->{io_timeout} ? $args->{io_timeout} : $class::default_io_timeout;
    my $socket = (blessed($invoker)) ? $invoker->{_sockets}->{$config_endpoint} : undef;

    for my $i (0..2) {
        unless (defined $socket && $socket->connected()) {
            $socket = IO::Socket::IP->new(PeerAddr => $config_endpoint, Timeout => 10, Proto => 'tcp');
            croak "Unable to connect to server: ".$config_endpoint." - $!" unless $socket;
            $socket->sockopt(SO_KEEPALIVE,1);
            $socket->autoflush(1);
            IO::Socket::Timeout->enable_timeouts_on($socket);
            $socket->read_timeout(0.5);
# This is currently commented out as it was breaking under perl 5.24 for me. Need to investigate!
#            $socket->write_Timeout(0.5);
        }

        try {
            $socket->send("config get cluster\r\n");
            my $count = 0;
            until ($data =~ m/END/) {
                my $line = $socket->getline();
                if (defined $line) {
                    $data .= $line;
                }
                $count++;
                last if ( $count == 30 );
            }
        } catch {
            $socket = undef;
            no warnings 'exiting';
            next;
        };
        if ($data ne "") {
            last;
        } else {
            $socket = undef;
        }
    }
    if (blessed $invoker) {
        $invoker->{_sockets}->{$config_endpoint} = $socket;
    } else {
        $socket->close() if (blessed $socket);
    }
    return $invoker->_parseConfigResponse($data);
}

sub _parseConfigResponse {
    my $class = shift;
    my $data = shift;
    return [] unless (defined $data && $data ne '');
    my @response_lines = split(/[\r\n]+/,$data);
    my @servers = ();
    my $node_regex = '([-.a-zA-Z0-9]+)\|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\|(\d+)';
    foreach my $line (@response_lines) {
        if ($line =~ m/$node_regex/) {
            foreach my $node (split(' ', $line)) {
                my ($host, $ip, $port) = split('\|',$node);
                push(@servers,$ip.':'.$port);
            }
        }
    }
    return \@servers;
}

sub DESTROY {
    my $self = shift;
    foreach my $config_endpoint (keys %{$self->{_sockets}}) {
        my $socket = $self->{_sockets}->{$config_endpoint};
        if (defined $self->{_socket} && $socket->connected()) {
            $self->{_socket}->close();
        }
    }
};

1;
__END__

=pod

=back

=head1 BUGS

L<github issues|https://github.com/zebardy/cache-elasticache-memcache/issues>

=head1 SEE ALSO

L<Cache::Memcached::Fast> - The undelying library used to communicate with memcached servers (apart from autodiscovery)

L<AWS Elasticache Memcached autodiscovery|http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.html> - AWS's documentation regarding elasticaches's mecached autodiscovery mechanism.

=head1 AUTHOR

Aaron Moses

=head1 WARRANTY

There's B<NONE>, neither explicit nor implied.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2015 Aaron Moses. All rights reserved

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=cut

