package App::FileSync;

use strict;
use warnings;
use Exporter 'import';

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();
use Time::HiRes ();
use Time::Local ();

our $VERSION = '0.001.0';

our @EXPORT_OK = qw(
	json_encode json_decode
	validate_relpath validate_repo_name validate_client_id
	conflict_name format_utc parse_since parse_until
	write_atomic read_text set_mtime
);

# Deliberately utf8(0): paths are byte strings on the wire, and both ends of the
# protocol are this implementation.
my $JSON = JSON::PP->new->canonical->allow_nonref;

sub json_encode { return $JSON->encode($_[0]) }

sub json_decode {
	my $data = $JSON->decode($_[0]);
	_to_bytes($data);
	return $data;
}

# JSON::PP returns UTF8-flagged strings even though paths are byte strings on
# disk.  Left alone, the flag makes -e/stat encode the name a second time and
# every non-ASCII file "disappears".  Downgrade back to the original bytes;
# only a genuine wide character string is encoded as UTF-8.
sub _to_bytes {
	# Work through @_ aliases: copying the scalar would rewrite the copy only.
	if (ref($_[0]) eq 'HASH') {
		_to_bytes($_) for values %{ $_[0] };
	} elsif (ref($_[0]) eq 'ARRAY') {
		_to_bytes($_) for @{ $_[0] };
	} elsif (defined($_[0]) && !ref($_[0]) && utf8::is_utf8($_[0])) {
		utf8::encode($_[0]) unless utf8::downgrade($_[0], 1);
	}

	return 1;
}

sub read_text {
	my ($path) = @_;
	open my $fh, '<', $path or die "Cannot read $path: $!\n";
	binmode $fh;
	local $/;
	my $text = <$fh>;
	close $fh;
	return defined $text ? $text : '';
}

# Set a file's mtime, keeping sub-second precision where the platform provides
# it.  Time::HiRes::utime dies as unimplemented on some Windows builds, where
# the builtin utime still works but stores whole seconds (on FAT, 2-second
# units), which the 2-second comparison tolerance already allows for.
sub set_mtime {
	my ($path, $mtime) = @_;
	return 1 unless defined $mtime;

	return 1 if eval { Time::HiRes::utime($mtime, $mtime, $path); 1 };

	# Only the "unimplemented" croak is expected; anything else is a real
	# failure and is reported as it was before this fallback existed.
	my $error = $@;
	die $error unless !ref $error && $error =~ /unimplemented/i;

	utime(int($mtime), int($mtime), $path);
	return 1;
}

# Replace $path with $data, atomically: temp file in the same directory, then rename.
sub write_atomic {
	my ($path, $data) = @_;

	my $dir = dirname($path);
	make_path($dir) unless -d $dir;

	my $tmp = File::Spec->catfile($dir, '.filesync-tmp-' . $$ . '-' . int(rand(1_000_000)));
	open my $fh, '>', $tmp or die "Cannot write $tmp: $!";
	binmode $fh;

    print {$fh} $data or do {
        my $error = $!;
        close $fh;
        unlink $tmp;
        die "Cannot write $tmp: $error";
    };
    close $fh or die "Cannot close $tmp: $!";

    rename $tmp, $path or do {
        my $error = $!;
        unlink $tmp;
        die "Cannot rename $tmp to $path: $error";
    };

	return 1;
}

# Returns (1, undef) for a usable relative path, (0, reason) otherwise.
# Paths on the wire are relative, "/"-separated and free of "." and "..".
# Both ends validate, so a path can never escape the tree it is joined to.
our $MAX_PATH_BYTES      = 4096;
our $MAX_COMPONENT_BYTES = 255;

sub validate_relpath {
	my ($path) = @_;

    return (0, 'missing path') unless defined $path;
    return (0, 'path is not text') if ref $path;
    return (0, 'empty path') unless length $path;
    return (0, 'path is too long') if length($path) > $MAX_PATH_BYTES;
    return (0, 'absolute path') if $path =~ m{\A/};
    return (0, 'drive-relative path') if $path =~ /\A[A-Za-z]:/;
    return (0, 'backslash in path') if $path =~ /\\/;
    return (0, 'NUL in path') if $path =~ /\0/;
    return (0, 'control character in path') if $path =~ /[\x01-\x1f\x7f]/;

    for my $part (split m{/}, $path, -1) {
        return (0, 'empty path component') if $part eq '';
        return (0, 'dot path component') if $part eq '.';
        return (0, 'parent path component') if $part eq '..';
        return (0, 'path component is too long')
            if length($part) > $MAX_COMPONENT_BYTES;
    }

    return (1, undef);
}

