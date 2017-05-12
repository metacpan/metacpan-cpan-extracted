package Apache::Session::Store::libmemcached;

use warnings;
use strict;

use Memcached::libmemcached;

=head1 NAME

Apache::Session::Store::libmemcached - Memcached::libmemcached

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use Apache::Session::libmemcache

  tie %hash, 'Apache::Session::libmemcache', $id, {
      servers => ['1.2.3.4:2100', '4.3.2.1:2100'],
      expiration => 300, # In seconds
      log_errors => 1,
  }

  # to enable a simple load balancing feature
  # and/or fail over
  tie %hash, 'Apache::Session::libmemcache', $id, {
     load_balance => [
        ['1.2.3.4:2100', '4.3.2.1:2100'],
        ['1.1.1.1:2100', '2.2.2.2:2100'],
     ],
     failover => 1,
     expiration => 300, # In seconds
     log_errors => 1,
  };

=head1 DESCRIPTION

Apache::Session::Store::libmemcached fulfills the storage interface of
L<Apache::Session>. Session data is stored memcached using
L<Memcached::libmemcached>

=head1 CONFIGURATION

=over

=item servers

Array reference containing strings with the format I<server:port>. You can include
multiple servers.

=item expiration

Optional parameter that sets the xpiration time of the session.
This is takes advantage of a memcached feature
that allows to set keys with expiration time. 0, I<undef> sets no
expiration time.

=item log_errors

If this parameter is set to 1, error messages will be outputed to
I<STDERR> if a memcached operation fails.

=back

=head1 LOAD BALANCE AND FAILOVER

=over

=item load_balance

You can use this paramater instead of I<servers>. It takes multiple server
pools. Each pool is represented by an array reference containing strings with
the format I<server:port>.

When this parameter is used read operations will be I<load balanced> between the
available pools.

The current balancing method is pretty straightforward. It uses the first
character of the session identifier to select the pool. On average and given
random session indentifiers memcache operation will be evenly distributed
amongst the available pools.

=item failover

When failover is enabled, write operations take place in all the available
pools. Read operations are still load balanced. However, in the event of a read
operation fail, the other available pools will be used.

=back


=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, $session) = @_;

    my $self = {};
    bless ($self, $class);
    $self->_connect($session);
    return $self;
}

=head2 insert

Insert a session id into memcached. It will die if the key already exists.

=cut

sub insert {
    my ($self, $session) = @_;

    if ($self->_read_session($session)) {
        die 'Object already exists in data store';
    }
    $self->_write_session(set => $session);
}

=head2 update

Replace a session id into memcached.

=cut

sub update {
    my ($self, $session) = @_;

    $self->_write_session(replace => $session);
}

=head2 materialize

Retrieve the content of a session id

=cut

sub materialize {
    my ($self, $session) = @_;

    if (my $value = $self->_read_session($session)) {
        $session->{serialized} = $value;
    }
    else {
        die 'Object does not exist in data store';
    }
}

=head2 remove

Remove a session id from mecached

=cut

sub remove {
    my ($self, $session) = @_;

    my $args = $session->{args};
    my $sid = $session->{data}->{_session_id};
    for my $mcache (@{$self->{libmemcached}}) {
        $mcache->{instance}->memcached_delete($sid);
    }
}

=head2 _connect

Private method that takes care of connecting to the memcache servers.

=cut

sub _connect {
    my ($self, $session) = @_;

    my $args = $session->{args};
    my @pools;
    if ($args->{servers} && ref($args->{servers}) eq 'ARRAY') {
        push (@pools, $args->{servers});
    }
    elsif ($args->{load_balance_pools}
            && ref($args->{load_balance_pools}) eq 'ARRAY'
          ) {
        push (@pools, @{$args->{load_balance_pools}});
    }

    die 'No libmemcached server supplied' unless (@pools);

    $self->{libmemcached} = [];
    for my $pool (@pools) {
        my $memc = Memcached::libmemcached->new();
        for my $server (@{$pool}) {
            my ($host, $port) = split(':', $server);
            unless ($memc->memcached_server_add($host, $port)) {
                $self->_log_error_message(
                        "failed to add server $host:$port"
                );
            }
        }
        push(
                @{$self->{libmemcached}},
                {
                    instance => $memc,
                    servers => $pool,
                }
            );
    }
}

=head2 _read_session

