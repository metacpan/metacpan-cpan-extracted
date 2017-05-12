# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-12 16:17 (EST)
# Function: 
#
# $Id$

package AC::DC::IO::Forked;

use AC::DC::Debug 'forked';

use Socket;
use POSIX;
use strict;

our @ISA = 'AC::DC::IO';

my $BUFSIZ = 8192;

sub new {
    my $class = shift;
    my $func  = shift;
    my $args  = shift;

    my $me = bless {
        func	=> $func,
        args	=> $args,
        @_
    }, $class;

    debug("new forked");

    return $me;
}

sub start {
    my $me = shift;

    debug("starting forked");
    my($fda, $fdb);
    unless( socketpair($fda, $fdb, AF_UNIX, SOCK_STREAM, PF_UNSPEC) ){
        problem("socketpair failed: $!");
        return ;
    }

    my $pid = fork();

    if( !defined($pid) ){
        problem("cannot fork: $!");
        return ;
    }elsif( $pid ){
        # parent
        close $fdb;
    }else{
        # child
        close $fda;
        eval { $me->_do_child($fdb) };
        _exit( $@ ? 1 : 0 );
    }

    $me->{pid} = $pid;
    $me->init($fda);
    $me->wantread(1);

    return $me;
}

sub _do_child {
    my $me = shift;
    my $fd = shift;

    close STDIN;  open( STDIN,  "<&", $fd );
    close STDOUT; open( STDOUT, ">&", $fd );
    close $fd;
    AC::DC::IO->closeall();
    $| = 1;
    $SIG{INT} = $SIG{TERM} = $SIG{QUIT} = $SIG{ALRM} = 'DEFAULT';

    alarm($me->{child_timeout});
    $me->{func}->( @{$me->{args}} );
}

sub shut {
    my $me = shift;

    debug("forked wait");
    if( $me->{pid} ){
        kill 15, $me->{pid};
        my $v = waitpid $me->{pid}, WNOHANG;

        if( $v == 0 ){
            # but I'm not dead yet
            debug("not dead yet");

            for(1..3){
                sleep 1;
                my $v = waitpid $me->{pid}, WNOHANG;
                last if $v;	# error or dead
                kill 9, $me->{pid};
            }
        }

        $me->{exitval} = $?;
        delete $me->{pid};
    }

    $me->SUPER::shut();
}

sub _readable {
    my $me = shift;

    my $buf;
    my $bs = $me->{rbufsize} || $BUFSIZ;
    my $i = sysread($me->{fd}, $buf, $bs);

    unless( defined $i ){
        my $e = $!;
        debug("read error");
        $me->run_callback('error', {
            cause	=> 'read',
            error	=> $e,
        });
        $me->shut();
        return ;
    }
    unless( $i ){
        debug("read eof");
        $me->run_callback('read_eof', undef);
        $me->shut();
        return ;
    }

    debug("forked read $i bytes");
    $me->run_callback('read', { data => $buf, size => $i } );

}


1;
