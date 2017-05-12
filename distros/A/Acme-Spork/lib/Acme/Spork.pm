package Acme::Spork;

use strict;
use warnings;
use Carp;
use IO::Handle;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(spork);
our @EXPORT_OK = qw(daemonize daemonize_without_close_on);

use version;our $VERSION = qv('0.0.8');

our %reopen_stdfhs_to;

sub import {
    shift->export_to_level(1, grep(!/^-/, @_));
    if(grep /^-reopen_stdfhs$/, @_) {
        %reopen_stdfhs_to = (
             STDIN  => [qw(< /dev/null)],
             STDOUT => [qw(> /dev/null)],
             STDERR => [qw(>&STDOUT)],
        );
    }
    return;
}

sub spork {
    my $spork = shift;
    croak "spork() needs a code ref!" if ref $spork ne 'CODE';
    
    my $PARENT_WTR = IO::Handle->new;
    my $CHILD_RDR  = IO::Handle->new;

    pipe($CHILD_RDR,  $PARENT_WTR); # or return/croak ?
    $PARENT_WTR->autoflush(1);

    defined (my $kid = fork) or die "Cannot fork: $!\n";
    
    if ($kid) {
        close $PARENT_WTR;
        chomp(my $grandkid_pid = <$CHILD_RDR>);
        close $CHILD_RDR; 
        waitpid($kid,0);
        return $grandkid_pid;
    }
    else {
        ## local $SIG{CHLD} = 'IGNORE';
        if (!defined &setsid) {                
            require POSIX;
            *setsid = *POSIX::setsid;
        }
        setsid();
        ##
        
        defined ( my $grandkid = fork) or die "Kid cannot fork: $!\n";
        if ($grandkid) {
            close $CHILD_RDR; 
            print $PARENT_WTR "$grandkid\n";
            close $PARENT_WTR;
            CORE::exit(0);
        }
        else {
            close $CHILD_RDR;
            close $PARENT_WTR;
            
            for my $stdfh (qw(STDIN STDOUT STDERR)) {
                close $stdfh;
                if(exists $reopen_stdfhs_to{ $stdfh } && ref $reopen_stdfhs_to{ $stdfh } eq 'ARRAY') {
                    eval  "open( $stdfh, " . join(', ', map { qq{"$_"} } @{ $reopen_stdfhs_to{ $stdfh } }) . ' );';
                    carp "Could not reopen $stdfh : $@" if $@; 
                    # no strict 'refs';
                    # open( $stdfh , @{ $reopen_stdfhs_to{ $stdfh } }) or carp "Could not reopen $stdfh : $!";
                }
            }
            
            ## if (!defined &setsid) {                
            ##     require POSIX;
            ##     *setsid = *POSIX::setsid;
            ## }
            ## 
            ## setsid();
            ## $SIG{CHLD} = 'DEFAULT';
            $spork->(@_);
            CORE::exit(0);
        }
    }
}   

sub daemonize {
    require Proc::Daemon;
    {
        local $SIG{'HUP'} = $SIG{'HUP'} || ''; # workaround until http://rt.cpan.org/Public/Bug/Display.html?id=21453
        goto &Proc::Daemon::Init;
    }
}

sub daemonize_without_close_on {
    require Proc::Daemon;
    {
        no warnings 'redefine';
        local *POSIX::close = sub { return 1; }; # the "without_close_on" part

        local $SIG{'HUP'} = $SIG{'HUP'} || ''; # workaround until http://rt.cpan.org/Public/Bug/Display.html?id=21453
        Proc::Daemon::Init(@_);
    }
}

1;

__END__

=head1 NAME

Acme::Spork - Perl extension for spork()ing in your script

=head1 SYNOPSIS

    use Acme::Spork;
    my $spork_pid = spork(\&long_running_code, @ARGV) 
        or die "Could not fork for spork: $!";
    print "Long running code has been started as PID $spork_pid, bye!\n";

=head1 DESCRIPTION

A spork in the plastic sense is a fork combined with a spoon. In programming I've come to call a spork() a fork() that does more than just a fork.

I use it to describe when you want to fork() to run some long running code but immediately return to the main program instead of waiting for it.

