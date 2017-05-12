package Daemon::Easy;

use 5.008008;
use strict;
use warnings;
use POSIX;

our $VERSION = '0.02';


sub import{
    my $class       = shift;
    my %args        = ( (@_ and ref($_[0])) ? %{$_[0]} : @_ ) or ();

    $args{sleep} = 5 unless defined $args{sleep};
    $args{pidfile} ||= "$0.pid";
    $args{stopfile} ||= "$0.stop";
    $args{callback} ||= 'worker';

    no strict 'refs';
    $args{worker} = \&{caller()."::$args{callback}"};
    *{caller()."::run"} = sub{
        unshift @_, \%args;
        goto &_run;
    };
}

sub _run{
    my ($args,$cmd) = @_;
    $cmd ||= $ARGV[0];
    
    $cmd = lc $cmd;
    if( $cmd eq 'start' ){
        if(my $status = status($args)){
            print "the daemon is running with pid: $status\n";
            exit;
        }
        start($args);
    }elsif( $cmd eq 'stop' ){
        stop($args);
    }elsif( $cmd eq 'status' ){
        if ( status($args) ){
            print "the daemon is running with pid: ".status($args)."\n";
        }else{
            print "the daemon stopped\n";
        }
    }elsif( $cmd eq 'restart' ){
        stop($args);
        sleep(3) while(status($args));
        start($args);
    }else{
        usage();
    }
}

sub usage{
    print "usage:\n\t $0 [start stop restart status]\n" ;
    exit;
}

sub start{
    my $args = shift;
    my $pid = fork();
    die "cant fork, $!\n" unless defined $pid;
    
    if($pid){ # parent, remember the child pid, and exit
        open PID,">$args->{pidfile}" or die "cant open $args->{pidfile}, $!\n";
        print PID $pid;
        close PID;
        exit(0);
    }

    POSIX::setsid();
    
    unlink ($args->{stopfile}) if( -e $args->{stopfile} );
    
    while(1){
        eval { $args->{worker}->(); };
        if($@){
            print $@;
            last;
        }
        sleep($args->{sleep}) if $args->{sleep};
        if(-e $args->{stopfile} ){
            unlink($args->{stopfile});
            last;
        }
    }

    unlink ($args->{pidfile});
}

sub stop{
    my $args = shift;
    open FH, ">$args->{stopfile}" or die "cant create $args->{stopfile}, $!\n";
    close FH;
}

# check status, 0 if stoped, pid if running
sub status{
    my $args = shift;
    if(-e $args->{pidfile} ){
        open PID,$args->{pidfile} or die "cant open $args->{pidfile}, $!\n";
        my $pid=<PID>; chomp $pid;
        close PID;
        return $pid;
    }else{
        return 0;
    }
}

1;
__END__


=head1 NAME

Daemon::Easy - easily create a daemon

This is a pretty light weight module for easily creating a daemon.

The execution of the daemon is controlled by checking whether 
a stopfile exists in each running loop.

The pidfile stores the pid of the running daemon. 

=head1 SYNOPSIS

    use Daemon::Easy sleep=>5, stopfile=>'stop', pidfile=>'pid', callback=>'worker';

    sub worker{
        print "i am alive\n";
    }

    run();

    in the shell:
    ./yourdaemon.pl [start stop restart status]


=head1 DESCRIPTION


=head1 AUTHOR

Zhang Jun, E<lt> jzhang533@gmail.com E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zhang Jun

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