# Repo and client ids become directory names under the server root and under
# ~/.filesync, so they are held to the same alphabet as a path component.
sub _validate_id {
    my ($what, $value) = @_;

    return (0, "missing $what") unless defined $value;
    return (0, "$what is not text") if ref $value;
    return (0, "empty $what") unless length $value;
    return (0, "$what is too long") if length($value) > 64;
    return (0, "bad $what '$value'")
        unless $value =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;

    return (1, undef);
}

sub validate_repo_name   { return _validate_id('repo name',   $_[0]) }
sub validate_client_id   { return _validate_id('client id',   $_[0]) }

# "2026-10-22" or an epoch.  Returns the epoch and whether the input was a
# date, because a date cutoff means a different instant at each end of a range.
sub _parse_when {
    my ($value, $option) = @_;

    return (undef, 0) unless defined $value;
    return ($value + 0, 0) if $value =~ /\A\d+\z/;

    if ($value =~ /\A(\d{4})-(\d{2})-(\d{2})\z/) {
        return (Time::Local::timegm(0, 0, 0, $3, $2 - 1, $1), 1);
    }

    die "Bad $option '$value' (use YYYY-MM-DD or an epoch)\n";
}

# Start of the window: a date means midnight UTC that day.
sub parse_since {
	my ($value, $option) = @_;
	my ($epoch) = _parse_when($value, $option || '--since');
	return $epoch;
}

# End of the window: a date means the last second of that day, so "--until
# 2026-10-22" includes that day's runs rather than stopping at its midnight.
sub parse_until {
    my ($value, $option) = @_;
    my ($epoch, $is_date) = _parse_when($value, $option || '--until');
    return undef unless defined $epoch;
    return $is_date ? $epoch + 86_399 : $epoch;
}

