package Acrux::FileLock;
use strict;
use warnings;
use utf8;

=encoding utf-8

=head1 NAME

Acrux::FileLock - The Lock File simple interface

=head1 SYNOPSIS

    use Acrux::FileLock;

    my $fl = Acrux::FileLock->new(
        file => '/tmp/file.lock',
        pid  => $$,
        auto => 0,
        flock => 0,
    );

    if ( $fl->check ) {
        warn $fl->error if $fl->error;
        die "Already running: $fl->own";
    }

    $fl->lock;
    die $fl->error if $fl->error;

    # . . . do stuff . . .

    $fl->unlock;
    die $fl->error if $fl->error;

... or with auto-lock and auto-unlock:

    my $fl = Acrux::FileLock->new(
        file => '/tmp/file.lock',
        pid  => $$,
        auto => 1,
    );

    die $fl->error if $fl->error;
    die "Already running" if $fl->check;

    # . . . do stuff . . .

=head1 DESCRIPTION

The Lock File simple interface

This package manages a lock files. It will create a lock file,
query the process within to discover if it's still running, and remove
the lock file. This module based on L<Lock::File>, L<File::TinyLock>,
L<JIP::LockFile>, L<LockFile::Simple> and L<Acrux::FilePid>.

=head1 METHODS

This module implements the following methods

=head2 new

    my $fl = Acrux::FileLock->new(
        file    => '/tmp/file.lock',
        delay   => 60,
        retries => 5,
        pid     => $$,
        auto    => 1,
    );

This constructor takes several optional attributes:

=over 4

=item auto

    auto => 0

If this flag specified as true, then
will be saved the lock file automatically while instance create and
removed the lock file automatically on DESTROY phase. Default: false

=item debug

    debug => 0

Print debugging messages to STDERR (0=Off (default), 1=On)

=item delay

    delay => 60

Number of seconds to wait between retries to getting a lockfile

Default: 60

=item file

    file => '/tmp/test.lock'

The name of the lock file to work on. If not specified, a lock
file located in current directory will be created that matches F<./basename($0).lock>.

=item flock

    flock => 1

If this flag is set to true then lockfile will be lock by system with flock

Default: 0

=item pid

    pid => $$

The pid to write to a new lockfile. If not specified, C<$$> is
used when the lock file doesn't exist. When the lock file does exist, the
pid inside it is used.


=item retries

    retries => 5

Number of times to retry getting a lockfile

Default: 5

=back

=head2 check

    if ( $fl->check ) {
        warn $fl->error if $fl->error;
        die "Already running: $fl->own";
    }

This method checks whether the lock is currently considered active.

Returns C<1> if the lock is active or C<0> if the lock is free.
The return value is always boolean and does not contain the PID of the
lock owner.

Before checking the lock state, this method reads the owner information
from the lock file and updates the C<own> and C<uid> attributes when the
file contains valid owner data. These values represent the metadata
stored in the lock file at the time of the call and must not be
considered proof that the corresponding process currently owns the
lock.

When C<flock> mode is enabled, the lock state is determined exclusively
by the system file lock. The C<own> and C<uid> attributes are still
updated from the lock file, but they do not participate in determining
the lock state.

In the regular mode, the owner PID and UID are additionally used to
determine whether the lock is still valid. A stale lock file is removed
automatically when possible.

If a stale lock file cannot be removed by the operating system, the
lock is considered active and C<check> returns C<1>. This condition is
reported through the debug facility and does not set C<error>.

=head2 error

    my $error = $fl->error;

Returns current error message

=head2 file

    my $file = $fl->file;

Accessor for the filename used as the lock file.

=head2 lock

    $self = $self->lock;

This method creates a lock file and stores the current PID in it.

=head2 own

    $fl = $fl->own(123);
    my $owner_did = $fl->own;

Accessor and mutator for the PID associated with the lock owner.

When C<check> reads a lock file containing valid owner information, this
attribute is updated with the PID stored in the file.

The value represents the owner PID recorded in the lock file at the time
of the last C<check> call. It is metadata and is not, by itself, a
guarantee that the corresponding process currently owns the lock.

After a successful C<lock>, the attribute contains the PID associated
with the newly acquired lock.

In C<flock> mode, the operating system does not provide the PID of the
process holding the system lock. Therefore, when inspecting a foreign
lock, C<own> represents only the PID recorded in the lock file.

=head2 pid

    my $pid = $fl->pid;

Returns the PID associated with this lock object.

By default, this is the PID of the current process (C<$$>). The value is
used when creating the lock file and is stored as the owner PID in the
lock file

The PID may be specified explicitly when creating the object:

    my $fl = Acrux::FileLock->new(pid => 123);

This can be useful when the object is used to represent a lock owned by
another process

=head2 uid

    $fl = $fl->uid(1000);
    my $owner_uid = $fl->uid;

Accessor and mutator for the numeric user ID associated with the lock
owner.

When C<check> reads a lock file containing valid owner information, this
attribute is updated with the UID stored in the file.

The value represents the owner UID recorded in the lock file at the time
of the last C<check> call. It is metadata and is not, by itself, a
guarantee that the corresponding process currently owns the lock.

