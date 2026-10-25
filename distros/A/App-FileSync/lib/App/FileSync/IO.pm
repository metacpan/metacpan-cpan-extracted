package App::FileSync::IO;

# Filesystem primitives shared by the client, the server, the trash and the
# snapshots.  Each one used to be written out two to four times; keeping them
# here means a fix (such as O_EXCL temporaries) lands everywhere at once.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Digest::SHA ();
use Exporter qw(import);
use File::Basename qw(dirname);
use File::Copy ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes ();

use App::FileSync::Constants qw($MODE_MASK $TEMP_PREFIX);
use App::FileSync::I18N qw(throw os_error strip_location);

use version; our $VERSION = version->declare('0.001.2');

our @EXPORT_OK = qw(
	read_text open_file temp_file write_atomic install_file clear_target
	set_mtime sha256_file list_dir copy_preserving append_line ensure_dir
);

# File::Temp wants at least four X's; ten keep collisions out of reach even
# with thousands of uploads in one directory.
Readonly my $TEMP_TEMPLATE => $TEMP_PREFIX . ('X' x 10);

# Catalogue key for each open mode, so the error names what was attempted.
Readonly my %OPEN_KEY => (
	'<'  => 'io.read',
	'>'  => 'io.write',
	'>>' => 'io.append',
);

# The permission bits a new file would get from open() under the current
# umask.  File::Temp creates 0600 files, which would otherwise leak into the
# master and every replica.
Readonly my $CREATE_MODE => oct('666');

# Windows has no POSIX permission bits worth setting.
Readonly my $HAS_MODES => $^O ne 'MSWin32';

=encoding utf8

=head1 NAME

App::FileSync::IO - filesystem primitives for App::FileSync

=head1 SYNOPSIS

	use App::FileSync::IO qw(write_atomic read_text sha256_file);

	write_atomic('/srv/filesync/.filesync/repos/docs/master.json', $json);
	my $text = read_text($path);

=head1 DESCRIPTION

Every function raises a catalogued error (see L<App::FileSync::I18N>) that
names the path and carries the operating system's reason.

=head1 FUNCTIONS

=head2 open_file

Purpose: open a file in binary mode.

Args: C<$path>, C<$mode> (C<< < >>, C<< > >> or C<<< >> >>>).

Returns: the filehandle.

Side Effects: creates or truncates the file for C<< > >>, creates it for
C<<< >> >>>.

Usage:

	my $fh = open_file($path, '<');

=head3 EXAMPLE

	my $out = open_file('/tmp/report.bin', '>');
	print {$out} $bytes;
	close $out;

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path', type => 'string', min => 1 },
		{ name => 'mode', type => 'string', memberof => [ '<', '>', '>>' ] },
	]

=head4 OUTPUT

	{ type => 'handle' }

=head3 MESSAGES

	Key        Meaning                          Resolution
	io.read    the file cannot be opened        check it exists and is readable
	io.write   the file cannot be created       check the directory is writable
	io.append  the file cannot be appended to   check permissions and free space

=head3 FORMAL SPECIFICATION

	open_file : PATH × MODE ↛ HANDLE
	pre  mode ∈ {<, >, >>} ∧ (mode = < ⇒ path ∈ dom FS)
	post mode = > ⇒ FS'(path) = ⟨⟩

=cut

sub open_file {
	my ($path, $mode) = @_;

	my $fh;
	eval { open $fh, $mode, $path; 1 }
		or throw($OPEN_KEY{$mode} || 'io.read', { path => $path, error => os_error($@) });
	binmode $fh;

	return $fh;
}

=head2 read_text

Purpose: read a whole file as bytes.

Args: C<$path>.

Returns: the contents (an empty string for an empty file).

Side Effects: none.

Usage:

	my $json = read_text($config_path);

=head3 EXAMPLE

	my $marker = read_text("$root/.filesync-root");

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	Key       Meaning                     Resolution
	io.read   the file cannot be opened   check it exists and is readable

