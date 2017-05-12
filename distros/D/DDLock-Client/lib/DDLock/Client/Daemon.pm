package DDLock::Client::Daemon;
use strict;
use Socket qw{:DEFAULT :crlf};
use IO::Socket::INET ();

use constant DEFAULT_PORT => 7002;
use constant DEBUG => 0;

use fields qw( name sockets pid client hooks );


### (CONSTRUCTOR) METHOD: new( $client, $name, @socket_names )
### Create a new lock object that corresponds to the specified I<name> and is
### held by the given I<sockets>.
sub new {
    my DDLock $self = shift;
    $self = fields::new( $self ) unless ref $self;

    $self->{client}  = shift;
    $self->{name}    = shift;
    $self->{pid}     = $$;
    $self->{sockets} = $self->getlocks(@_);
    $self->{hooks}   = {}; # hookname -> coderef
    return $self;
}


### (PROTECTED) METHOD: getlocks( @servers )
### Try to obtain locks with the specified I<lockname> from one or more of the
### given I<servers>.
sub getlocks {
    my DDLock $self = shift;
    my $lockname = $self->{name};
    my @servers = @_;

    my @addrs = ();

    my $fail = sub {
        my $msg = shift;
        # release any locks that we did get:
        foreach my $addr (@addrs) {
            my $sock = $self->{client}->get_sock($addr)
                or next;
            $sock->printf("releaselock lock=%s%s", eurl($self->{name}), CRLF);
            my $result = <$sock>;
            warn $result if DEBUG;
        }
        die $msg;
    };

    # First create connected sockets to all the lock hosts
  SERVER: foreach my $server ( @servers ) {
        my ( $host, $port ) = split /:/, $server;
        $port ||= DEFAULT_PORT;
        my $addr = "$host:$port";

        my $sock = $self->{client}->get_sock($addr)
            or next SERVER;

        $sock->printf( "trylock lock=%s%s", eurl($lockname), CRLF );
        chomp( my $res = <$sock> );
        $fail->("$server: '$lockname' $res\n") unless $res =~ m{^ok\b}i;

        push @addrs, $addr;
    }

    die "No available lock hosts" unless @addrs;
    return \@addrs;
}

sub name {
    my DDLock $self = shift;
    return $self->{name};
}

sub set_hook {
    my DDLock $self = shift;
    my $hookname = shift || return;

    if (@_) {
        $self->{hooks}->{$hookname} = shift;
    } else {
        delete $self->{hooks}->{$hookname};
    }
}

sub run_hook {
    my DDLock $self = shift;
    my $hookname = shift || return;

    if (my $hook = $self->{hooks}->{$hookname}) {
        local $@;
        eval { $hook->($self) };
        warn "DDLock hook '$hookname' threw error: $@" if $@;
    }
}

sub DESTROY {
    my DDLock $self = shift;

    $self->run_hook('DESTROY');
    local $@;
    eval { $self->_release_lock(@_) };

    return;
}

### METHOD: release()
### Release the lock held by the lock object. Returns the number of sockets that
### were released on success, and dies with an error on failure.
sub release {
    my DDLock $self = shift;

    $self->run_hook('release');
    return $self->_release_lock(@_);
}

sub _release_lock {
    my DDLock $self = shift;

    my $count = 0;

    my $sockets = $self->{sockets} or return;

    # lock server might have gone away, but we don't really care.
    local $SIG{'PIPE'} = "IGNORE";

    foreach my $addr (@$sockets) {
        my $sock = $self->{client}->get_sock_onlycache($addr)
            or next;

        my $res;

        eval {
            $sock->printf("releaselock lock=%s%s", eurl($self->{name}), CRLF);
            $res = <$sock>;
            chomp $res;
        };

        if ($res && $res !~ m/ok\b/i) {
            my $port = $sock->peerport;
            my $addr = $sock->peerhost;
            die "releaselock ($addr): $res\n";
        }

        $count++;
    }

    return $count;
}


### FUNCTION: eurl( $arg )
### URL-encode the given I<arg> and return it.
sub eurl
{
    my $a = $_[0];
    $a =~ s/([^a-zA-Z0-9_,.\\: -])/uc sprintf("%%%02x",ord($1))/eg;
    $a =~ tr/ /+/;
    return $a;
}

1;


# Local Variables:
# mode: perl
# c-basic-indent: 4
# indent-tabs-mode: nil
# End:
