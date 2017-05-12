package Data::STUID::Client;
use strict;
use Data::STUID;
use Errno qw( EINPROGRESS EWOULDBLOCK EISCONN );
use IO::Socket::INET;
use List::Util ();
use Class::Accessor::Lite
    rw => [ qw(active_socket servers connect_timeout fetch_timeout select_timeout reuse_count max_reuse_count failure_delay) ]
;

sub new {
    my ($class, %args) = @_;
    $args{servers} ||= [];
    $args{connect_timeout} ||= 5;
    $args{select_timeout}  ||= 0.1;
    $args{fetch_timeout}   ||= 0.5;
    $args{failure_delay}   ||= 300;
    $args{max_reuse_count} ||= 300;
    bless { %args, _connect_failures => {} }, $class;
}

sub fetch_id {
    my $self = shift;

    my $id;

    my $timeout = time() + $self->fetch_timeout();
TRY_READ:
    while (time() < $timeout) {
        my $sock = $self->get_socket;
        if (! $sock) {
            last;
        }

        print $sock "\0";

        my $fileno = fileno($sock);
        my $rin = '';
        my $rout;
        my $nfound;
        my $nread;
        my $buf;
        my $read_offset = 0;
        while (1) {
            vec($rin, $fileno, 1) = 1;

            $nfound = select($rout = $rin, undef, undef, $self->select_timeout);
            if (! $nfound) {
                if (Data::STUID::DEBUG) {
                    print STDERR "Nothing to read\n";
                }
                $self->close_socket($sock);
                last;
            }

            if (vec($rout, $fileno, 1)) {
                if (Data::STUID::DEBUG) {
                    print STDERR "Attempting to read from socket\n";
                }
                $nread = sysread($sock, $buf, 8, $read_offset);
                if ( !defined $nread && $! == EWOULDBLOCK) {
                    if (Data::STUID::DEBUG) {
                        print STDERR "Error state while reading from socket\n";
                    }
                    # Try next sock
                    goto TRY_READ;
                }

                if ( ($nread || 0) <= 0 ) {
                    if (Data::STUID::DEBUG) {
                        print STDERR "Read <= 0 bytes\n";
                    }
                    $self->close_socket($sock);
                    goto TRY_READ;
                }

                $read_offset += $nread;
                if (Data::STUID::DEBUG) {
                    print STDERR "Read $nread bytes\n";
                }

                if ($read_offset == 8) {
                    my ($id) = unpack("Q", $buf);
                    return $id;
                }
            }
        }
    }
    Carp::croak("Could not get id :/");
}

sub get_socket {    
    my $self = shift;

    if ($self->active_socket) {
        $self->reuse_count($self->reuse_count + 1);
        if ($self->reuse_count < $self->max_reuse_count) {
            return $self->active_socket;
        }
    }

    my @servers = List::Util::shuffle(@{$self->servers});
    my $failures = $self->{_connect_failures};
    foreach my $server (@servers) {
        my $expires;
        if (defined($expires = $failures->{$server})) {
            if (Data::STUID::DEBUG) {
                print STDERR "Previous failure for $server found. Will expire in @{[$expires - time() ]}\n";
            }
            if ($expires > time()) {
                if (Data::STUID::DEBUG) {
                    print STDERR "+++ Skipping $server\n";
                }
                next;
            }
        }

        if (Data::STUID::DEBUG) {
            print STDERR "Attempting to connect $server\n";
        }
        my $socket = $self->create_socket($server);
        if ($socket) {
            if (Data::STUID::DEBUG) {
                print STDERR "Connected to $server\n";
            }
            $self->active_socket($socket);
            $self->reuse_count(0);
            return $socket;
        }
    }

    die "Could not connect to any servers";
}

sub create_socket {
    my ($self, $server) = @_;

    my ($addr, $port) = split /:/, $server;
    my $socket =  IO::Socket::INET->new(
        PeerAddr    => $addr,
        PeerPort    => $port,
        Proto       => "tcp",
        Type        => SOCK_STREAM,
        ReuseAddr   => 1,
        ReusePort   => 1,
        Blocking    => 0,
        Timeout     => $self->connect_timeout
    );
    if (! $socket) {
        if (Data::STUID::DEBUG) {
            print STDERR "Failed to connect to $server: $@\n";
        }
        $self->{_connect_failures}->{$server} = time() + $self->failure_delay;
    } else {
        delete $self->{_connect_failures}->{$server};
    }
    return $socket;
}

sub close_socket {
    my ($self, $socket) = @_;
    $socket->close;
    $self->active_socket(undef);
    $self->reuse_count(0);
}

1;

__END__

=head1 NAME

Data::STUID::Client - Client for Simplistic STUID Server

=head1 SYNOPSIS

    my $client = Data::STUID::Client->new(
        servers => [ qw(
            foo.bar.baz:9001
            foo.bar.baz:9002
        )]
    );

    my $id = $client->fetch_id;

=cut
