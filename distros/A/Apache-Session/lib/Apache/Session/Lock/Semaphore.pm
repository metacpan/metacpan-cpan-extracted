############################################################################
#
# Apache::Session::Lock::Semaphore
# IPC Semaphore locking for Apache::Session
# Copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Lock::Semaphore;

use strict;
use Config;
use IPC::SysV qw(IPC_PRIVATE IPC_CREAT S_IRWXU SEM_UNDO);
use IPC::Semaphore;
use Carp qw/croak confess/;
use vars qw($VERSION);

$VERSION = '1.04';

BEGIN {

    if ($Config{'osname'} eq 'linux') {
        #More semaphores on Linux means less lock contention
        $Apache::Session::Lock::Semaphore::nsems = 32;
    } elsif ($Config{'osname'}=~/bsd/i) {
        $Apache::Session::Lock::Semaphore::nsems = 8; #copied from IPC::Semaphore/sem.t minus 1
    } else {
        $Apache::Session::Lock::Semaphore::nsems = 16;
    }
    
    $Apache::Session::Lock::Semaphore::sem_key = 31818;
}

sub new {
    return unless $Config{d_semget};
    return
        if $^O eq 'cygwin' && (!exists $ENV{'CYGWIN'} || $ENV{'CYGWIN'} !~ /server/i);
    #Modified by Alexandr Ciornii, 2007-03-12

    my $class   = shift;
    my $session = shift;
    
    my $nsems = $session->{args}->{NSems} ||
        $Apache::Session::Lock::Semaphore::nsems;
    
#    die "You shouldn't set session argument SemaphoreKey to undef"
#     if exists($session->{args}->{SemaphoreKey}) && 
#        !defined ($session->{args}->{SemaphoreKey});

    my $sem_key = #exists ($session->{args}->{SemaphoreKey})?
        $session->{args}->{SemaphoreKey} || 
        $Apache::Session::Lock::Semaphore::sem_key;

    return bless {read => 0, write => 0, sem => undef, nsems => $nsems, 
        read_sem => undef, sem_key => $sem_key}, $class;
}

