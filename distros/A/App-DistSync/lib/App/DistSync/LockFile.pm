package App::DistSync::LockFile;
use strict;
use warnings;
use utf8;

=encoding utf-8

=head1 NAME

App::DistSync::LockFile - Lock File management package

=head1 SYNOPSIS

    use App::DistSync::LockFile;

    my $lf = App::DistSync::LockFile->new (
        file => '/tmp/file.lock',
        pid  => $$,
        auto => 0,
    );

    if ( my $pid = $lf->check ) {
        warn $lf->error if $lf->error;
        die "Already running: $pid";
    }

    $lf->lock;
    die $lf->error if $lf->error;

    # . . . do stuff . . .

    $lf->unlock;
    die $lf->error if $lf->error;

... or with auto-lock and auto-unlock:

    my $lf = App::DistSync::LockFile->new (
        file => '/tmp/file.lock',
        pid  => $$,
        auto => 1,
    );

    die $lf->error if $lf->error;
    die "Already running" if $lf->check;

    # . . . do stuff . . .

=head1 DESCRIPTION

This package manages a lock files. It will create a lock file,
query the process within to discover if it's still running, and remove
the lock file. This module based on L<File::Pid>, L<Lock::File>,
L<File::TinyLock>, L<JIP::LockFile> and L<LockFile::Simple>.

=head1 METHODS

This module implements the following methods

=head2 new

    my $lf = new App::DistSync::LockFile(
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

    if ( my $pid = $lf->check ) {
        warn $lf->error if $lf->error;
        die "Already running: $pid";
    }

This method checks the lock file and returns the PID of the process that first acquired the lock.
Otherwise returns 0 if no lock file found

=head2 error

    my $error = $lf->error;

Returns current error message

=head2 file

    my $file = $lf->file;

Accessor for the filename used as the lock file.

=head2 lock

    $self = $self->lock;

This method creates a lock file and stores the current PID in it.

=head2 own

    $lf->own(123);
    my $owner_did = $lf->own;

Accessor/mutator for the pid being saved to the lock file.

=head2 pid

    my $pid = $lf->pid;

Accessor for the pid being saved to the lock file.

=head2 unlock

    $self = $self->unlock;

This method performs unlocking the lock file and removes it

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acme::Ghost::FilePid>,  L<Lock::File>, L<File::TinyLock>,
L<JIP::LockFile> and L<LockFile::Simple>

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
use IO::File qw//;
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
    $self->{pid}        ||= $$; # Current PID by default
    $self->{own}        ||= 0; # Owner PID
    $self->{auto}       //= 0;
    $self->{retries}    //= RETRIES;
    $self->{delay}      //= DELAY;
    $self->{_is_locked} = 0;
    croak("Incorrect pid attribute") unless $self->{pid} =~ /^[0-9]{1,11}$/;
    croak("Incorrect retries attribute") unless $self->{retries} =~ /^[0-9]{1,5}$/;
    croak("Incorrect delay attribute") unless $self->{delay} =~ /^[0-9]{1,5}$/;

    # Lock file
    return $self->lock if $self->{auto};
    return $self;
}

sub file { shift->{file} }
sub pid { shift->{pid} }
sub own {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{own} = shift;
        return $self;
    }
    return $self->{own};
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
    if ($self->_is_locked) {
        $self->_debug(sprintf("File %s already locked", $self->file));
        return $self;
    }

    # Signals
    $SIG{HUP} = $SIG{QUIT} = $SIG{INT} = $SIG{TERM} = sub {
        $self->_debug( "Caught SIG$_[0]" );
        exit;
    };

    # Save temp file
    my $tmp_file = sprintf("%s.%d", $self->file, $self->pid);
    if (open(my $fh, '>', $tmp_file)) {
        printf $fh "%d\n", $self->pid || $$;
        close $fh;

        # Rename temp file to lock file
        for my $try (0 .. $self->{retries}) {
            unless ($self->check()) { # not exists, ok
                if (rename($tmp_file, $self->file)) {
                    $self->{_is_locked} = 1;
                    $self->_debug("Got lock file");
                    return $self;
                }
            }
            if ($self->{retries} && ($try != $self->{retries})) {
                $self->_debug(sprintf("Retrying in %d seconds", $self->{delay}));
                sleep $self->{delay} unless ($try == $self->{retries});
            }
        }

    } else {
        $self->error(sprintf("Could not write to %s: $!", $tmp_file))->_debug($self->error);
    }

    # Remove temp file in silent mode
    unlink $tmp_file if -f $tmp_file;

    # Ok
    return $self;
}
sub check {
    my $self = shift;
    return 0 unless -f $self->file;

    # Load file
    if (open(my $fh, $self->file)) {
        chomp(my $line = <$fh>);
        close $fh;
        $self->own(($line || 0) * 1) if $line =~ /^\d+$/;
        $self->_debug(sprintf("Found owner PID=%d in %s", $self->own, $self->file));

        # Check PID and owner PID
        if ($self->own == $self->pid) {
            $self->_debug(sprintf("An attempt to call the check method twice was detected for PID=%d", $self->own));
            return $self->own;
        }

        # Check owner PID
        if ( kill(0, $self->own) ) {
            $self->_debug(sprintf("Found valid existing lock file for PID=%d", $self->own));
            return $self->own;
        } else {
            $self->error(sprintf("Could not unlink %s: $!", $self->file))->_debug($self->error)
                unless unlink $self->file;
            $self->own(0) unless -f $self->file; # Reset owner PID to 0
            $self->_debug("Found and removed stale lock file");
        }
    } else {
        $self->error(sprintf("Could not read %s: $!", $self->file))->_debug($self->error);
    }

    return 0;
}
sub unlock {
    my $self = shift;

    # Remove lock file
    if ($self->_is_locked) {
        $self->error(sprintf("Could not unlink %s: $!", $self->file))->_debug($self->error)
            unless unlink $self->file;
        $self->own(0) unless -f $self->file; # Reset owner PID to 0
    } else {
        $self->own(0) # Reset owner PID to 0
    }

    # Remove temp file in silent mode
    my $tmp_file = sprintf("%s.%d", $self->file, $self->pid);
    unlink $tmp_file if -f $tmp_file;

    return $self;
}

sub _is_locked {
    my $self = shift;
    return ($self->{_is_locked} && -f $self->file) ? 1 : 0
}
sub _debug {
    my $self = shift;
    warn sprintf("%s: %s\n", ref($self), join("\n", @_)) if $self->{debug};
}

sub DESTROY {
    my $self = shift;
    return unless $self->{auto};
    $self->_debug("Cleaning up...");
    $self->unlock();
}

1;

__END__
