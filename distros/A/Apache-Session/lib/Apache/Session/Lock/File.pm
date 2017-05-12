############################################################################
#
# Apache::Session::Lock::File
# flock(2) locking for Apache::Session
# Copyright(c) 1998, 1999, 2000, 2004 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Lock::File;

use strict;

use Fcntl qw(:flock);
use Symbol;
use vars qw($VERSION);

$VERSION = '1.04';

$Apache::Session::Lock::File::LockDirectory = '/tmp';

sub new {
    my $class = shift;
    
    return bless { read => 0, write => 0, opened => 0, id => 0 }, $class;
}

sub acquire_read_lock  {
    if ($^O eq 'MSWin32' or $^O eq 'cygwin') {
        #Windows cannot escalate lock, so all locks will be exclusive
        return &acquire_write_lock;
    }
    #Works for acquire_read_lock => acquire_write_lock => release_all_locks
    #This hack does not support release_read_lock
    #Changed by Alexandr Ciornii, 2006-06-21

    my $self    = shift;
    my $session = shift;
    
    return if $self->{read};
    #does not support release_read_lock

    if (!$self->{opened}) {
        my $fh = Symbol::gensym();
        
        my $LockDirectory = $session->{args}->{LockDirectory} || 
            $Apache::Session::Lock::File::LockDirectory;
            
        open($fh, "+>".$LockDirectory."/Apache-Session-".$session->{data}->{_session_id}.".lock") || die "Could not open file (".$LockDirectory."/Apache-Session-".$session->{data}->{_session_id}.".lock) for writing: $!";

        $self->{fh} = $fh;
        $self->{opened} = 1;
    }
        
    if (!$self->{write}) {
     #acquiring read lock, when write lock is in effect will clear write lock
     flock($self->{fh}, LOCK_SH) || die "Cannot lock: $!";
    }

    $self->{read} = 1;
}

sub acquire_write_lock {
    my $self    = shift;
    my $session = shift;

    return if $self->{write};
    
    if (!$self->{opened}) {
        my $fh = Symbol::gensym();
        
        my $LockDirectory = $session->{args}->{LockDirectory} || 
            $Apache::Session::Lock::File::LockDirectory;
            
        open($fh, "+>".$LockDirectory."/Apache-Session-".$session->{data}->{_session_id}.".lock") || die "Could not open file (".$LockDirectory."/Apache-Session-".$session->{data}->{_session_id}.".lock) for writing: $!";

        $self->{fh} = $fh;
        $self->{opened} = 1;
    }
    
    flock($self->{fh}, LOCK_EX) || die "Cannot lock: $!";
    $self->{write} = 1;
}

sub release_read_lock  {
    if ($^O eq 'MSWin32' or $^O eq 'cygwin') {
        die "release_read_lock is not supported on Win32 or Cygwin";
    }
    my $self    = shift;
    my $session = shift;
    
    die "No read lock to release in release_read_lock" unless $self->{read};
    
    if (!$self->{write}) {
        flock($self->{fh}, LOCK_UN) || die "Cannot unlock: $!";
        close $self->{fh} || die "Could no close file: $!";
        $self->{opened} = 0;
    }
    
    $self->{read} = 0;
}

sub release_write_lock {
    my $self    = shift;
    my $session = shift;
    
    die "No write lock acquired" unless $self->{write};
    
    if ($self->{read}) {
        flock($self->{fh}, LOCK_SH) || die "Cannot lock: $!";
    }
    else {
        flock($self->{fh}, LOCK_UN) || die "Cannot unlock: $!";
        close $self->{fh} || die "Could not close file: $!";
        $self->{opened} = 0;
    }
    
    $self->{write} = 0;
}

sub release_all_locks  {
    my $self    = shift;
    my $session = shift;

    if ($self->{opened}) {
        flock($self->{fh}, LOCK_UN) || die "Cannot unlock: $!";
        close $self->{fh} || die "Could not close file: $!";
    }
    
    $self->{opened} = 0;
    $self->{read}   = 0;
    $self->{write}  = 0;
}

sub DESTROY {
    my $self = shift;
    
    $self->release_all_locks;
}

sub clean {
    my $self = shift;
    my $dir  = shift;
    my $time = shift;

    my $now = time();
    
    opendir(DIR, $dir) || die "Could not open directory $dir: $!";
    my @files = readdir(DIR);
    foreach my $file (@files) {
        if ($file =~ /^Apache-Session.*\.lock$/) {
            if ($now - (stat($dir.'/'.$file))[8] >= $time) {
              if ($^O eq 'MSWin32') {
                #Windows cannot unlink open file
                unlink($dir.'/'.$file) || next;
              } else {
                open(FH, "+>$dir/".$file) || next;
                flock(FH, LOCK_EX) || next;
                unlink($dir.'/'.$file) || next;
                flock(FH, LOCK_UN);
                close(FH);
              }
            }
        }
    }
    closedir(DIR);
}

1;

=pod

=head1 NAME

Apache::Session::Lock::File - Provides mutual exclusion using flock

=head1 SYNOPSIS

 use Apache::Session::Lock::File;

 my $locker = new Apache::Session::Lock::File;

 $locker->acquire_read_lock($ref);
 $locker->acquire_write_lock($ref);
 $locker->release_read_lock($ref);
 $locker->release_write_lock($ref);
 $locker->release_all_locks($ref);

 $locker->clean($dir, $age);

=head1 DESCRIPTION

Apache::Session::Lock::File fulfills the locking interface of 
Apache::Session.  Mutual exclusion is achieved through the use of temporary
files and the C<flock> function.

=head1 CONFIGURATION

The module must know where to create its temporary files.  You must pass an
argument in the usual Apache::Session style.  The name of the argument is
LockDirectory and its value is the path where you want the lockfiles created.
Example:

 tie %s, 'Apache::Session::Blah', $id, {LockDirectory => '/var/lock/sessions'}

If you do not supply this argument, temporary files will be created in /tmp.

=head1 NOTES

=head2 clean

This module does not unlink temporary files, because it interferes with proper
locking.  This can cause problems on certain systems (Linux) whose file systems
(ext2) do not perform well with lots of files in one directory.  To prevent this
you should use a script to clean out old files from your lock directory.
The meaning of old is left as a policy decision for the implementor, but a
method is provided for implementing that policy.  You can use the C<clean>
method of this module to remove files unmodified in the last $age seconds.
Example:

 my $l = new Apache::Session::Lock::File;
 $l->clean('/var/lock/sessions', 3600) #remove files older than 1 hour

=head2 acquire_read_lock

Will do nothing if write lock is in effect, only set readlock flag to true.

=head2 release_read_lock

Will do nothing if write lock is in effect, only set readlock flag to false.

=head2 Win32 and Cygwin

Windows cannot escalate lock, so all locks will be exclusive.

release_read_lock not supported - it is not used by Apache::Session.

When deleting files, they are not locked (Win32 only).

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session>