=head1 spork()

The first argument is a code ref that gets executed and any other args are passed to the call to the code ref.

    #!/usr/bin/perl

    use strict;
    use warnings;
    use Acme::Spork;

    print 1;
    spork( 
        sub { 
            sleep 5;
            open my $log_fh, '>>', 'spork.log', or die "spork.log open failed: $!";
            print {$log_fh} "I am spork hear me spoon\n"; 
            close $log_fh;
        },
    ) or die qq{Couldn't fork for spork: $!};
    print 2;

This prints out "12" immediately and is done running, now if you tail -f spork.log you'll see "I am spork hear me spoon\n" get written to it 4 or 5 seconds later by the spork()ed process :)

spork() returns the PID of the spork()ed process so you can keep track of them and do what you need with it.

If it returns false then fork failed so you can:

    if(spork(\&foo)) {
        print "I am spork here me spoon\n";
    }
    else {
        print "Could not fork for spork: $!";
    }
    my $spork_pid = spork(\&foo) or die "Could not fork for for spork: $!";

=head2 %reopen_stdfhs_to

You can now have spork reopen one or more of STDIN, STDOUT, STDERR.
You define how this is handled in the Acme::Spork hash '%reopen_stdfhs_to'

The key is the STD* handle (any other values are simply ignored).

The value is an array reference of arguments to open().

Its always a good idea to local()ize it as well (and specify all 3 handles, otherwise you may get some strange warnings and behavior):

    local %Acme::Spork::reopen_stdfhs_to = (
         STDIN  => [qw(< /dev/null)],
         STDOUT => [qw(> /dev/null)],
         STDERR => [qw(> &STDOUT)],
    );
    spork(...)    
    
or you can have it set to the value above globally like so:

    use Acme::Spork qw(-reopen_stdfhs);
    ...
    spork(...)

=head2 setsid()

Say you have a custom module that is a subset of POSIX functions that includes setsid() and you'd rather use that one instead of bringing in all of POSIX.

Just define Acme::Spork::setsid ()

   sub Acme::Spork::setsid {
       require POSIX::Subset;
       POSIX::Subset::setsid();  
   }
   my $pid = spork(...);

or if you already have the module loaded:

  *Acme::Spork::setsid = *POSIX::Subset::setsid;
   my $pid = spork(...);

It will use your setsid() instead and POSIX will not be brought in. If it doesn't actually setsid() then you just broke yourself so don't do that.

=head1 daemonize()

Since many daemons need to spork a child process when a request is received I've included a cheat function to daemonize your script execution.

Its simply a wrapper for Proc::Daemon::Init.

    use Acme::Spork qw(daemonize);

    # make sure we are the only one running:
    use Unix::Pid '/var/run/this.pid';

    # if so make me a daemon:
    daemonize();

    # and redo the pid_file with the new pid
    Unix::PID->new()->pid_file('/var/run/this.pid') 
        or die 'The PID in /var/run/this.pid is still running.'; 

    # and handle requests as a server:
    while(<$incoming_requests>) {
        my $req_pid = spork(\&handle_request($_));
        if($req_pid) {
            spork(\&log_request($_), $req_pid) 
                or warn "Could not spork log request $req_pid: $!";
        }
        else {
            warn "Could not spork request: $!";
        }
    }

=head1 daemonize_without_close_on()

Same as daemonize() except it doesn't get Proc::Daemon::Init()'s POSIX::close done.
Useful if that happening causes you problems (which it has me...)

=head1 CAVEAT

If you set $SIG{CHLD} to 'IGNORE' all your $?'s will be -1 (i.e not what you might be expecting)

=head1 EXPORT

spork() is by default, daemonize() and daemonize_without_close_on() can be.

=head1 SEE ALSO

L<Proc::Daemon> is not used unless you call daemonize().

L<Unix::PID> is not used at all in this module except the daemonize() example. I figured if you were using this module you many be interested in it as well :)

=head1 ATTN modules@perl.org

I'd love to have this registered if you could find it in your heart :)

L<http://www.xray.mpe.mpg.de/mailing-lists/modules/2005-12/msg00154.html>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
