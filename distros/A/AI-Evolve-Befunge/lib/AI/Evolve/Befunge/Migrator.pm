package AI::Evolve::Befunge::Migrator;
use strict;
use warnings;

use Carp;
use IO::Select;
use IO::Socket::INET;
use Perl6::Export::Attrs;
use POSIX qw(sysconf _SC_OPEN_MAX);

use AI::Evolve::Befunge::Util;


=head1 NAME

    AI::Evolve::Befunge::Migrator - connection to migration server


=head1 SYNOPSIS

    my $migrator = AI::Evolve::Befunge::Migrator->new(Local => $socket);
    $migrator->spin() while $migrator->alive();


=head1 DESCRIPTION

Maintains a connection to the migration server, migrationd.  This
module is meant to run in a child process, which will die when the
Local socket is closed.

It provides a non-blocking, fault tolerant adaptation layer between
migrationd (which may be somewhere across the internet) and the
AI::Evolve::Befunge population object (which spends most of its time
evolving critters, and only occasionally polls us).


=head1 CONSTRUCTOR

=head2 new

    my $migrator = AI::Evolve::Befunge::Migrator->new(Local => $socket);

Construct a new Migrator object.

The Local parameter is mandatory, it is the socket (typically a UNIX
domain socket) used to pass critters to and from the parent process.

Note that you probably don't want to call this directly... in most
cases you should call spawn_migrator, see below.

=cut

sub new {
    my ($package, %args) = @_;
    croak("The 'Local' parameter is required!") unless exists $args{Local};
    my $host = global_config('migrationd_host', 'quack.glines.org');
    my $port = global_config('migrationd_port', 29522);
    my $self = {
        host  => $host,
        port  => $port,
        dead  => 0,
        loc   => $args{Local},
        rxbuf => '',
        txbuf => '',
        lastc => 0,
    };
    return bless($self, $package);
}


=head2 spawn_migrator

    my $socket = spawn_migrator($config);

Spawn off an external migration child process.  This process will live
as long as the returned socket lives; it will die when the socket is
closed.  See AI::Evolve::Befunge::Migrator for implementation details.

=cut

sub spawn_migrator :Export(:DEFAULT) {
    my ($sock1, $sock2) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);
    my $pid = fork();
    if($pid) {
        close($sock2);
        return $sock1;
    }

    close($sock1);
    for my $fd (0..sysconf(_SC_OPEN_MAX)-1) {
        next if $fd == $sock2->fileno();
        next if $fd == STDERR->fileno();
        POSIX::close($fd);
    }
    $sock2->blocking(0);
    my $migrator = AI::Evolve::Befunge::Migrator->new(Local  => $sock2);
    $migrator->spin() while $migrator->alive();
    exit(0);
}


=head1 METHODS

=head2 spin

    $migrator->spin();

This is the main control component of this module.  It looks for
incoming events and responds to them.

=cut

sub spin {
    my $self = shift;
    $self->spin_reads();
    $self->spin_writes();
    $self->spin_exceptions();
}


=head2 spin_reads

    $migrator->spin_reads();

Handle read-related events.  This method will delay for up to 2
seconds if no reading is necessary.

=cut

sub spin_reads {
    my $self = shift;
    $self->try_connect() unless defined $$self{sock};
    my $select = IO::Select->new($$self{loc});
    $select->add($$self{sock}) if defined $$self{sock};
    my @sockets = $select->can_read(2);
    foreach my $socket (@sockets) {
        if($socket == $$self{loc}) {
            my $rv = $socket->sysread($$self{txbuf}, 4096, length($$self{txbuf}));
            $$self{dead} = 1 unless $rv;
        } else {
            my $rv = $socket->sysread($$self{rxbuf}, 4096, length($$self{rxbuf}));
            if(!defined($rv) || $rv < 0) {
                debug("Migrator: closing socket due to read error: $!\n");
                undef $$self{sock};
                next;
            }
            if(!$rv) {
                debug("Migrator: closing socket due to EOF\n");
                undef $$self{sock};
            }
        }
    }
}


=head2 spin_writes

    $migrator->spin_writes();

Handle write-related events.  This method will not block.

=cut

sub spin_writes {
    my $self = shift;
    $self->try_connect() unless defined $$self{sock};
    return unless length($$self{txbuf} . $$self{rxbuf});
    my $select = IO::Select->new();
    $select->add($$self{loc}) if length $$self{rxbuf};
    $select->add($$self{sock})  if(length $$self{txbuf} && defined($$self{sock}));
    my @sockets = $select->can_write(0);
    foreach my $socket (@sockets) {
        if($socket == $$self{loc}) {
            my $rv = $socket->syswrite($$self{rxbuf}, length($$self{rxbuf}));
            if($rv > 0) {
                substr($$self{rxbuf}, 0, $rv, '');
            }
            debug("Migrator: write on loc socket reported error $!\n") if($rv < 0);
        }
        if($socket == $$self{sock}) {
            my $rv = $socket->syswrite($$self{txbuf}, length($$self{txbuf}));
            if(!defined($rv)) {
                debug("Migrator: closing socket due to undefined syswrite retval\n");
                undef $$self{sock};
                next;
            }
            if($rv > 0) {
                substr($$self{txbuf}, 0, $rv, '');
            }
            if($rv < 0) {
                debug("Migrator: closing socket due to write error $!\n");
                undef $$self{sock};
            }
        }
    }
}


=head2 spin_exceptions

    $migrator->spin_exceptions();

Handle exception-related events.  This method will not block.

=cut

sub spin_exceptions {
    my $self = shift;
    my $select = IO::Select->new();
    $select->add($$self{loc});
    $select->add($$self{sock}) if defined($$self{sock});
    my @sockets = $select->has_exception(0);
    foreach my $socket (@sockets) {
        if($socket == $$self{loc}) {
            debug("Migrator: dying: select exception on loc socket\n");
            $$self{dead} = 1;
        }
        if($socket == $$self{sock}) {
            debug("Migrator: closing socket due to select exception\n");
            undef $$self{sock};
        }
    }
}


=head2 alive

    exit unless $migrator->alive();

Returns true while migrator still wants to live.
=cut

sub alive {
    my $self = shift;
    return !$$self{dead};
}

=head2 try_connect

    $migrator->try_connect();

Try to establish a new connection to migrationd.

=cut

sub try_connect {
    my $self = shift;
    my $host = $$self{host};
    my $port = $$self{port};
    my $last = $$self{lastc};
    return if $last > (time() - 2);
    return if $$self{dead};
    debug("Migrator: attempting to connect to $host:$port\n");
    $$self{lastc} = time();
    $$self{sock}  = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => $host,
        PeerPort => $port,
        Blocking => 0,
    );
}


1;
