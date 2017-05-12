package App::Control;

$VERSION = '1.02';

use strict;
use warnings;

use File::Basename;
use File::Path;

sub new
{
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    die "No EXEC specified\n" unless $self->{EXEC};
    die "$self->{EXEC} doesn't exist\n" unless -e $self->{EXEC};
    die "$self->{EXEC} is not executable\n" unless -x $self->{EXEC};
    die "No PIDFILE specified\n" unless $self->{PIDFILE};
    my $piddir = dirname( $self->{PIDFILE} );
    die "Can't work out directory from path $self->{PIDFILE}\n" 
        unless $piddir
    ;
    unless ( -d $piddir )
    {
        warn "Creating $piddir ...\n" if $self->{VERBOSE};
        mkpath( $piddir ) or die "Can't create path $piddir\n";
    }
    unless ( -w $piddir )
    {
        die "can't create $self->{PIDFILE}\n";
    }
    if ( -e $self->{PIDFILE} )
    {
        die "$self->{PIDFILE} is not readable\n"
            unless -r $self->{PIDFILE}
        ;
        die "$self->{PIDFILE} is not writeable\n"
            unless -w $self->{PIDFILE}
        ;
    }
    if ( defined $self->{ARGS} )
    {
        die "ARGS should be an ARRAY ref\n" 
            unless ref( $self->{ARGS} ) eq 'ARRAY'
        ;
    }
    $self->{SLEEP} = 1 unless defined $self->{SLEEP};
    $self->{ARGS} ||= [];
    return $self;
}

sub running()
{
    my $self = shift;
    my $pid = $self->pid;
    return defined( $pid ) ? kill( 0, $self->{PID} ) : 0;
}

sub pid()
{
    my $self = shift;
    return unless -e $self->{PIDFILE};
    die "Can't read $self->{PIDFILE}\n" unless -r $self->{PIDFILE};
    open( PID, $self->{PIDFILE} ) 
        or die "Can't open pid file $self->{PIDFILE}\n"
    ;
    my $pid = <PID>;
    close( PID );
    return undef unless defined $pid;
    chomp( $pid );
    return undef unless $pid;
    die "$pid looks like a funny pid!\n"
        unless $pid =~ /^(\d+)$/
    ;
    return $self->{PID} = $1;
}

sub cmd()
{
    my $self = shift;
    my $cmd = shift;

    return if
        defined $self->{IGNOREFILE} and
        -e $self->{IGNOREFILE}
    ;
    unless ( defined $cmd )
    {
        die "CMD should be <start|stop|restart|status|hup>\n";
    }
    if ( $cmd eq 'status' )
    {
        return
            "$self->{EXEC} (",
            ( $self->pid ? $self->pid : "no pidfile $self->{PIDFILE}" ),
            ") is ", 
            ( $self->running ? '' : 'not ' ), 
            "running\n"
        ;
    }
    elsif ( $cmd eq 'start' )
    {
        die $self->status if $self->running;
        my $child = fork;
        if ( $child )
        {
            $SIG{CHLD} = 'IGNORE';
            warn "$self->{EXEC} @{$self->{ARGS}} ($child) started\n"
                if $self->{VERBOSE}
            ;
            if ( $self->{CREATE_PIDFILE} )
            {
                warn "Creating $self->{PIDFILE} ...\n" if $self->{VERBOSE};
                open( FH, ">$self->{PIDFILE}" ) 
                    or die "Can't write to $self->{PIDFILE}"
                ;
                print FH "$child\n";
                close( FH );
            }
            my $loop = 0;
            while( not $self->running )
            {
                warn $self->status if $self->{VERBOSE};
                sleep( $self->{SLEEP} );
                warn "is $self->{EXEC} ruinning (${loop}'th time)?\n"
                    if $self->{VERBOSE} and $loop
                ;
                if ( defined $self->{LOOP} and $loop++ == $self->{LOOP} )
                {
                    warn "Failed to start $self->{EXEC}\n"
                        if $self->{VERBOSE}
                    ;
                    if ( kill( 0, $child ) )
                    {
                        warn "killing $child ...\n" if $self->{VERBOSE};
                        kill( 'KILL', $child );
                        exit;
                    }
                }
            }
            warn "$self->{EXEC} running\n" if $self->{VERBOSE};
        }
        else
        {
            exec( $self->{EXEC}, @{$self->{ARGS}} );
        }
    }
    elsif ( $cmd eq 'stop' )
    {
        die $self->status unless $self->running;
        warn "kill ", $self->pid, "\n" if $self->{VERBOSE};
        die "failed to kill ", $self->pid, "\n" 
            unless kill( 'TERM', $self->pid )
        ;
        while ( $self->running )
        {
            warn $self->status if $self->{VERBOSE};
            sleep( 1 );
        }
        warn $self->pid, " killed\n" if $self->{VERBOSE};
        if ( $self->{CREATE_PIDFILE} )
        {
            warn "unlink $self->{PIDFILE}\n" if $self->{VERBOSE};
            unlink( $self->{PIDFILE} ) or
                warn "Can't unlink $self->{PIDFILE}\n"
            ;
        }
    }
    elsif ( $cmd eq 'restart' )
    {
        if ( $self->running )
        {
            eval { $self->stop };
            if ( $@ ) {
                die "Error stopping $self->{EXEC}: $@\n";
            }
        }
        eval { $self->start };
        if ( $@ )
        {
            die "Error starting $self->{EXEC}: $@\n";
        }
    }
    elsif ( $cmd eq 'hup' )
    {
        if ( $self->running )
        {
            unless ( kill( 'HUP', $self->pid ) )
            {
                die "Error hup'ing $self->{EXEC}: $@\n";
            }
        }
        else
        {
            die "Can't hup $self->{EXEC}: not running\n";
        }
    }
    else
    {
        die "CMD should be <start|stop|restart|status|hup>\n";
    }
}

