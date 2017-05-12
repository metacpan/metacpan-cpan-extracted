package DDLock::Server;

use vars qw($VERSION);
$VERSION = '0.51';

use strict;
use warnings;

use Danga::Socket;
use IO::Socket::INET;
use Socket qw(IPPROTO_TCP SO_KEEPALIVE TCP_NODELAY SOL_SOCKET);

# Linux-specific:
use constant TCP_KEEPIDLE  => 4; # Start keeplives after this period
use constant TCP_KEEPINTVL => 5; # Interval between keepalives
use constant TCP_KEEPCNT   => 6; # Number of keepalives before death


sub new {
    my $class = shift;
    my %args = @_;

    $args{port} = 7002
        unless defined $args{port};

    $args{lock_type} = "internal"
        unless defined $args{lock_type};

    my $lock_type = $args{lock_type};

    my $client_class;
    my @client_options;
    if ($lock_type eq 'internal') {
        $client_class = "DDLock::Server::Client::Internal";
    }
    elsif($lock_type eq 'dlmfs') {
        $client_class = "DDLock::Server::Client::DLMFS";
    }
    elsif($lock_type eq 'dbi') {
        my $hostname = $args{hostname};
        my $table = $args{table};
        length( $hostname ) or die( "-h (--hostname) must be included with a hostname in dbi mode\n" );
        length( $table ) or die( "-T (--table) must be included with a table name in dbi mode\n" );
        $client_class = "DDLock::Server::Client::DBI";
        @client_options = ( $hostname, $table );
    }
    else {
        die( "Unknown lock type of '$lock_type' specified.\n" );
    }

    eval "use $client_class; 1"
        or die "Couldn't load class '$client_class' to handle lock type '$lock_type': $@\n";

    $client_class->_setup( @client_options );

    # establish SERVER socket, bind and listen.
    my $server = IO::Socket::INET->new(LocalPort => $args{port},
                                       Type      => SOCK_STREAM,
                                       Proto     => IPPROTO_TCP,
                                       Blocking  => 0,
                                       Reuse     => 1,
                                       Listen    => 10 )
        or die "Error creating socket: $@\n";

    # Not sure if I'm crazy or not, but I can't see in strace where/how
    # Perl 5.6 sets blocking to 0 without this.  In Perl 5.8, IO::Socket::INET
    # obviously sets it from watching strace.
    IO::Handle::blocking($server, 0);

    my $accept_handler = sub {
        my $csock = $server->accept();
        return unless $csock;

        IO::Handle::blocking($csock, 0);
        setsockopt($csock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;

        # Enable keep alive
        unless ( $args{nokeepalive} ) {
            (setsockopt($csock, SOL_SOCKET, SO_KEEPALIVE,  pack("l", 1)) &&
             setsockopt($csock, IPPROTO_TCP, TCP_KEEPIDLE,  pack("l", 30)) &&
             setsockopt($csock, IPPROTO_TCP, TCP_KEEPCNT,   pack("l", 10)) &&
             setsockopt($csock, IPPROTO_TCP, TCP_KEEPINTVL, pack("l", 30)) &&
             1
            ) || die "Couldn't set keep-alive settings on socket (Not on Linux?)";
        }

        my $client = $client_class->new($csock);
        $client->watch_read(1);
    };

    DDLock::Server::Client->OtherFds(fileno($server) => $accept_handler);

    return $client_class;
}

1;
