# $Id$

package Data::YUID::Client;
use strict;

use fields qw( servers select_timeout hosts connect_timeout );
use Carp;
use Errno qw( EINPROGRESS EWOULDBLOCK EISCONN );
use IO::Socket::INET;
use Socket qw( MSG_NOSIGNAL );
use URI::Escape ();

use constant DEFAULT_PORT => 9001;
use constant DEFAULT_TIMEOUT => {
    connect => 1.0, # seconds
    select  => 1.0, # seconds
};

our $FLAG_NOSIGNAL = 0;
eval { $FLAG_NOSIGNAL = MSG_NOSIGNAL };

my $Active_Sock;
my $Socket_Used_Count = 0; #yuids served per socket before we refresh it, to force rebalancing
my $Max_Socket_Reused = 1000 + rand(1000);

sub new {
    my Data::YUID::Client $client = shift;
    my %args = @_;
    $client = fields::new($client) unless ref $client;

    croak "servers must be an arrayref if specified"
        unless !exists $args{servers} || ref $args{servers} eq 'ARRAY';
    $client->{servers} = $args{servers} || [];
    for (qw(select_timeout connect_timeout)) {
        my $value = exists $args{$_} ? $args{$_} : DEFAULT_TIMEOUT->{$_};
        $client->{$_} = $value;
    }
    $client->{hosts} = $args{servers};

    $client;
}

sub _oneline {
    my Data::YUID::Client $client = shift;
    my ($sock, $line) = @_;
    my $res;
    my ($ret, $offset) = (undef, 0);

    # state: 0 - writing, 1 - reading, 2 - done
    my $state = defined $line ? 0 : 1;

    # the bitsets for select
    my ($rin, $rout, $win, $wout);
    my $nfound;

    my $copy_state = -1;
    local $SIG{'PIPE'} = "IGNORE" unless $FLAG_NOSIGNAL;

    # the select loop
    while(1) {
        if ($copy_state!=$state) {
            last if $state==2;
            ($rin, $win) = ('', '');
            vec($rin, fileno($sock), 1) = 1 if $state==1;
            vec($win, fileno($sock), 1) = 1 if $state==0;
            $copy_state = $state;
        }
        $nfound = select($rout=$rin, $wout=$win, undef,
                         $client->{select_timeout});
        last unless $nfound;

        if (vec($wout, fileno($sock), 1)) {
            $res = send($sock, $line, $FLAG_NOSIGNAL);
            next
                if not defined $res and $!==EWOULDBLOCK;
            unless (($res || 0) > 0) {
                _close_sock($sock);
                return undef;
            }
            if ($res == length($line)) { # all sent
                $state = 1;
            } else { # we only succeeded in sending some of it
                substr($line, 0, $res, ''); # delete the part we sent
            }
        }

        if (vec($rout, fileno($sock), 1)) {
            $res = sysread($sock, $ret, 255, $offset);
            next
                if !defined($res) and $!==EWOULDBLOCK;
            if ($res == 0) { # catches 0=conn closed or undef=error
                _close_sock($sock);
                return undef;
            }
            $offset += $res;
            if (rindex($ret, "\r\n") + 2 == length($ret)) {
                $state = 2;
            }
        }
    }

    unless ($state == 2) {
        _close_sock($sock);
        return undef;
    }

    return $ret;
}

sub get_id {
    my Data::YUID::Client $client = shift;
    my($ns) = @_;
    my $id;
    while (!$id && (my $sock = $client->get_sock)) {
        my $cmd = sprintf "getid ns=%s\r\n", URI::Escape::uri_escape($ns || '');
        my $res = $client->_oneline($sock, $cmd) or next;
        ($id) = $res =~ /^ok\s+id=(\d+)/i;
    }
    $id;
}

sub _close_sock {
    my($sock) = @_;
    undef $Active_Sock
        if ($Active_Sock && fileno($sock) == fileno($Active_Sock));
    close $sock;
}

#class method, for request cleanup
sub close_active_sock {
    close $Active_Sock;
}

sub connect_to_server {
    my Data::YUID::Client $client = shift;
    my($host) = @_;
    my($ip, $port) = split /:/, $host;
    $port ||= DEFAULT_PORT;
    my $sock = IO::Socket::INET->new(
            PeerAddr        => $ip,
            PeerPort        => $port,
            Proto           => 'tcp',
            Type            => SOCK_STREAM,
            ReuseAddr       => 1,
            Blocking        => 0,
            Timeout         => $client->{connect_timeout},
        ) or return;
    $sock;
}

sub get_sock {
    my Data::YUID::Client $client = shift;

    ++$Socket_Used_Count;

    if ($Active_Sock && $Active_Sock->connected && ($Socket_Used_Count % $Max_Socket_Reused != 0)) {
        return $Active_Sock;
    }else{
        my $hosts = $client->{hosts};
        my @try_hosts = @$hosts;
        my $sock;
        while (@try_hosts){
            my $host = splice(@try_hosts, int(rand(@try_hosts)), 1);
            $sock = $client->connect_to_server($host);
            last if $sock;
        }
        return $Active_Sock = $sock;
    }
}

1;
__END__

=head1 NAME

Data::YUID::Client - Client for distributed YUID generation

=head1 SYNOPSIS

    use Data::YUID::Client;
    my $client = Data::YUID::Client->new(
            servers => [
                '192.168.100.4:11001',
                '192.168.100.5:11001',
            ],
            connect_timeout => 1.0, # seconds
            select_timeout  => 1.0, # seconds
        );
    my $id = $client->get_id;

=head1 DESCRIPTION

I<Data::YUID::Client> is a client for the client/server protocol used to
generate distributed unique IDs. F<bin/yuidd> implements the server portion
of the protocol.

=head1 USAGE

=head2 Data::YUID::Client->new(%param)

Creates a new client object, initialized with I<%param>, and returns the
new object.

I<%param> can contain:

=over 4

=item * servers

A reference to a list of server addresses, in I<host:port> notation. These
should point to the locations of servers running the F<yuidd> server using
the client/server protocol for ID generation.

New Behavior: the original version of this would create a connection
to every server at C<new()> and cache them all.  This version
creates only one connection, when the first YUID is requested, and
caches that connection.  If the connection goes bad, it'll try other servers
it its list until one works or until it has worked through the list.

=item * connect_timeout

Number of seconds (can be fractional) to wait for a valid connection to the
server. It defaults to C<1.0> if the option is left out. If the value is
C<undef> then it basically waits forever (one of the previous behaviour
of this library.

=item * select_timeout

Number of seconds (can be fractional) for the select() on the server socket.
It defaults to C<1.0> if the option is left out. If the value is C<undef> then
it waits forever (not really advised).

=back

=head2 $client->get_id([ $namespace ])

Obtains a unique ID from one of the servers, in the optional namespace
I<$namespace>.

Returns undef if it can't get an ID from any server.

=head1 AUTHOR & COPYRIGHT

Please see the I<Data::YUID> manpage for author, copyright, and license
information.

=cut