=head3 FORMAL SPECIFICATION

	read_text : PATH ↛ seq BYTE
	pre  path ∈ dom FS
	post result = FS(path)

=cut

sub read_text {
	my ($path) = @_;

	my $fh = open_file($path, '<');
	my $text = do { local $/; <$fh> };
	close $fh;

	return defined $text ? $text : '';
}

=head2 temp_file

Purpose: create a temporary file beside its final location.

Args: C<$directory>; created if missing.

Returns: an arrayref C<[ $filehandle, $path ]>.

Side Effects: creates the file exclusively (C<O_EXCL>), so a planted file or
symlink of the same name cannot be written through.  Its permissions are those
an ordinary C<open> would give under the current umask.  The name starts with
C<.filesync-tmp->, which the scanner ignores and stale-temp cleanup removes.

Usage:

	my ($fh, $temp) = @{ temp_file($directory) };

=head3 EXAMPLE

	my ($fh, $temp) = @{ temp_file('/home/foo/Documents/notes') };
	print {$fh} $bytes;
	close $fh;
	install_file($temp, '/home/foo/Documents/notes/plan.txt');

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'directory', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'arrayref', min => 2, max => 2 }

=head3 MESSAGES

	Key          Meaning                                  Resolution
	io.mkdir     the directory cannot be created          check permissions
	io.temp      no temporary file can be made there      check permissions and free space

=head3 FORMAL SPECIFICATION

	ΔFS
	dir? : PATH ; t! : PATH
	t! ∉ dom FS ∧ dirname(t!) = dir? ∧ FS' = FS ∪ {t! ↦ ⟨⟩}

=cut

sub temp_file {
	my ($directory) = @_;

	ensure_dir($directory);

	my ($fh, $path);
	eval {
		($fh, $path) = File::Temp::tempfile($TEMP_TEMPLATE, DIR => $directory, UNLINK => 0);
		1;
	} or throw('io.temp', { path => $directory, error => os_error($@) });

	binmode $fh;
	chmod($CREATE_MODE & ~umask, $path) if $HAS_MODES;

	return [ $fh, $path ];
}

=head2 write_atomic

Purpose: replace a file's contents so readers see the old or the new version,
never a mixture.

Args: C<$path>, C<$data> (bytes).

Returns: 1.

Side Effects: creates missing parent directories; writes a temporary file in
the same directory and renames it over C<$path>.  The temporary file is
removed if any step fails.

Usage:

	write_atomic($path, json_encode($config) . "\n");

=head3 EXAMPLE

	write_atomic('/tmp/state.json', qq({"ok":1}\n));

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path', type => 'string', min => 1 },
		{ name => 'data', type => 'string' },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key        Meaning                                Resolution
	io.temp    no temporary file can be created       check permissions and space
	io.write   writing or closing the file failed     check free space
	io.rename  the new file cannot replace the old    check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	path? : PATH ; data? : seq BYTE
	FS'(path?) = data?
	∀ t : dom FS' \ dom FS • ¬ prefix(TEMP, basename t)

=cut

sub write_atomic {
	my ($path, $data) = @_;

	my ($fh, $temp) = @{ temp_file(dirname($path)) };

	# print is outside autodie's reach, so its failure is checked here.
	my $written = print {$fh} $data;
	my $closed  = eval { close $fh; 1 };
	unless ($written && $closed) {
		my $error = os_error($@);
		_discard($temp);
		throw('io.write', { path => $temp, error => $error });
	}

	_rename_or_discard($temp, $path);
	return 1;
}

=head2 install_file

Purpose: move a verified temporary file into place.

Args: C<$temp>, C<$target>, optional C<$mtime> (epoch, may be fractional) and
C<$mode> (permission bits).

Returns: C<$target>.

Side Effects: sets the mode (not on Windows) and mtime on C<$temp>, removes
whatever is at C<$target> (a file, a symlink or an empty directory), then
renames.  C<$temp> is removed if the rename fails.

Usage:

	install_file($temp, $abs, $mtime, $mode);