After a successful C<lock>, the attribute contains the UID associated
with the newly acquired lock.

In C<flock> mode, the operating system does not provide the UID of the
process holding the system lock. Therefore, when inspecting a foreign
lock, C<uid> represents only the UID recorded in the lock file.

=head2 unlock

    $self = $self->unlock;

This method performs unlocking the lock file and removes it

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Lock::File>, L<File::TinyLock>, L<JIP::LockFile>, L<LockFile::Simple>,
L<Acrux::FilePid>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use Carp qw/croak/;
use File::Spec;
use File::Basename qw/basename/;
use IO::File;
use Fcntl qw/O_RDWR O_RDONLY O_WRONLY O_CREAT LOCK_EX LOCK_NB LOCK_UN/;
use Cwd qw/getcwd/;

use constant {
        RETRIES     => 5,
        DELAY       => 60,
    };

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $self  = bless {%$args}, $class;
    $self->{debug}      ||= 0;
    $self->{error}      = "";
    $self->{file}       //= File::Spec->catfile(getcwd, sprintf("%s.lock", basename($0)));
    $self->{pid}        //= $$; # Current PID by default
    $self->{own}        //= 0; # Owner PID
    $self->{uid}        //= 0; # Owner UID
    $self->{auto}       //= 0;
    $self->{retries}    //= RETRIES;
    $self->{delay}      //= DELAY;
    $self->{'flock'}    ||= 0;
    $self->{fh}         = undef;
    $self->{_is_locked} = 0;

    # PID normalize
    my $raw_pid = $self->{pid} || 0;
       $self->{pid} = abs(int($raw_pid)) if defined($raw_pid) && $raw_pid =~ /^-?\d+$/;
    unless (defined($self->{pid}) && $self->{pid} =~ /^[0-9]{1,11}$/) { # Protect
        croak("Incorrect \"pid\" attribute: $raw_pid");
    }

    # Check etries and delay
    croak("Incorrect \"retries\" attribute: " . $self->{retries}) unless $self->{retries} =~ /^[0-9]{1,5}$/;
    croak("Incorrect \"delay\" attribute: " . $self->{delay}) unless $self->{delay} =~ /^[0-9]{1,5}$/;

    # Lock file
    return $self->lock if $self->{auto};
    return $self;
}