sub acquire_read_lock  {
    my $self    = shift;
    my $session = shift;

    return if $self->{read};
    return if $self->{write};

    if (!$self->{sem}) {    
        $self->{sem} = IPC::Semaphore->new(
            defined($self->{sem_key})?$self->{sem_key}:IPC_PRIVATE, $self->{nsems},
            IPC_CREAT | S_IRWXU) || confess("Cannot create semaphore with key $self->{sem_key}; NSEMS: $self->{nsems}: $!");
    }
    
    if (!defined $self->{read_sem}) {
        #The number of semaphores (2^2-2^4, typically) is much less than
        #the potential number of session ids (2^128, typically), we need
        #to hash the session id to choose a semaphore.  This hash routine
        #was stolen from Kernighan's The Practice of Programming.

        my $read_sem = 0;
        foreach my $el (split(//, $session->{data}->{_session_id})) {
            $read_sem = 31 * $read_sem + ord($el);
        }
        $read_sem %= ($self->{nsems}/2);
        
        $self->{read_sem} = $read_sem;
    }    
    
    #The semaphore block is divided into two halves.  The lower half
    #holds the read semaphores, and the upper half holds the write
    #semaphores.  Thus we can do atomic upgrade of a read lock to a
    #write lock.
    
    $self->{sem}->op($self->{read_sem} + $self->{nsems}/2, 0, SEM_UNDO,
                     $self->{read_sem},                    1, SEM_UNDO);
    
    $self->{read} = 1;
}

sub acquire_write_lock {    
    my $self    = shift;
    my $session = shift;

    return if($self->{write});

    if (!$self->{sem}) {
        $self->{sem} = IPC::Semaphore->new(
            defined($self->{sem_key})?$self->{sem_key}:IPC_PRIVATE, $self->{nsems},
            IPC_CREAT | S_IRWXU) || confess "Cannot create semaphore with key $self->{sem_key}; NSEMS: $self->{nsems}: $!";
    }
    
    if (!defined $self->{read_sem}) {
        #The number of semaphores (2^2-2^4, typically) is much less than
        #the potential number of session ids (2^128, typically), we need 
        #to hash the session id to choose a semaphore.  This hash routine
        #was stolen from Kernighan's The Practice of Programming.

        my $read_sem = 0;
        foreach my $el (split(//, $session->{data}->{_session_id})) {
            $read_sem = 31 * $read_sem + ord($el);
        }
        $read_sem %= ($self->{nsems}/2);
        
        $self->{read_sem} = $read_sem;
    }    
    
    $self->release_read_lock($session) if $self->{read};

    $self->{sem}->op($self->{read_sem},                    0, SEM_UNDO,
                     $self->{read_sem} + $self->{nsems}/2, 0, SEM_UNDO,
                     $self->{read_sem} + $self->{nsems}/2, 1, SEM_UNDO);
    
    $self->{write} = 1;
}

sub release_read_lock  {
    my $self    = shift;

    my $session = shift;
    
    return unless $self->{read};

    $self->{sem}->op($self->{read_sem}, -1, SEM_UNDO);
    
    $self->{read} = 0;
}

sub release_write_lock {
    my $self    = shift;
    my $session = shift;
    
    return unless $self->{write};
    
    $self->{sem}->op($self->{read_sem} + $self->{nsems}/2, -1, SEM_UNDO);

    $self->{write} = 0;
}

sub release_all_locks  {
    my $self    = shift;
    my $session = shift;

    if($self->{read}) {
        $self->release_read_lock($session);
    }
    if($self->{write}) {
        $self->release_write_lock($session);
    }
    
    $self->{read}  = 0;
    $self->{write} = 0;
}

sub hash {
    my $key   = shift;
    my $nsems = shift;
    my $hash = 0;


}

sub remove {
    my $self    = shift;
    if ($self->{sem}) {    
        $self->{sem}->remove();
    }
}

1;


=pod

=head1 NAME

Apache::Session::Lock::Semaphore - Provides mutual exclusion through semaphores

=head1 SYNOPSIS

 use Apache::Session::Lock::Semaphore;

 my $locker = new Apache::Session::Lock::Semaphore;
 die "no semaphores" unless $locker;

 $locker->acquire_read_lock($ref);
 $locker->acquire_write_lock($ref);
 $locker->release_read_lock($ref);
 $locker->release_write_lock($ref);
 $locker->release_all_locks($ref);

=head1 DESCRIPTION

Apache::Session::Lock::semaphore fulfills the locking interface of 
Apache::Session.  Mutual exclusion is achieved through system semaphores and
the IPC::Semaphore module.

=head1 CONFIGURATION

The module must know how many semaphores to use, and what semaphore key to
use. The number of semaphores has an impact on performance.  More semaphores
means less lock contention. You should use the maximum number of semaphores
that your platform will allow. On stock NetBSD, OpenBSD, and Solaris systems,
this is probably 16. On Linux 2.2, this is 32. This module tries to guess
the number based on your operating system, but it is safer to configure it
yourself.

To set the number of semaphores, you need to pass an argument in the usual
Apache::Session style. The name of the argument is NSems, and the value is
an integer power of 2. For example:

 tie %s, 'Apache::Session::Blah', $id, {NSems => 16};

You may also need to configure the semaphore key that this package uses. By
default, it uses key 31818.  You can change this using the argument
SemaphoreKey:

 tie %s, 'Apache::Session::Blah', $id, {NSems => 16, SemaphoreKey => 42};

=head1 PROBLEMS

There are a few problems that people frequently encounter when using this
package.

If you get an invalid argument message, that usually means that the system
is unhappy with the number of semaphores that you requested.  Try decreasing
the number of semaphores.  The semaphore blocks that this package creates
are persistent until the system is rebooted, so if you request 8 semaphores
one time and 16 semaphores the next, it won't work.  Use the system
commands ipcs and ipcrm to inspect and remove unwanted semphore blocks.

=head2 Cygwin

IPC on Cygwin requires running cygserver. Without it, program will exit with
"Bad System call" message. It cannot be intercepted with eval.

Read /usr/share/doc/Cygwin/cygserver.README for more information.

=head2 Darwin/MacOS X

Darwin and MacOS X may not have semaphores, see
L<http://sysnet.ucsd.edu/~bellardo/darwin/sysvsem.html>

=head2 *BSD

Error "No space left on device" means that maximum number of semaphores is reached.
See L<http://www.postgresql.org/docs/7.3/static/kernel-resources.html> for
more information.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session>