=head3 EXAMPLE

	my ($fh, $temp) = @{ temp_file($dir) };
	print {$fh} $content;
	close $fh;
	install_file($temp, "$dir/report.txt", 1_700_000_000, oct(644));

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'temp',   type => 'string', min => 1 },
		{ name => 'target', type => 'string', min => 1 },
		{ name => 'mtime',  type => 'number', optional => 1 },
		{ name => 'mode',   type => 'integer', optional => 1, min => 0 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key                Meaning                                     Resolution
	io.remove          the old file cannot be removed              check permissions
	io.replace_dir     a non-empty directory is in the way         move it aside
	io.rename          the new file cannot be moved into place     check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	temp?, target? : PATH
	pre  temp? ∈ dom FS
	post FS'(target?) = FS(temp?) ∧ temp? ∉ dom FS'

=cut

sub install_file {
	my ($temp, $target, $mtime, $mode) = @_;

	chmod($mode & $MODE_MASK, $temp) if defined $mode && $HAS_MODES;
	set_mtime($temp, $mtime);

	clear_target($target);
	_rename_or_discard($temp, $target);

	return $target;
}

=head2 clear_target

Purpose: make room for a file at C<$path>.

Args: C<$path>.

Returns: 1.

Side Effects: removes a symlink or file at C<$path>, or an empty directory.
A non-empty directory is never removed.

Usage:

	clear_target($abs);

=head3 EXAMPLE

	clear_target('/tmp/old-copy.txt');

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key              Meaning                              Resolution
	io.remove        the file or symlink cannot go        check permissions
	io.replace_dir   a non-empty directory is in the way  move it aside

=head3 FORMAL SPECIFICATION

	ΔFS
	path? : PATH
	path? ∈ dom FS ∧ (kind path? ≠ dir ∨ children path? = ∅) ⇒ path? ∉ dom FS'

=cut

sub clear_target {
	my ($path) = @_;

	# Symlinks first: -d follows them, and a link to a directory must be
	# unlinked, not rmdir'ed.
	if (-l $path || (-e _ && !-d _)) {
		eval { unlink $path; 1 } or throw('io.remove', { path => $path, error => os_error($@) });
	} elsif (-d _) {
		eval { rmdir $path; 1 } or throw('io.replace_dir', { path => $path });
	}

	return 1;
}

=head2 set_mtime

Purpose: set a file's modification time, keeping sub-second precision where
the platform allows.

Args: C<$path>, C<$mtime> (epoch; C<undef> leaves the file alone).

Returns: 1.

Side Effects: changes the file's atime and mtime.  Where C<Time::HiRes::utime>
is unimplemented (some Windows builds) whole seconds are stored, which the
2-second comparison tolerance already allows for.

Usage:

	set_mtime($temp, 1_700_000_123.456);

=head3 EXAMPLE

	set_mtime('/tmp/a.txt', time - 3600);

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path',  type => 'string', min => 1 },
		{ name => 'mtime', type => 'number', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key        Meaning                         Resolution
	io.utime   the timestamp cannot be set     check ownership of the file

=head3 FORMAL SPECIFICATION

	ΔFS
	path? : PATH ; m? : ℝ ∪ {⊥}
	m? = ⊥ ⇒ FS' = FS
	m? ≠ ⊥ ⇒ |mtime'(path?) − m?| < 1

=cut

sub set_mtime {
	my ($path, $mtime) = @_;

	return 1 if !defined $mtime || eval { Time::HiRes::utime($mtime, $mtime, $path); 1 };

	# Only the "unimplemented" croak is expected; anything else is a real
	# failure, reported with the reason Time::HiRes gave.
	my $error = $@;
	throw('io.utime', { path => $path, error => strip_location($error) })
		unless !ref $error && $error =~ /unimplemented/i;

	eval { utime(int($mtime), int($mtime), $path); 1 }
		or throw('io.utime', { path => $path, error => os_error($@) });
	return 1;
}

=head2 sha256_file

Purpose: hash a file's contents.

Args: C<$path>.

Returns: the lower-case hex SHA-256, or C<undef> when C<$path> is not a
readable regular file.

Side Effects: none.

Usage:

	my $hash = sha256_file($abs);

=head3 EXAMPLE

	print sha256_file('/etc/hostname'), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'string', optional => 1, matches => qr/\A[0-9a-f]{64}\z/ }

=head3 MESSAGES

None; an unreadable file yields C<undef>.

=head3 FORMAL SPECIFICATION

	sha256_file : PATH ⇸ HEX64
	sha256_file(p) = sha256(FS(p))   if p ∈ dom FS ∧ kind p = file ∧ readable p

=cut

sub sha256_file {
	my ($path) = @_;

	my $sha = Digest::SHA->new(256);
	my $ok = -f $path && eval { $sha->addfile($path, 'b'); 1 };

	return $ok ? $sha->hexdigest() : undef;
}

=head2 list_dir

Purpose: the entries of a directory.

Args: C<$directory>.

Returns: an arrayref of names, sorted, without C<.> and C<..>; C<undef> when
the directory cannot be read (C<$!> says why).

Side Effects: none.

Usage:

	my $names = list_dir($dir) or return 0;

=head3 EXAMPLE

	print "$_\n" for @{ list_dir('/tmp') || [] };

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'directory', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'arrayref', optional => 1 }