sub file { shift->{file} }
sub pid { shift->{pid} }
sub own { # Owner PID
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{own} = shift;
        return $self;
    }
    return $self->{own};
}
sub uid { # Owner UID
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{uid} = shift;
        return $self;
    }
    return $self->{uid};
}
sub error {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{error} = shift;
        return $self;
    }
    return $self->{error};
}
sub lock {
    my $self = shift;
       $self->error(undef);
    if ($self->_is_locked) {
        $self->_debug(sprintf("File \"%s\" already locked", $self->file));
        return $self;
    }

    # Signals
    $SIG{HUP} = $SIG{QUIT} = $SIG{INT} = $SIG{TERM} = sub {
        $self->_debug( "Caught SIG$_[0]" );
        exit;
    };

    # Using flock
    if ($self->_use_flock) {
        # Initialize or reuse initialized fh
        $self->{fh} //= IO::File->new($self->file, O_RDWR | O_CREAT);
        if (my $fh = $self->{fh}) {
            unless (flock $fh, LOCK_EX | LOCK_NB) {
                $self->error(sprintf("Can't lock \"%s\": %s", $self->file, $!));
                $self->_debug($self->error);
                $self->{fh} = undef;
                return $self;
            }

            # Truncate file
            unless (truncate $fh, 0) {
                $self->error(sprintf("Can't truncate \"%s\": %s", $self->file, $!));
                $self->_debug($self->error);
                return $self->_rollback;
            }
            seek $fh, 0, 0;

            # Write data
            unless ($fh->printf("%d:%d\n", $self->pid || $$, $>)) {
                $self->error(sprintf("Can't write message to \"%s\": %s", $self->file, $!));
                $self->_debug($self->error);
                return $self->_rollback;
            }

            # Ok
            $self->{_is_locked} = 1;
            $self->own($self->pid || $$)->uid($>);
            $self->_debug("Got lock file (flock=true)");
        } else {
            $self->error(sprintf("Can't open \"%s\": %s", $self->file, $!));
            $self->_debug($self->error);
        }
        return $self;
    }

    # Regular case: save temp file first
    my $tmp_file = sprintf("%s.%d", $self->file, $self->pid);
    if (my $fh = IO::File->new($tmp_file, O_WRONLY | O_CREAT)) {
        unless ($fh->printf("%d:%d\n", $self->pid || $$, $>)) {
            $self->error(sprintf("Can't write message to \"%s\": %s", $tmp_file, $!));
            $self->_debug($self->error);
            unlink $tmp_file if -f $tmp_file;
            return $self;
        }
        unless ($fh->close) {
            $self->error(sprintf("Can't close \"%s\": %s", $tmp_file, $!));
            $self->_debug($self->error);
            unlink $tmp_file if -f $tmp_file;
            return $self;
        }

        # Rename temp file to lock file
        for my $try (0 .. $self->{retries}) {
            unless ($self->check()) { # not exists, ok
                if (rename($tmp_file, $self->file)) {
                    $self->{_is_locked} = 1;
                    $self->_debug("Got lock file (flock=false)");
                    return $self;
                }
            }
            if ($self->{retries} && ($try != $self->{retries})) {
                $self->_debug(sprintf("Retrying in %d seconds", $self->{delay}));
                sleep $self->{delay} unless ($try == $self->{retries});
            }
        }
    } else {
        $self->error(sprintf("Can't open \"%s\": %s", $tmp_file, $!));
        $self->_debug($self->error);
    }

    # Remove temp file in silent mode
    unlink $tmp_file if -f $tmp_file;

    # Ok
    return $self;
}
sub check {
    my $self = shift;
       $self->error(undef);

    # Read owner-data of existed file (see own and uid accessors)
    $self->_read_owner;

    return $self->_is_locked
        if $self->_use_flock;

    # File not exists. Returns 0
    return 0 unless -f $self->file;

    # Check current PID and owner PID
    if ($self->own == $self->pid) {
        $self->_debug(sprintf("An attempt to call the check method twice was detected for PID=%d", $self->own));
        return 1;
    }

    # Check owner PID
    if ($self->own && kill(0, $self->own)) {
        # Oops! Process already exists
        $self->_debug(sprintf("Found valid existing lock file for PID=%d", $self->own));
        return 1;
    }

    # Process for owner PID not exists. Check owner UID
    else {
        # Owner UID is current user?
        if ($self->uid && $self->uid != $>) {
            $self->_debug("The owner of the lock file owns NOT current user");
            # Check process by by /proc/PID (for linux only!)
            if (-d File::Spec->catfile("/proc", $self->own)) {
                $self->_debug(sprintf("Found valid existing lock file for PID=%d (by /proc/%d)", $self->own, $self->own));
                return 1;
            }
        }

        # Try unlink the not my lock file
        unless (unlink $self->file) {
            $self->_debug(sprintf("Can't remove stale lock file \"%s\": %s", $self->file, $!));
            return 1;
        }

        # File has removed. Reset owner PID and UID to 0
        unless (-f $self->file) {
            $self->own(0)->uid(0);
        }
        $self->_debug("Found and removed stale lock file");
    }

    return 0;
}
sub unlock {
    my $self = shift;
       $self->error(undef);

    # Remove lock file
    if ($self->_is_locked) {
        # Release file handler first
        if ($self->{fh}) {
            flock $self->{fh}, LOCK_UN;
            $self->{fh} = undef;
        }

        # Unlink file
        $self->error(sprintf("Can't remove \"%s\": %s", $self->file, $!))->_debug($self->error)
            unless unlink $self->file;
        $self->own(0)->uid(0) unless -f $self->file; # Reset owner PID and UID to 0
    } else {
        $self->own(0)->uid(0) # Reset owner PID and UID to 0
    }

    # Remove temp file in silent mode
    my $tmp_file = sprintf("%s.%d", $self->file, $self->pid);
    unlink $tmp_file if -f $tmp_file;

    return $self;
}

sub _read_owner {
    my $self = shift;

    # File not exists - skip
    return 0 unless -f $self->file;

    # Try to load file in ReadOnly mode
    my $fh = IO::File->new($self->file, O_RDONLY);
    unless ($fh) {
        $self->_debug(sprintf("Can't read \"%s\": %s", $self->file, $!));
        return 0;
    }

    # Read first line
    $fh->seek(0, 0);
    my $line = $fh->getline() // '';
    chomp $line;

    # Close file
    unless ($fh->close) {
        $self->_debug(sprintf("Can't close \"%s\": %s", $self->file, $!));
        return 0;
    }

    # Parse line
    my ($owner_pid, $owner_uid) = (0, 0);
    if ($line =~ /^(\d+):(\d+)$/) {
        ($owner_pid, $owner_uid) = ($1 * 1, $2 * 1);
    }

    # Set owner PID and UID
    $self->own($owner_pid)->uid($owner_uid);
    $self->_debug(sprintf("Read owner PID=%d, UID=%d from \"%s\"", $owner_pid, $owner_uid, $self->file));

    # Ok
    return 1;
}
sub _rollback {
    my $self = shift;
    $self->{_is_locked} = 0;
    $self->own(0)->uid(0);
    return $self unless $self->{fh};
    flock $self->{fh}, LOCK_UN;
    $self->{fh}->close;
    $self->{fh} = undef;
    return $self;
}
sub _is_locked {
    my $self = shift;
    return ($self->{_is_locked} && -f $self->file) ? 1 : 0
}
sub _use_flock {shift->{'flock'} ? 1 : 0}
sub _debug {
    my $self = shift;
    warn sprintf("%s: %s\n", ref($self), join("\n", @_)) if $self->{debug};
    return $self;
}

sub DESTROY {
    my $self = shift;
    return unless $self->{auto};
    $self->_debug("Cleaning up...");
    $self->unlock();
}

1;

__END__