sub AUTOLOAD
{
    use vars qw( $AUTOLOAD );
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    die "unkown method $method\n" 
        unless $method =~ /^(start|stop|restart|status|hup)$/
    ;
    $self->cmd( $method );
}

# True

1;

__END__

=head1 NAME

App::Control - Perl module for apachectl style control of another script or
executable

=head1 SYNOPSIS

    use App::Control;
    my $ctl = App::Control->new(
        EXEC => $exec,
        ARGS => \@args,
        PIDFILE => $pidfile,
        SLEEP => 1,
        VERBOSE => 1,
    );
    my $pid = $ctl->pid;
    if ( $ctl->running )
    {
        print "$pid is running\n";
    }
    else
    {
        print "$pid is not running\n";
    }
    # or alternatively ...
    print $ctl->status;
    $ctl->start;
    # or alternatively ...
    $ctl->cmd( 'start' );
    $ctl->stop;
    $ctl->hup;
    $ctl->restart;

=head1 DESCRIPTION

App::Control is a simple module to replicate the kind of functionality you get
with apachectl to control apache, but for any script or executable. There is a
very simple OO interface, where the constructor is used to specify the
executable, command line arguments, and pidfile, and various methods (start,
stop, etc.) are used to control the executable in the obvious way.

The module is intended to be used in a simple wrapper control script. Currently
the module does a fork and exec to start the executable, and sets the signal
handler for SIGCHLD to 'IGNORE' to avoid zombie processes.

=head1 CONSTRUCTOR

The constructor is called with a hash of options in the standard way. The
options are as follows:

=head2 EXEC

Path to the executable to be controlled. This option is REQUIRED.

=head2 ARGS

Command line arguments for the executable. This option is OPTIONAL, but if set,
should be an ARRAY reference.

=head2 PIDFILE

Path to the pidfile for the executable. This need not exists, but the
constructor will die if it thinks it can't create it. If the path where
the pidfile lives doesn't exist the constructor will try to create it. This
option is REQUIRED.

=head2 IGNOREFILE

The ignore file allows you to temporarily disable the control functionality.
Suppose you have a chkdaemon / crontab entry that restarts a service;
specifying an IGNOREFILE means that you can disable this wihtout having to edit
the relevant config files.

=head2 CREATE_PIDFILE

By default, App::Control depends on the application to manage the pid file.
This is consistent will analogous utilities (apachectl, chkdaemon, etc.), but
if you would like App::Control to create and remove pid files for you, then set
this option to a true value.

=head2 SLEEP

Number of seconds to sleep before checking that the process has been started.
If the start fails, the control script will loop with a SLEEP delay per
iteration until it has (see <"LOOP">). Default is 1 second.

head2 LOOP

Number of times to loop before giving up on starting the process.

=head2 VERBOSE

If set to a true value, the module will output verbose messages to STDERR.

=head1 METHODS

=head2 start

Start the executable specified in the constructor. This method waits until it
is convinced that the executable has started. It then writes the new pid to the
pidfile.

=head2 stop

Stop the executable specified in the constructor. It assumes that the pid
listed in the pidfile specified in the constructor is the process to kill.
This method waits until it is convinced that the executable has stopped.

=head2 hup

Send a SIGHUP to the executable.

=head2 restart

Basically; stop if running, and then start.

=head2 status

Returns a status message along the lines of "$exec ($pid) is / is not running".

=head2 cmd

All of the above methods can also be invoked using cmd; i.e.:

    $ctl->start;

is equivilent to:

    $ctl->cmd( 'start' );

give or take a call to AUTOLOAD!

=head2 pid

Returns the current value of the pid in the pidfile.

=head2 running

returns true if the pid in the pidfile is running.

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