Private method to read sessions.

If load balance is enabled it will read from the right cache.

If it fails and failover is enabled, it will try to read
from other pools.

=cut

sub _read_session {
    my ($self, $session) = @_;

    my $args = $session->{args};

    # Select pool
    my ($idx, @alternative_pools) = $self->_select_read_pool($session);

    # Read session and return it if everything is ok
    my $ret = $self->_read_from_pool($session, $idx);
    if (defined($ret) || !$args->{failover} || !@alternative_pools) {
        return $ret;
    }

    # Try other pools if failover is enabled
    for my $pool (@alternative_pools) {
        $ret = $self->_read_from_pool($session, $pool);
        last if (defined($ret));
    }
    return $ret;
}

=head2 _select_read_pool

Private method to select a pool to read from.

We just use 'first session id character' mod $numberOfPools to
select a pool.

Note that we return the first available pool if load balance is
not enabled or if there is only one pool.

=cut
sub _select_read_pool
{
    my ($self, $session) = @_;

    my $args = $session->{args};
    my $sid = $session->{data}->{_session_id};

    my $num_pools = 1;
    my $idx = 0;
    my @alternative_pools;
    if ($sid && length($sid) && $args->{load_balance_pools}) {
        $num_pools = scalar(@{$args->{load_balance_pools}});
        $idx = hex(substr($sid, 0, 1)) % $num_pools;
        @alternative_pools = map { $_ != $idx } 0..($num_pools - 1);
    }
    return ($idx, @alternative_pools);
}

=head2 _update_pools

Private method to return which pools must be updated.

If failover is not enabled only one pool is returned.
Otherwise the designated pool will be returned.

=cut

sub _update_pools
{
    my ($self, $session) = @_;

    my @pools;
    # If failover is enabled remove from available pools,
    # otherwise update designated pool.
    if ($session->{args}->{failover}) {
        @pools = @{$self->{libmemcached}};
    } else {
        my ($idx, @alternative_pools) = $self->_select_read_pool($session);
        return ($self->{libmemcached}->[$idx]);
        @pools = ($self->{libmemcached}->[$idx]);
    }

    return @pools;
}

=head2 _read_from_pool

Private method to read from a given pool.

If read fails it will log the error in case logging is enabled.

=cut
sub _read_from_pool {
    my ($self, $session, $pool) = @_;

    my $instance = $self->{libmemcached}->[$pool]->{instance};
    my $key = $session->{data}->{_session_id};
    my $value = $instance->memcached_get($key);
    my $log = $session->{args}->{log_errors};
    if ($log && !defined($value) && $instance->errstr() ne 'NOT FOUND') {
        my $servers = $self->{libmemcached}->[$pool]->{servers};
        my $errmsg = sprintf(
            'Failed get %s in pool with %s',
            join(' ', @{$servers}),
            $instance->errstr()
        );
        $self->_log_error_message($errmsg);
    }

    return $value;
}

=head2 _write_session

Private method to set a key-value entry in all the configured pools.

=cut

sub _write_session {
    my ($self, $op, $session) = @_;

    my $expiration = $session->{args}->{expiration};
    if (defined($expiration) && !($expiration =~ m/^\d+$/)) {
        die "Invalid expiration: $expiration";
    }
    else {
        $expiration = 0;
    }

    my $sid = $session->{data}->{_session_id};
    for my $mcache ($self->_update_pools($session)) {
        my $ret;
        my $instance = $mcache->{instance};
        if ($op eq 'set') {
            $ret = $instance->memcached_set(
                $sid,
                $session->{serialized},
                $expiration
            );
        }
        else {
            $ret = $instance->memcached_replace(
                $sid,
                $session->{serialized},
                $expiration
            );
        }

        if ($session->{args}->{log_errors} && !defined($ret)) {
            my $errmsg = sprintf(
                'Failed %s in pool %s with %s',
                $op,
                join(' ', @{$mcache->{servers}}),
                $instance->errstr()
            );
            $self->_log_error_message($errmsg);
        }
    }
}

=head2 _log_error_message

Private method to log error messages

=cut

sub _log_error_message {
    my ($self, $message) = @_;

    warn($message);
}

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::Session::libmemcached

=head1 AUTHOR

Javier Uruen Val C<< <javi.uruen@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 Venda Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1; # End of Apache::Session::Store::libmemcached
