#!/usr/bin/perl

use strict;
use warnings;

use IO::Handle;
use Socket;

# CHANGE THIS!
my $PROGRAM = "/home/hachi/test.pl";

# Using IO::Handle::INET (or whatever that module is) actually blocks during
# connect even if you set the 'blocking' option to 0.

socket( my $server_sock, PF_INET, SOCK_STREAM, getprotobyname( 'tcp' ) )
    or die( "socket failed: $!\n" );
    
setsockopt( $server_sock, SOL_SOCKET, SO_REUSEADDR, pack( "l", 1 ) )
    or die( "setsockopt failed: $!\n" );
    
bind( $server_sock, sockaddr_in( 2345, INADDR_ANY ) )
    or die( "bind failed: $!\n" );

listen( $server_sock, SOMAXCONN )
    or die( "listen failed: $!\n" );

IO::Handle::blocking( $server_sock, 0 );

Danga::Socket->AddOtherFds( fileno( $server_sock ), sub {
    my $paddr = accept( my $client, $server_sock );
    Client->new( $client );
} );

$SIG{CHLD} = 'IGNORE';

Danga::Socket->EventLoop;

warn "Clean Exit!\n";
exit 0;

package Client;

use strict;
use warnings;

use Data::Dumper;

use base 'Danga::Socket';

use fields qw(exec);

sub new {
    my Client $self = shift;
    my $sock = shift;
    
    $self = fields::new( $self ) unless ref $self;
    $self->SUPER::new( $sock );

    my $exec = Exec->new(
        read  => sub {
            my $exec = shift;
            my $input = $exec->read( 1024 );
            if ($input) {
                print "Exec for $exec->{pid} read: $$input\n";
                $self->write( $input );
            }
            else {
                $exec->watch_read( 0 );
            }
        },
        program => $PROGRAM,
    );

    $exec->watch_read( 1 );

    $self->{exec} = $exec;

    return $self;
}

sub event_err {
    my Client $self = shift;
    $self->{exec}->kill;
}

sub event_hup {
    my Client $self = shift;
    $self->{exec}->kill( "INT" );
}

package Exec;

use strict;
use warnings;

use Socket;
use IO::Handle;

use base 'Danga::Socket';

use fields qw(pid read write err hup);

sub new {
    my Exec $self = shift;
    my %opts = @_;

    $self = fields::new( $self ) unless ref $self;

    $self->{read} = delete( $opts{read} );
    $self->{write} = delete( $opts{write} );
    $self->{err} = delete( $opts{err} );
    $self->{hup} = delete( $opts{hup} );

    my $program = delete( $opts{program} )
        or die( "Must supply a program argument" );
    my $args = delete( $opts{args} ) || [];

    die( "Unknown arguments" ) if keys( %opts );

    socketpair( my $one, my $two, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
        or die( "Sockpair failed" );
    IO::Handle::blocking( $one, 0 );
    IO::Handle::blocking( $two, 0 );

    # Try turning off autoflush on these, so stdio calls don't buffer
    select((select( $one ), $|++)[0]);
    select((select( $two ), $|++)[0]);

    my $pid = fork();

    die( "Fork failed: $!" ) unless defined( $pid );

    if ($pid) {
        # Parent process
        $self->{pid} = $pid;
        close $two;
        $self->SUPER::new( $one );
        return $self;
    }
    else {
        # Child process
        close $one;
        close STDIN;
        close STDOUT;

        # DUP our $two handle into the 0 and 1 fd slots
        open( STDIN, "<&" . fileno( $two ) )
            or die( "Couldn't dup to STDIN in pid $$: $!" );
        open( STDOUT, ">&" . fileno( $two ) )
            or die( "Couldn't dup to STDOUT in pid $$: $!" );

        exec( $program, @$args );
        
        die( "Exec failed: $!" );
    }
}

sub event_read {
    my Exec $self = shift;
    if (my $code = $self->{read}) {
        $code->( $self );
    }
}

sub event_write {
    my Exec $self = shift;
    if (my $code = $self->{write}) {
        $code->( $self );
    }
}

sub event_err {
    my Exec $self = shift;
    if (my $code = $self->{err}) {
        $code->( $self );
    }
}

sub event_hup {
    my Exec $self = shift;
    if (my $code = $self->{hup}) {
        $code->( $self );
    }
}

sub kill {
    my Exec $self = shift;
    my $signal = shift or return;
    kill $signal, $self->{pid};
}
