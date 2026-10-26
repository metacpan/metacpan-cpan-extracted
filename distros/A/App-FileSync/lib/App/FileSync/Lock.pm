package App::FileSync::Lock;

# An advisory lock file, so two runs (cron firing while the previous run is
# still going, or reindex racing a session) never work on the same tree.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Fcntl qw(:flock);
use File::Basename qw(dirname);

use App::FileSync::Args qw(named);
use App::FileSync::IO qw(ensure_dir open_file);

use version; our $VERSION = version->declare('0.001.5');

=encoding utf8

=head1 NAME

App::FileSync::Lock - advisory lock files

=head1 SYNOPSIS

	my $lock = App::FileSync::Lock::acquire(path => $path, nonblock => 1)
		or exit 2;	# another run holds it
	# ... the lock is released when $lock goes out of scope

=head1 FUNCTIONS

=head2 acquire

Purpose: take an exclusive C<flock> on a file.

Args: C<path> (required), C<nonblock> (return at once instead of waiting).

Returns: the filehandle holding the lock, or C<undef> when C<nonblock> is set
and another process holds it.  The lock lasts until the handle is closed or
goes out of scope.

Side Effects: creates the file and its directory if needed.

Usage:

	my $lock = App::FileSync::Lock::acquire(path => $lock_path, nonblock => 1);

=head3 EXAMPLE

	if (my $lock = App::FileSync::Lock::acquire(path => '/tmp/demo.lock', nonblock => 1)) {
		print "got it\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		path     => { type => 'string', min => 1 },
		nonblock => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'handle', optional => 1 }

=head3 MESSAGES

	Key            Meaning                        Resolution
	args.invalid   no path was given              pass path
	io.append      the lock file cannot be made   check permissions

=head3 FORMAL SPECIFICATION

	ΔLocks
	path? : PATH ; nb? : 𝔹 ; h! : HANDLE ∪ {⊥}
	path? ∉ dom Locks ⇒ h! ≠ ⊥ ∧ Locks' = Locks ∪ {path? ↦ self}
	path? ∈ dom Locks ∧ nb? ⇒ h! = ⊥ ∧ Locks' = Locks

=cut

sub acquire {
	my $args = named(\@_, {
		path     => { type => 'string', min => 1 },
		nonblock => { type => 'boolean', optional => 1 },
	}, 'Lock::acquire');

	my $path = $args->{path};
	ensure_dir(dirname($path));

	# Append mode creates the file without truncating one another process
	# has open.
	my $fh = open_file($path, '>>');

	# autodie's flock returns false (rather than dying) when a non-blocking
	# lock would block, which is exactly the "someone else has it" answer.
	my $flags = LOCK_EX | ($args->{nonblock} ? LOCK_NB : 0);
	my $held = flock($fh, $flags);
	close $fh unless $held;

	return $held ? $fh : undef;
}

1;

__END__

=head1 LIMITATIONS

C<flock> is advisory and, on NFS, may not lock across machines at all.  Keep
the server root and the client's F<~/.filesync> on local disks.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
