# -*- perl -*-

# Copyright (c) 2008 by AdCopy
# Author: Jeff Weisberg
# Created: 2008-Dec-01 16:02 (EST)
# Function: daemonization + logging
#
# $Id$

package AC::Daemon;
use AC::Import;
use Sys::Syslog;
use Time::HiRes;
use POSIX;
use strict;

BEGIN {
    # use it if we've got it
    eval {
        require AC::Error; AC::Error->import();
    };
    if($@){
        *daemon_error = sub {};
        *stack_trace  = sub {};
    }
}

our @EXPORT = qw(daemonize run_and_watch initlog debugmsg verbose problem fatal);

my $childpid;
my $verbose = 1;
my $nomail  = 0;
my $syslog;
my @maybe_argv = @ARGV;	# save for restart (might not be available)

sub daemonize {
    my $tout = shift;
    my $name = shift;
    my $argv = shift;

    fork && exit;	# background ourself
    $verbose = 0;

    my @argv = $argv ? @$argv : @maybe_argv;

    close STDIN;        open( STDIN,  "/dev/null" );
    close STDOUT;       open( STDOUT, "> /dev/null" );
    close STDERR;       open( STDERR, "> /dev/null" );
    setsid();

    $SIG{QUIT} = $SIG{INT} = $SIG{TERM} = sub { _signal($name, @_) };

    if( $name ){
        # save pid file
        open(PID, "> /var/run/$name.pid");
        print PID "$$\n";
        print PID "# @argv\n";
        close PID;
    }

    # run as 2 processes
    while(1){
	$childpid = fork;
	die "cannot fork: $!\n" unless defined $childpid;
        if( $childpid ){
            # parent
            wait;
            $childpid = undef;
            sleep $tout;
        }else{
            # child
            return;
        }
    }
}

sub _signal {
    my $name = shift;

    verbose( "caught signal SIG$_[0] - exiting" );

    if( $childpid > 1 ){
	# kill child process + wait for it to exit
        unlink "/var/run/$name.pid" if $name;
        kill "TERM", $childpid;
        wait;
    }

    exit;
}

sub initlog {
    my $name  = shift;
    my $facil = shift;
    my $quiet = shift;
    my $verb  = shift;

    unless( $syslog ){
        openlog( $name, 'ndelay, pid', $facil );
        $syslog = 1;
    }

    $nomail  = $quiet;
    $verbose = $verb if defined $verb;
}

sub run_and_watch {
    my $optf = shift;
    my $func = shift;

    $SIG{USR2} = \&_send_trace;

    eval {
	$func->();
    };
    if( my $e = $@ ){
	if( $optf ){
	    $e .= "\n\n" . stack_trace();
	    verbose( "UNCAUGHT ERROR: $e" );
	}else{
	    fatal( "UNCAUGHT ERROR: $e" );
	}
    }
}

sub debugmsg {
    my $msg = shift;

    syslog( 'debug', '%s', $msg ) if $syslog;
    _to_stderr( $msg ) if $verbose;
}

sub verbose {
    my $msg = shift;

    syslog( 'info', '%s', $msg ) if $syslog;
    _to_stderr( $msg ) if $verbose;
}

sub problem {
    my $msg = shift;

    daemon_error( $msg ) unless $nomail;
    syslog( 'err', '%s', $msg ) if $syslog;
    _to_stderr( $msg );
}

sub fatal {
    my $msg = shift;

    daemon_error( $msg ) unless $nomail;
    syslog( 'err', '%s', $msg ) if $syslog;
    _to_stderr( $msg );
    exit -1;
}

sub _to_stderr {
    my $msg = shift;

    my $tx = Time::HiRes::time();
    my $f  = $tx - int($tx);
    $f = sprintf('%.6f', $f);
    $f =~ s/^0\.//;
    my $t = strftime '%H:%M:%S', localtime($tx);
    print STDERR "[$$ $t.$f] $msg\n";

}

sub _send_trace {

    # email a stack trace to developer
    problem("sigusr2");
}


=head1 NAME

AC::Daemon - daemon program utility functions.

=head1 SYNOPSIS

    use AC::Daemon;
    use strict;

    initlog( 'program', 'local5' );
    daemonize( 5, 'program', \@ARGV ) unless $opt{foreground};
    verbose( 'starting.' );

    run_and_watch( $opt{foreground}, \&myfunction );
    exit;

=cut


1;