=head3 MESSAGES

None; an unreadable directory yields C<undef>.

=head3 FORMAL SPECIFICATION

	list_dir : PATH ⇸ seq NAME
	list_dir(d) = sort(children d \ {".", ".."})   if readable d

=cut

sub list_dir {
	my ($directory) = @_;

	# A missing or unreadable directory is an answer here, not an exception,
	# so autodie is switched off for this one call and $! is left for the
	# caller to report.
	my $dh;
	my $opened = do { no autodie qw(opendir); opendir($dh, $directory) };
	return undef unless $opened;	## no critic (Subroutines::ProhibitExplicitReturnUndef)

	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
	closedir $dh;

	return \@names;
}

=head2 copy_preserving

Purpose: copy one regular file, keeping its mode and mtime.

Args: C<$source>, C<$destination>, optional C<\@stat> of the source (saves a
second C<stat> when the caller already has one).

Returns: 1.

Side Effects: creates C<$destination>'s parent directories; overwrites
C<$destination>.

Usage:

	copy_preserving($from, $to, \@stat);

=head3 EXAMPLE

	copy_preserving('/srv/a.txt', '/backup/a.txt');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'source',      type => 'string', min => 1 },
		{ name => 'destination', type => 'string', min => 1 },
		{ name => 'stat',        type => 'arrayref', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key       Meaning                      Resolution
	io.copy   the copy could not be made   check space and permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	src?, dst? : PATH
	FS'(dst?) = FS(src?) ∧ mtime'(dst?) = mtime(src?) ∧ mode'(dst?) = mode(src?)

=cut

sub copy_preserving {
	my ($source, $destination, $stat) = @_;

	$stat = [ Time::HiRes::stat($source) ] unless ref($stat) eq 'ARRAY' && @{$stat};
	ensure_dir(dirname($destination));

	File::Copy::copy($source, $destination)
		or throw('io.copy', { from => $source, to => $destination, error => "$!" });

	chmod($stat->[2] & $MODE_MASK, $destination) if $HAS_MODES;
	utime($stat->[9], $stat->[9], $destination);

	return 1;
}

=head2 append_line

Purpose: append one line to a log or journal.

Args: C<$path>, C<$line> (without a newline).

Returns: 1.

Side Effects: creates C<$path> and its directory if needed.  If the file ends
in a torn line from a killed run, a newline is written first so the new entry
is not glued to the fragment.

Usage:

	append_line($journal, json_encode($event));

=head3 EXAMPLE

	append_line('/tmp/run.log', 'started');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path', type => 'string', min => 1 },
		{ name => 'line', type => 'string' },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key         Meaning                           Resolution
	io.append   the file cannot be appended to    check permissions and space

=head3 FORMAL SPECIFICATION

	ΔFS
	path? : PATH ; line? : seq CHAR
	let old = FS(path?) if path? ∈ dom FS, else ⟨⟩
	let sep = "\n" if old ≠ ⟨⟩ ∧ last old ≠ "\n", else ⟨⟩
	FS'(path?) = old ⁀ sep ⁀ line? ⁀ "\n"

=cut

sub append_line {
	my ($path, $line) = @_;

	ensure_dir(dirname($path));
	my $prefix = _ends_mid_line($path) ? "\n" : '';

	my $fh = open_file($path, '>>');
	my $written = print {$fh} $prefix, $line, "\n";
	my $closed  = eval { close $fh; 1 };
	throw('io.append', { path => $path, error => os_error($@) }) unless $written && $closed;

	return 1;
}

=head2 ensure_dir

Purpose: make sure a directory exists.

Args: C<$directory>.

Returns: C<$directory>.

Side Effects: creates it and any missing parents.

Usage:

	ensure_dir(dirname($path));

=head3 EXAMPLE

	ensure_dir('/tmp/a/b/c');

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'directory', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key        Meaning                          Resolution
	io.mkdir   the directory cannot be created  check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	d? : PATH
	kind'(d?) = dir ∧ ∀ a : ancestors d? • kind'(a) = dir

=cut

sub ensure_dir {
	my ($directory) = @_;

	unless (-d $directory) {
		make_path($directory, { error => \my $errors });
		throw('io.mkdir', { path => $directory, error => _path_error($errors) })
			unless -d $directory;
	}

	return $directory;
}

# _rename_or_discard
# Purpose:     rename a temporary file over its target.
# Entry:       $temp exists; $target's directory exists.
# Exit:        returns 1, or raises io.rename after removing $temp.
# Side effects: $temp disappears either way.
sub _rename_or_discard :Private {
	my ($temp, $target) = @_;

	unless (eval { rename $temp, $target; 1 }) {
		my $error = os_error($@);
		_discard($temp);
		throw('io.rename', { from => $temp, to => $target, error => $error });
	}

	return 1;
}

# _discard
# Purpose:     best-effort removal of a temporary file after a failure.
# Entry:       $path may or may not exist.
# Exit:        returns 1.
# Side effects: removes $path when it can; never raises, so the original
#              error is the one the caller reports.
sub _discard :Private {
	my ($path) = @_;

	{ no autodie qw(unlink); unlink $path }
	return 1;
}

# _ends_mid_line
# Purpose:     detect a log or journal whose last line was torn by a kill.
# Entry:       $path may or may not exist.
# Exit:        returns 1 when the file is non-empty and its last byte is not
#              a newline, otherwise 0.
# Side effects: none.
sub _ends_mid_line :Private {
	my ($path) = @_;

	return 0 unless -s $path;

	my $fh = open_file($path, '<');
	seek($fh, -1, 2);
	read($fh, my $last, 1);
	close $fh;

	return (defined $last && $last ne "\n") ? 1 : 0;
}

# _path_error
# Purpose:     the first reason File::Path recorded, for an io.mkdir message.
# Entry:       $errors is File::Path's error arrayref (may be undef or empty).
# Exit:        returns the reason text, or the current $! when there is none.
# Side effects: none.
sub _path_error :Private {
	my ($errors) = @_;

	my ($first) = @{ $errors || [] };
	my ($reason) = $first ? values %{$first} : ();
	return defined $reason && length $reason ? $reason : "$!";
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Nothing is fsync'ed.  A rename is atomic against other processes, but
after a power cut the new name can point at a file whose data never reached
the disk.  Adding C<IO::Handle::sync> before each rename would make every
upload pay a disk flush; the trade-off has not been measured yet.

=item * C<File::Copy::copy> does not copy extended attributes, ACLs or
alternate data streams.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
