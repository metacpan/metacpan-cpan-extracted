package App::FileSync::Constants;

# Every fixed number and reserved name the distribution shares.  Tunables that
# tests adjust with "local" (chunk sizes, the run-log limit, the delta
# thresholds) stay as package variables in their own modules instead.

use strict;
use warnings;

use Exporter qw(import);
use Readonly;

use version; our $VERSION = version->declare('0.002.2');

# Plain values use Readonly::Scalar: it sets Perl's own read-only flag, where
# "Readonly our $X" ties the variable and makes every read a method call
# (about nine times slower).  Several of these are read once per file.  The
# pattern and the list keep Readonly, which handles references.

# Exit codes: the contract with cron, the Task Scheduler and "--exit N".
Readonly::Scalar our $EXIT_OK       => 0;
Readonly::Scalar our $EXIT_FATAL    => 1;
Readonly::Scalar our $EXIT_LOCKED   => 2;
Readonly::Scalar our $EXIT_WARNINGS => 3;
Readonly::Scalar our $EXIT_DRIFT    => 4;

# Highest exit status a process can report; "--exit N" is checked against it.
Readonly::Scalar our $EXIT_MAX => 255;

# Wire protocol version spoken by this release; client and server must agree.
Readonly::Scalar our $PROTOCOL_VERSION => 2;

# Where the server tree lives when neither --root nor FILESYNC_ROOT says.
Readonly::Scalar our $DEFAULT_SERVER_ROOT => '/srv/filesync';

# The program sshd runs as the forced command.
Readonly::Scalar our $SERVER_PROGRAM => 'filesync-server';

# Session roles.  A replica only ever pulls.
Readonly::Scalar our $ROLE_CLIENT  => 'client';
Readonly::Scalar our $ROLE_REPLICA => 'replica';
Readonly our @ROLES        => ($ROLE_CLIENT, $ROLE_REPLICA);

# Manifest entry types.
Readonly::Scalar our $TYPE_FILE => 'f';
Readonly::Scalar our $TYPE_DIR  => 'd';

# Fields of the list stat() and lstat() return.
Readonly::Scalar our $STAT_MODE  => 2;
Readonly::Scalar our $STAT_SIZE  => 7;
Readonly::Scalar our $STAT_MTIME => 9;

# Permission bits worth carrying between machines, and the mode a file gets
# when the peer did not send one.
Readonly::Scalar our $MODE_MASK         => oct('7777');
Readonly::Scalar our $DEFAULT_FILE_MODE => oct('644');

# Reserved names inside a sync root or the master.
Readonly::Scalar our $ROOT_MARKER  => '.filesync-root';
Readonly::Scalar our $TEMP_PREFIX  => '.filesync-tmp-';
Readonly::Scalar our $SNAPSHOT_DIR => '.filesync-snapshots';

# Temporaries older than this are from a run that died; younger ones may
# belong to a run in progress.
Readonly::Scalar our $STALE_TEMP_SECONDS => 3600;

# Largest single data frame either side accepts for an upload chunk.
Readonly::Scalar our $MAX_CHUNK_BYTES => 8 * 1024 * 1024;

# Repo policy defaults, also used when a stored config omits a key.
Readonly::Scalar our $TRASH_DAYS         => 30;
Readonly::Scalar our $MAX_DELETES        => 200;
Readonly::Scalar our $MAX_DELETE_PERCENT => 10;

# The most max_delete_percent can be: a percentage of the repo.
Readonly::Scalar our $MAX_PERCENT => 100;

# Replica snapshots kept by "filesync snapshot" when nothing says otherwise.
Readonly::Scalar our $SNAPSHOT_KEEP => 14;

# Calendar arithmetic.
Readonly::Scalar our $SECONDS_PER_DAY => 86_400;

# Repo and client ids become directory names, so they are short.
Readonly::Scalar our $MAX_ID_LENGTH => 64;

# The Digest::SHA algorithm behind every content hash.
Readonly::Scalar our $SHA_BITS => 256;

# A SHA-256 digest as it appears on the wire and in the index.
Readonly our $SHA256_HEX => qr/\A[0-9a-f]{64}\z/;

# Two clocks are treated as agreeing within this many seconds (FAT stores
# mtimes in 2-second units).
Readonly::Scalar our $MTIME_TOLERANCE => 2;

our @EXPORT_OK = qw(
	$EXIT_OK $EXIT_FATAL $EXIT_LOCKED $EXIT_WARNINGS $EXIT_DRIFT $EXIT_MAX
	$PROTOCOL_VERSION $DEFAULT_SERVER_ROOT $SERVER_PROGRAM
	$ROLE_CLIENT $ROLE_REPLICA @ROLES
	$TYPE_FILE $TYPE_DIR
	$STAT_MODE $STAT_SIZE $STAT_MTIME
	$MODE_MASK $DEFAULT_FILE_MODE
	$ROOT_MARKER $TEMP_PREFIX $SNAPSHOT_DIR $STALE_TEMP_SECONDS
	$MAX_CHUNK_BYTES
	$TRASH_DAYS $MAX_DELETES $MAX_DELETE_PERCENT $MAX_PERCENT $SNAPSHOT_KEEP
	$SECONDS_PER_DAY $MAX_ID_LENGTH $SHA_BITS $SHA256_HEX $MTIME_TOLERANCE
);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;

__END__

=head1 NAME

App::FileSync::Constants - shared constants for App::FileSync

=head1 SYNOPSIS

	use App::FileSync::Constants qw($EXIT_LOCKED $ROLE_REPLICA);

	exit $EXIT_LOCKED if $locked;

=head1 DESCRIPTION

Read-only values (L<Readonly>) shared by the client, server and admin tools:
exit codes, the protocol version, reserved file names, the fields of
C<stat()>, policy defaults and size limits.  Import them by name, or all of
them with C<:all>.

=head1 EXIT CODES

	$EXIT_OK        0  success
	$EXIT_FATAL     1  the run failed
	$EXIT_LOCKED    2  another run holds the lock (temporary, not a failure)
	$EXIT_WARNINGS  3  completed, with warnings or conflict copies
	$EXIT_DRIFT     4  verify found the tree differs from its record

=head1 LIMITATIONS

Readonly values cannot be changed with C<local>.  Values the tests need to
shrink (C<$App::FileSync::Client::LOG_LIMIT>, the chunk sizes and the
C<$App::FileSync::Delta> thresholds) are therefore ordinary package variables
in their own modules.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