sub format_utc {
    my ($epoch) = @_;
    $epoch = time unless defined $epoch;
    my @t = gmtime($epoch);
    return sprintf('%04d%02d%02dT%02d%02d%02dZ',
        $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

# "report.txt" edited on laptop-1 at 10:15:00Z becomes
# "report.conflict-laptop-1-20261022T101500Z.txt".
sub conflict_name {
    my ($path, $client_id, $epoch) = @_;

    my ($dir, $base) = ('', $path);
    if ($path =~ m{\A(.*)/([^/]+)\z}) {
        ($dir, $base) = ($1, $2);
    }

    my ($stem, $ext) = ($base, '');
    if ($base =~ /\A(.+)(\.[^.]+)\z/) {
        ($stem, $ext) = ($1, $2);
    }

    my $id = defined $client_id ? $client_id : 'unknown';
    $id =~ s/[^A-Za-z0-9._-]+/_/g;
    $id = 'unknown' unless length $id;

    my $stamp = format_utc($epoch);

    # Keep the whole name inside the 255-byte limit of common filesystems.
    my $room = 200 - length(".conflict-$id-$stamp$ext");
    $room = 16 if $room < 16;
    $stem = substr($stem, 0, $room) if length($stem) > $room;

	my $name = "$stem.conflict-$id-$stamp$ext";
	return length($dir) ? "$dir/$name" : $name;
}

1;

__END__

=head1 NAME

App::FileSync - cron-driven file synchronisation without a daemon

=head1 SYNOPSIS

    filesync init --repo documents --root ~/Documents \
        --transport local --server-root /srv/filesync --remote-repo documents
    filesync sync --repo documents --dry-run
    filesync sync --repo documents

=head1 DESCRIPTION

App::FileSync keeps one directory per client in step with a master copy on a server, and
keeps a separate machine holding a replica of that master.  Every run is a short-lived CLI
process suitable for cron or the Windows Task Scheduler: there is no daemon, no database
and no web interface.

Only files whose content changed are transferred.  Data frames are deflated when that
makes them smaller, and files of at least 64 KiB are sent as rsync-style block deltas
when the other side already holds an older copy, so an edit moves the changed blocks
rather than the whole file.  C<filesync sync --no-delta> forces whole files.  Each run
reports the payload bytes it sent and received and how many files moved as a delta, and
C<filesync log> repeats those figures for past runs.

This module holds the pieces shared by the client, the server and the admin tools:
byte-transparent JSON, path validation, conflict-copy naming and atomic file writes.

=head1 FUNCTIONS

=head2 json_encode

=head2 json_decode

Encode and decode a structure as a single line of JSON.  Paths are byte strings and are
not treated as UTF-8 by these functions.

=head2 validate_relpath

Returns C<(1, undef)> for a safe relative path, or C<(0, $reason)>.  Absolute paths,
backslashes, control characters, empty, C<.> and C<..> components, and paths longer than
4096 bytes or with a component longer than 255 bytes are rejected.

=head2 validate_repo_name

=head2 validate_client_id

Return C<(1, undef)> for a name usable as a directory name (C<[A-Za-z0-9][A-Za-z0-9._-]*>,
at most 64 characters), or C<(0, $reason)>.

=head2 conflict_name

    my $name = conflict_name('notes.txt', 'laptop-1', time);

Returns the conflict-copy name for a losing version: the original name with
C<.conflict-E<lt>clientE<gt>-E<lt>timestampE<gt>> inserted before the extension.

=head2 format_utc

Formats an epoch as C<YYYYMMDDTHHMMSSZ>.

=head2 write_atomic

Writes a file through a temporary file in the same directory and renames it into place.

=head1 EXAMPLES

On the server, create the master copy and allow the client once.  Then, on each
client, register the directory and add a cron entry that runs every minute:

    # once, on the client
    filesync init --repo documents --root /home/foo/Documents --server srv

    # crontab -e, for foo on each client
    * * * * * /usr/local/bin/filesync sync --repo documents --quiet >/dev/null

The summary line is dropped so cron does not mail on every successful run;
diagnostics still go to standard error, so a failure is mailed.  Every attempt,
successful or not, is also appended to F<~/.filesync/logs/documents.jsonl>, and
C<filesync log --repo documents --exit 1> lists the ones that failed.

Windows clients use a scheduled task rather than cron.  With the script in
F<C:\filesync> and Strawberry Perl installed, the same job is set up from a
command prompt:

    REM once, on the client
    C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync init ^
      --repo documents --root C:\Users\foo\Documents --server srv

    REM then create the task; it runs every minute as the current user
    schtasks /Create /SC MINUTE /MO 1 /TN FileSync /F ^
      /TR "C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync sync --repo documents --quiet"

The task runs only while that user is logged on, which suits a Documents
folder; its run log is still written under F<%USERPROFILE%\.filesync\logs>, so
C<filesync log --repo documents --warnings> works there too.

The master copy on the server is an ordinary directory tree, so it can be
mirrored to a backup directory from the same crontab:

    # crontab -e, for foo on the server
    * * * * * rsync -a --delete --exclude '.filesync-tmp-*' \
        /home/foo/FileSync/ /home/foo/backups/FileSync/

Filesync writes each file to a temporary name and renames it into place, so the
mirror never catches a half-written upload; the exclusion keeps the temporary
files themselves out of the backup.  C<--delete> makes the copy a mirror: a
deletion that reaches the master also removes the backed-up file.

To restore the master from that backup, stop the client jobs (comment out their
cron lines, or disable the scheduled task) and the server's backup job, so the
backup job cannot copy a half-restored tree back into the backup.  Let any
running sync finish, then mirror the backup back:

    rsync -a --delete --checksum /home/foo/backups/FileSync/ /home/foo/FileSync/

C<--checksum> compares the contents, so a restored file is not skipped just
because its size and modification time happen to match the newer copy.  This is
a rollback rather than a merge: files created after the backup was taken
disappear from the master, and the next sync propagates that to the clients, so
copy anything you need to keep out of the tree first.  The server
would rehash the restored files on the next session anyway, but
C<filesync-admin reindex> rebuilds the index immediately, before any client
reconnects; clients then pull the restored versions, merging edits they have not
synced as usual.

Before re-enabling the jobs, check that the copy is exact with a read-only
comparison against the backup:

    rsync -a --delete --checksum --dry-run --itemize-changes \
        /home/foo/backups/FileSync/ /home/foo/FileSync/

No output and exit 0 mean the master matches the backup.  Any line beginning
C<< >f >> names a path that still differs, and C<*deleting> names one the
rollback should have removed.  The index still describes the pre-rollback tree,
so C<filesync-admin verify> may report drift at this point; that is expected.
Rebuild it and check it:

    sudo -u filesync filesync-admin reindex documents
    sudo -u filesync filesync-admin verify documents --deep

C<reindex> hashes every file in the master and replaces the index atomically; it
refuses to run while a sync session holds the repo lock, and it names any paths
it could not index.  C<clean> and exit 0 from C<verify> confirm that the master
and its index agree.  Re-enable the jobs once that check passes.

To restore just one file or directory, copy that path back instead of mirroring
the whole tree, with the jobs paused as above so nothing changes the tree while
the copy runs:

    rsync -a --checksum /home/foo/backups/FileSync/notes/plan.txt /home/foo/FileSync/notes/
    rsync -a --checksum /home/foo/backups/FileSync/photos/ /home/foo/FileSync/photos/

The trailing slash on the second source copies the directory's contents; without
it rsync would put the directory itself inside the destination.  Add C<--delete>
only when that directory should match the backup exactly, since it removes files
created after the backup was taken.  Everything outside the restored paths is
left alone; refresh the index with C<reindex> as above, or let the next session
do it, and clients pull the restored versions.  Check the restored paths with the
matching C<rsync --dry-run --itemize-changes> comparison before re-enabling the
jobs; no output means they match the backup.

Adjust F</usr/local/bin/filesync> to where the script was installed, because
cron's default PATH rarely includes a per-user Perl bin directory.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/App-FileSync/coverage/>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
