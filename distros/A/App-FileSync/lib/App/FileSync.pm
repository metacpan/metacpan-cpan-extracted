package App::FileSync;

# The pieces shared by the client, the server and the admin tools:
# byte-transparent JSON, path and id validation, conflict-copy naming, date
# parsing and (re-exported from App::FileSync::IO) atomic file writes.

# TODO: from the 0.002.0 gap analysis.  Pre-release blockers first.
#
# Behaviour that is silently wrong or inconsistent:
# TODO: trash retention of 0 means different things on each side: the client's
#	local_trash_days 0 keeps trash forever (Client.pm, "//"), the server's
#	trash_days 0 silently becomes 30 days (Store.pm prune_trash, "||").
#	Pick one meaning, document it, add a regression test.
# TODO: document for users that 0 switches off --max-deletes and
#	--max-delete-percent (only Merge's internal POD says so; not the help
#	text, the admin POD or website/html/commands.html).
# TODO: give --max-delete-percent an upper bound of 100 (150 is accepted).
# TODO: Params::Validate::Strict failures bypass the catalogue and name the
#	internal parameter ('trash_days') instead of the option (--trash-days).
# TODO: I18N::warning is exported but never called or tested, and its
#	trailing "\n" to carp puts the location on its own line, unlike its
#	FORMAL SPECIFICATION.  Test and fix it, or remove it.
#
# Failure and rollback paths no test runs:
# TODO: Delta past the 8 MiB scan window (the literal tail loop in diff):
#	large-file deltas are unverified; "local $SCAN_LIMIT" makes it cheap.
# TODO: Snapshot rollback: a failed build should remove its temp directory.
# TODO: IO::write_atomic failure (a full disk): the temp file is discarded.
# TODO: Scan::clean_stale_temps never deletes a stale temp in any test.
# TODO: type changes: moving a directory into the trash (Trash::move_to_trash)
#	and replacing a directory with a file (IO::clear_target).
# TODO: the admin root-not-writable path in Admin::repo_create.
#
# Commands and APIs with no tests:
# TODO: filesync-admin "repo show" and "client list" (Admin::repo_show,
#	Admin::client_list) never run, in-process or through the CLI.
# TODO: Protocol::close, Transport::SSH::command and exit_status,
#	Transport::Local::error_text, Store::root and Store::repo.
# TODO: the extra_args check in Transport::SSH->new has never run.
#
# Mutation testing:
# TODO: the 80% score is 10 mutants, all in Platform.pm.  Mutation-test Merge,
#	Delta, the server's %MAY table and the deletion guard.
# TODO: kill the two survivors: nothing checks the return value of
#	Platform::use_plain_end_of_scope_hook.
#
# Documentation:
# TODO: =head3 PSEUDOCODE for the 24 public routines over 15 lines without it
#	(Server::new, Client::new, Trash::move_to_trash and prune,
#	Merge::check_delete_limit, Scan::clean_stale_temps, Ignore::new, ...).
# TODO: UTF-8 notes in Scan, Ignore, Trash, Snapshot and Store: names are
#	bytes, and NFC and NFD forms of a name are different files.
# TODO: warn when the client cache is damaged: the run silently re-hashes
#	every file (no data is at risk; the merge base is on the server).
# TODO: remove the unused message key word.snapshot, and make t/locales.t
#	report unused keys as well as missing ones.
#
# Post-release roadmap: features.
# TODO: incremental manifests (a change journal or Merkle summary), so an
#	idle run costs almost nothing instead of O(files).
# TODO: "filesync watch": sync on file changes (inotify, FSEvents,
#	ReadDirectoryChangesW), with cron as the fallback.
# TODO: let a client restore from the server's trash (admin-only today).
# TODO: selective sync: a client takes only a subtree of a repo.
# TODO: --bwlimit and a quiet-hours window for metered links.
# TODO: monitoring output: a node-exporter textfile, or a status --json health
#	summary that alerts on repeated exit codes 3 or 4.
# TODO: reconcile NFC and NFD forms of a name (the macOS/Linux gap).
# TODO: a conflict review command to list and resolve conflict copies.
#
# Post-release roadmap: technical debt.
# TODO: widen mutation testing (Merge, Delta, Server, Trash first) and gate CI
#	on condition coverage (57% now).
# TODO: pipeline the protocol: one request in flight bounds throughput by the
#	round-trip time.
# TODO: stream the plan as JSON lines instead of one huge line, which also
#	bounds message size.
# TODO: fsync: renames are atomic between processes but not durable across a
#	power cut.
# TODO: an optional native rolling checksum (Inline::C or XS) to lift the
#	8 MiB scan window; pure Perl manages about 2.5 MB/s when nothing matches.
# TODO: one validation error layer that turns Params::Validate::Strict
#	failures into catalogue messages naming the CLI option.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);
use feature 'current_sub';

use Exporter qw(import);
use JSON::MaybeXS ();
use POSIX qw(strftime);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::Local ();

use App::FileSync::Constants qw($MAX_ID_LENGTH $SECONDS_PER_DAY);
use App::FileSync::I18N qw(message throw);
use App::FileSync::IO qw(write_atomic read_text set_mtime);

use version; our $VERSION = version->declare('0.002.1');

our @EXPORT_OK = qw(
	json_encode json_decode
	validate_relpath validate_repo_name validate_client_id
	conflict_name name_with_suffix split_name
	format_utc parse_since parse_until
	write_atomic read_text set_mtime
);

# Limits on paths as they travel on the wire.  Package variables rather than
# Readonly because they document the protocol and tests read them.
our $MAX_PATH_BYTES      = 4096;
our $MAX_COMPONENT_BYTES = 255;

# A conflict-copy name is kept this far inside the common 255-byte limit, and
# never trims the original stem below the minimum.
Readonly::Scalar my $CONFLICT_NAME_BYTES => 200;
Readonly::Scalar my $MIN_STEM_BYTES      => 16;

# The alphabet of a repo or client id: it becomes a directory name.
Readonly my $ID_PATTERN => qr/\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;

# What an unusable client id is replaced with in a conflict-copy name.
Readonly::Scalar my $UNKNOWN_CLIENT => 'unknown';

# format_utc's ISO 8601 basic format: 20261104T014157Z.
Readonly::Scalar my $UTC_STAMP => '%Y%m%dT%H%M%SZ';

# JSON::MaybeXS picks Cpanel::JSON::XS, then JSON::XS, then the core JSON::PP,
# and installing it pulls in Cpanel::JSON::XS wherever there is a compiler.  On
# a 100,000-file manifest Cpanel::JSON::XS decodes in 0.2s where JSON::PP takes
# about 15s.  All three read any valid JSON, so a client and a server using
# different backends still understand each other.  The text differs only in
# number formatting (Cpanel::JSON::XS writes a whole-valued float as 1000.0),
# which decodes to the same value everywhere.
#
# Deliberately utf8(0): paths are byte strings on the wire, and both ends of the
# protocol are this implementation.
my $JSON = JSON::MaybeXS->new->canonical->allow_nonref;

# Both backends return UTF8-flagged strings even though paths are byte strings on
# disk.  Left alone, the flag makes -e/stat encode the name a second time and
# every non-ASCII file "disappears".  This downgrades back to the original
# bytes; only a genuine wide-character string is encoded as UTF-8.
#
# Hash keys need the same treatment, and manifests are keyed by path, but a key
# cannot be changed in place: a non-ASCII key is deleted and stored again as
# bytes.  An ASCII key names the same file flagged or not, so it is left alone,
# which keeps the cost to one pattern match per key.
#
# A lexical coderef rather than a named sub: it runs once per JSON value (six
# times per manifest entry), and the Sub::Private enforce wrapper would cost
# more than the work.  Being lexical, nothing outside this file can reach it.
my $to_bytes = sub {
	# Work through @_ aliases: copying the scalar would rewrite the copy only.
	if (ref($_[0]) eq 'HASH') {
		my $hash = $_[0];
		for my $key (grep { /[^\x00-\x7f]/ } keys %{$hash}) {
			my $bytes = $key;
			utf8::encode($bytes) unless utf8::downgrade($bytes, 1);
			# delete first: a flagged key and its bytes are the same hash key.
			my $value = delete $hash->{$key};
			$hash->{$bytes} = $value;
		}
		__SUB__->($_) for values %{$hash};
	} elsif (ref($_[0]) eq 'ARRAY') {
		__SUB__->($_) for @{ $_[0] };
	} elsif (defined($_[0]) && !ref($_[0]) && utf8::is_utf8($_[0])) {
		utf8::encode($_[0]) unless utf8::downgrade($_[0], 1);
	}
	return 1;
};

=encoding utf8

=head1 NAME

App::FileSync - cron-driven file synchronisation without a daemon

=head1 VERSION

0.002.1

=head1 SYNOPSIS

	filesync-admin --root ~/filesync repo create documents
	filesync init --repo documents --root ~/Documents \
		--transport local --server-root ~/filesync --remote-repo documents
	filesync sync --repo documents --dry-run
	filesync sync --repo documents

=head1 DESCRIPTION

App::FileSync keeps a directory on each client in step with one master copy on
the server.  Clients never talk to each other: each pushes its changes to the
master and pulls everyone else's from it, so a change made on one client - a
new file, an edit or a deletion - reaches the others on their next run.  Any
number of clients can share a repo this way.

A separate machine can hold a replica of the master.  Every run is a
short-lived CLI process suitable for cron or the Windows Task Scheduler: there
is no daemon, no database and no web interface.

Only files whose content changed are transferred.  Data frames are deflated when that
makes them smaller, and files of at least 64 KiB are sent as rsync-style block deltas
when the other side already holds an older copy, so an edit moves the changed blocks
rather than the whole file.  C<filesync sync --no-delta> forces whole files.  Each run
reports the payload bytes it sent and received and how many files moved as a delta, and
C<filesync log> repeats those figures for past runs.

Every message the tools print is looked up in a catalogue
(L<App::FileSync::I18N>), so a translation is one new catalogue.

This module holds the pieces shared by the client, the server and the admin tools:
byte-transparent JSON, path validation, conflict-copy naming and atomic file writes.

=head1 FUNCTIONS

=head2 json_encode

Purpose: encode a structure as one line of canonical JSON.

Args: C<$data>, any JSON-encodable value.

Returns: the JSON text, keys sorted, with no trailing newline.

Side Effects: none.

Usage:

	print {$fh} json_encode($event), "\n";

=head3 EXAMPLE

	print json_encode({ b => 1, a => [ 'x' ] }), "\n";	# {"a":["x"],"b":1}

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'data', type => 'scalar', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

The JSON backend's own error for a value it cannot encode (a code reference,
say).  L<JSON::MaybeXS> chooses the backend: L<Cpanel::JSON::XS>, else
L<JSON::XS>, else L<JSON::PP>.

=head3 FORMAL SPECIFICATION

	json_encode : VALUE → TEXT
	json_decode(json_encode(v)) = v

=cut

sub json_encode {
	my ($data) = @_;

	return $JSON->encode($data);
}

=head2 json_decode

Purpose: decode one JSON document, keeping strings as byte strings.

Args: C<$text>.

Returns: the decoded structure.  Strings that fit in bytes are downgraded, so a
path read back from JSON names the same file as the bytes it was written from.

Side Effects: none.

Usage:

	my $config = json_decode(read_text($path));

=head3 EXAMPLE

	my $entry = json_decode('{"p":"caf\u00e9.txt"}');
	print length($entry->{p}), "\n";	# 8 (bytes), not 9

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'text', type => 'string' } ]

=head4 OUTPUT

	{ type => 'scalar', optional => 1 }

=head3 MESSAGES

The JSON backend's own error for malformed JSON, so its wording depends on
which backend L<JSON::MaybeXS> chose (L<Cpanel::JSON::XS>, else L<JSON::XS>,
else L<JSON::PP>).

=head3 FORMAL SPECIFICATION

	json_decode : TEXT ↛ VALUE
	∀ s : STRING in result • ¬ utf8_flag(s) ∨ ∃ c ∈ s • ord c > 255

=cut

sub json_decode {
	my ($text) = @_;

	my $data = $JSON->decode($text);
	$to_bytes->($data);

	return $data;
}

=head2 validate_relpath

Purpose: decide whether a path is safe to join to a sync root.

Args: C<$path>, a relative path as it travels on the wire.

Returns: a two-element list C<(1, undef)> for a usable path, or
C<(0, $reason)> where C<$reason> is a translated explanation.  (A list rather
than a reference because every caller destructures it at once, and it is
called once per path in the tree.)

Side Effects: none.

Usage:

	my ($ok, $reason) = validate_relpath($path);

=head3 EXAMPLE

	my ($ok, $why) = validate_relpath('notes/../secret');
	print "$why\n" unless $ok;	# parent path component

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'scalar', optional => 1 } ]

=head4 OUTPUT

	{ type => 'arrayref', min => 2, max => 2 }

=head3 MESSAGES

	Key                       Meaning
	path.missing              no path was given
	path.not_text             the path is a reference
	path.empty                the path is empty
	path.too_long             longer than 4096 bytes
	path.absolute             starts with /
	path.drive                starts with a drive letter
	path.backslash            contains a backslash
	path.nul                  contains a NUL byte
	path.control              contains a control character
	path.empty_component      contains //, or starts or ends with /
	path.dot_component        has a . component
	path.parent_component     has a .. component
	path.component_too_long   a component is longer than 255 bytes

Resolution: rename the file on the side that holds it.

=head3 FORMAL SPECIFICATION

	SafePath == { p : seq BYTE |
		0 < #p ≤ 4096 ∧ head p ≠ '/' ∧ ¬ drive(p) ∧
		'\' ∉ ran p ∧ ran p ∩ CONTROL = ∅ ∧
		∀ c : split('/', p) • c ∉ {⟨⟩, ".", ".."} ∧ #c ≤ 255 }
	validate_relpath(p) = (1, ⊥)        if p ∈ SafePath
	                    = (0, reason)   otherwise

=head3 PSEUDOCODE

	reject undef, references and empty strings
	reject paths over 4096 bytes
	reject absolute, drive-relative, backslash, NUL and control characters
	for each "/"-separated component:
		reject empty, ".", ".." and components over 255 bytes
	accept

=cut

sub validate_relpath {
	my ($path) = @_;

	# One key per rejection, checked in order: the first problem found is
	# the one reported.
	my $problem =
		  !defined $path                       ? 'path.missing'
		: ref $path                            ? 'path.not_text'
		: !length $path                        ? 'path.empty'
		: length($path) > $MAX_PATH_BYTES      ? 'path.too_long'
		: $path =~ m{\A/}                      ? 'path.absolute'
		: $path =~ /\A[A-Za-z]:/               ? 'path.drive'
		: $path =~ /\\/                        ? 'path.backslash'
		: $path =~ /\0/                        ? 'path.nul'
		: $path =~ /[\x01-\x1f\x7f]/           ? 'path.control'
		: undef;

	# Components are only worth checking once the whole path is plausible.
	unless (defined $problem) {
		for my $part (split m{/}, $path, -1) {
			$problem =
				  $part eq ''                             ? 'path.empty_component'
				: $part eq '.'                            ? 'path.dot_component'
				: $part eq '..'                           ? 'path.parent_component'
				: length($part) > $MAX_COMPONENT_BYTES    ? 'path.component_too_long'
				: undef;
			last if defined $problem;
		}
	}

	return defined $problem ? (0, message($problem)) : (1, undef);
}

=head2 validate_repo_name

Documented with L</validate_client_id> below.

=head2 validate_client_id

Purpose: decide whether a repo name or client id is usable as a directory name.

Args: C<$value>.

Returns: C<(1, undef)>, or C<(0, $reason)> with a translated reason.  The
alphabet is C<[A-Za-z0-9][A-Za-z0-9._-]*>, at most 64 characters.

Side Effects: none.

Usage:

	my ($ok, $reason) = validate_client_id($id);

=head3 EXAMPLE

	my ($ok, $why) = validate_repo_name('../etc');
	print "$why\n";	# bad repo name '../etc'

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'value', type => 'scalar', optional => 1 } ]

=head4 OUTPUT

	{ type => 'arrayref', min => 2, max => 2 }

=head3 MESSAGES

	Key           Meaning                         Resolution
	id.missing    no value was given              supply one
	id.not_text   the value is a reference        pass a string
	id.empty      the value is empty              supply one
	id.too_long   longer than 64 characters       shorten it
	id.bad        outside the allowed alphabet    use letters, digits, . _ -

=head3 FORMAL SPECIFICATION

	Id == { s : seq CHAR | 0 < #s ≤ 64 ∧ head s ∈ ALNUM ∧ ran s ⊆ ALNUM ∪ {'.','_','-'} }
	validate(s) = (1, ⊥) if s ∈ Id, (0, reason) otherwise

=cut

sub validate_repo_name {
	my ($value) = @_;

	return _validate_id('id.repo_name', $value);
}

sub validate_client_id {
	my ($value) = @_;

	return _validate_id('id.client_id', $value);
}

# _validate_id
# Purpose:     shared check for repo names and client ids.
# Entry:       $what_key is the catalogue key naming the kind of id;
#              $value is the candidate.
# Exit:        returns (1, undef) or (0, translated reason).
# Side effects: none.
sub _validate_id :Private {
	my ($what_key, $value) = @_;

	my $problem =
		  !defined $value                    ? 'id.missing'
		: ref $value                         ? 'id.not_text'
		: !length $value                     ? 'id.empty'
		: length($value) > $MAX_ID_LENGTH    ? 'id.too_long'
		: $value !~ $ID_PATTERN              ? 'id.bad'
		: undef;

	return defined $problem
		? (0, message($problem, { what => message($what_key), value => $value }))
		: (1, undef);
}

=head2 parse_since

Purpose: the start of a time window.

Args: C<$value> (C<YYYY-MM-DD> or an epoch), optional C<$option> naming the
command-line option for the error message (default C<--since>).

Returns: the epoch, or C<undef> when C<$value> is undef.  A date means
midnight UTC that day.

Side Effects: none.

Usage:

	my $since = parse_since($opts{since});

=head3 EXAMPLE

	print parse_since('2026-10-22'), "\n";	# 1792627200

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'value',  type => 'string', optional => 1 },
		{ name => 'option', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', optional => 1, min => 0 }

=head3 MESSAGES

	Key        Meaning                              Resolution
	when.bad   neither a date nor an epoch          use YYYY-MM-DD or digits

=head3 FORMAL SPECIFICATION

	parse_since : (DATE ∪ ℕ ∪ {⊥}) ↛ ℕ ∪ {⊥}
	parse_since(n) = n ; parse_since(d) = midnight_utc(d) ; parse_since(⊥) = ⊥

=cut

sub parse_since {
	my ($value, $option) = @_;

	my ($epoch) = @{ _parse_when($value, $option || '--since') };
	return $epoch;
}

=head2 parse_until

Purpose: the end of a time window.

Args: as for L</parse_since> (default option name C<--until>).

Returns: the epoch, or C<undef>.  A date means the last second of that day, so
C<--until 2026-10-22> includes that day's runs.

Side Effects: none.

Usage:

	my $until = parse_until($opts{until});

=head3 EXAMPLE

	print parse_until('2026-10-22'), "\n";	# 1792713599

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'value',  type => 'string', optional => 1 },
		{ name => 'option', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', optional => 1, min => 0 }

=head3 MESSAGES

	Key        Meaning                              Resolution
	when.bad   neither a date nor an epoch          use YYYY-MM-DD or digits

=head3 FORMAL SPECIFICATION

	parse_until(n) = n ; parse_until(d) = midnight_utc(d) + 86399 ; parse_until(⊥) = ⊥

=cut

sub parse_until {
	my ($value, $option) = @_;

	my ($epoch, $is_date) = @{ _parse_when($value, $option || '--until') };
	return (defined $epoch && $is_date) ? $epoch + $SECONDS_PER_DAY - 1 : $epoch;
}

# _parse_when
# Purpose:     parse "YYYY-MM-DD" or an epoch.
# Entry:       $value may be undef; $option names the option for errors.
# Exit:        returns [ $epoch_or_undef, $is_date ]; a date cutoff means a
#              different instant at each end of a range, hence the flag.
# Side effects: raises when.bad for anything else.
sub _parse_when :Private {
	my ($value, $option) = @_;

	my $parsed =
		  !defined $value                          ? [ undef, 0 ]
		: $value =~ /\A\d+\z/                      ? [ $value + 0, 0 ]
		: $value =~ /\A(\d{4})-(\d{2})-(\d{2})\z/  ? [ Time::Local::timegm(0, 0, 0, $3, $2 - 1, $1), 1 ]
		: undef;

	throw('when.bad', { option => $option, value => $value }) unless $parsed;
	return $parsed;
}

=head2 format_utc

Purpose: a compact UTC timestamp.

Args: optional C<$epoch> (default now).

Returns: C<YYYYMMDDTHHMMSSZ>.

Side Effects: none.

Usage:

	my $stamp = format_utc($run->{ts});

=head3 EXAMPLE

	print format_utc(0), "\n";	# 19700101T000000Z

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'epoch', type => 'number', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string', matches => qr/\A\d{8}T\d{6}Z\z/ }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	format_utc : ℕ → STAMP
	format_utc(e) = yyyy mm dd 'T' HH MM SS 'Z' of gmtime(e)

=cut

sub format_utc {
	my ($epoch) = @_;

	return strftime($UTC_STAMP, gmtime($epoch // time));
}

=head2 split_name

Purpose: split a relative path into directory, stem and extension.

Args: C<$path>.

Returns: an arrayref C<[ $dir, $stem, $ext ]>; C<$dir> has no trailing slash
and is empty at the top level, C<$ext> includes its dot and is empty when there
is none.  A leading dot (C<.profile>) is part of the stem.

Side Effects: none.

Usage:

	my ($dir, $stem, $ext) = @{ split_name('a/b/report.txt') };

=head3 EXAMPLE

	my $parts = split_name('notes/plan.v2.txt');	# ['notes', 'plan.v2', '.txt']

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'arrayref', min => 3, max => 3 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	split_name(p) = (d, s, e) where p = d ⁀ "/" ⁀ s ⁀ e ∨ (d = ⟨⟩ ∧ p = s ⁀ e)
	                e = ⟨⟩ ∨ (head e = '.' ∧ '.' ∉ ran(tail e)) ; s ≠ ⟨⟩

=cut

sub split_name {
	my ($path) = @_;

	my ($dir, $base) = $path =~ m{\A(.*)/([^/]+)\z} ? ($1, $2) : ('', $path);
	my ($stem, $ext) = $base =~ /\A(.+)(\.[^.]+)\z/ ? ($1, $2) : ($base, '');

	return [ $dir, $stem, $ext ];
}

=head2 name_with_suffix

Purpose: make a name unique by numbering it before its extension.

Args: C<$path>, C<$suffix> (a number).

Returns: C<report-2.txt> for C<report.txt> and 2, keeping the directory.

Side Effects: none.

Usage:

	my $candidate = name_with_suffix($loser_name, $n);

=head3 EXAMPLE

	print name_with_suffix('a/b.txt', 3), "\n";	# a/b-3.txt

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path',   type => 'string', min => 1 },
		{ name => 'suffix', type => 'integer', min => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	let (d, s, e) = split_name(p)
	name_with_suffix(p, n) = join(d, s ⁀ "-" ⁀ n ⁀ e)

=cut

sub name_with_suffix {
	my ($path, $suffix) = @_;

	my ($dir, $stem, $ext) = @{ split_name($path) };
	return _join_dir($dir, "$stem-$suffix$ext");
}

=head2 conflict_name

Purpose: the name a losing version is kept under.

Args: C<$path>, C<$client_id> (may be undef), C<$epoch> (default now).

Returns: the original name with C<.conflict-CLIENT-TIMESTAMP> inserted before
the extension, kept within 200 bytes so it fits common filesystems.

Side Effects: none.

Usage:

	my $name = conflict_name('notes.txt', 'laptop-1', time);

=head3 EXAMPLE

	print conflict_name('report.txt', 'laptop-1', 1_792_664_100), "\n";
	# report.conflict-laptop-1-20261022T101500Z.txt

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path',      type => 'string', min => 1 },
		{ name => 'client_id', type => 'string', optional => 1 },
		{ name => 'epoch',     type => 'number', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	let (d, s, e) = split_name(p) ; id = sanitise(c) ; t = format_utc(when)
	let room = max(16, 200 − #(".conflict-" ⁀ id ⁀ "-" ⁀ t ⁀ e))
	conflict_name(p, c, when) = join(d, s[1..room] ⁀ ".conflict-" ⁀ id ⁀ "-" ⁀ t ⁀ e)

=cut

sub conflict_name {
	my ($path, $client_id, $epoch) = @_;

	my ($dir, $stem, $ext) = @{ split_name($path) };

	# The id lands in a file name, so anything outside the id alphabet is
	# flattened rather than trusted.
	my $id = defined $client_id ? $client_id : $UNKNOWN_CLIENT;
	$id =~ s/[^A-Za-z0-9._-]+/_/g;
	$id = $UNKNOWN_CLIENT unless length $id;

	my $tail = ".conflict-$id-" . format_utc($epoch) . $ext;

	# Keep the whole name inside the 255-byte limit of common filesystems.
	my $room = $CONFLICT_NAME_BYTES - length($tail);
	$room = $MIN_STEM_BYTES if $room < $MIN_STEM_BYTES;
	$stem = substr($stem, 0, $room) if length($stem) > $room;

	return _join_dir($dir, $stem . $tail);
}

# _join_dir
# Purpose:     put a relative directory and a name back together.
# Entry:       $dir may be empty (top level).
# Exit:        returns "dir/name" or "name".
# Side effects: none.
sub _join_dir :Private {
	my ($dir, $name) = @_;

	return length($dir) ? "$dir/$name" : $name;
}

=head2 write_atomic

Documented with L</set_mtime> below.

=head2 read_text

Documented with L</set_mtime> below.

=head2 set_mtime

Re-exported from L<App::FileSync::IO>, where they are documented.

=cut

1;

__END__

=head1 EXAMPLES

Two machines are involved: the server, which holds the master, and each
client, which holds a copy.  Install App::FileSync on both - C<cpanm
App::FileSync>, say - because C<filesync-admin> and C<filesync-server> run on
the server and C<filesync> on the clients.

The example keeps the master in the server account's home directory, so
nothing has to run as root.  F</srv/filesync> is the built-in default root;
"A root of /srv/filesync instead" below says what changes if you prefer it.

=head2 On the server

Create the repo as the account the clients log in to.  A session over ssh
carries only the repo, the client id and the role, so the client never tells
the server which root to use: name the same C<--root> on every server command.

	# on the server, once
	filesync-admin --root ~/filesync repo create documents
	filesync-admin --root ~/filesync client allow laptop --repo documents

C<repo create> makes the master directory and the metadata beside it, printing
both paths.  C<client allow> is optional, because a repo with no clients
admits every client, and it takes the client's id: the host name unless
C<--id> was given.

The server also needs C<--root> when C<filesync-server> starts, and the client
cannot pass one, so wrap it:

	# on the server, once
	cat > ~/bin/filesync-server-home <<'EOF'
	#!/bin/sh
	exec /usr/local/bin/filesync-server --root "$HOME/filesync" "$@"
	EOF
	chmod +x ~/bin/filesync-server-home

Use the path C<filesync-server> was actually installed to, which
C<ssh srv 'command -v filesync-server'> shows: a non-interactive ssh command
can see a shorter PATH than an interactive login shell.

=head2 On each client

Register the directory and name the wrapper as the server program:

	# on the client, once
	filesync init --repo documents --root /home/foo/Documents \
		--server foo@srv \
		--server-command /home/foo/bin/filesync-server-home
	filesync sync --repo documents --dry-run
	filesync sync --repo documents

Nothing needs naming: the client reports its host name, which is the id
C<client allow> lists and the name the server keeps this client's base, its
journal entries and its conflict copies under.  Pass C<--id> only when the
host name is not the name you want, and allow that name on the server
instead.  An id is not a login - the ssh key and the account do the
authenticating - and it does not divide the repo: every client of a repo
syncs the whole tree.

ssh runs with C<BatchMode=yes>, so the client's key must already be in the
server account's F<authorized_keys>, or loaded in C<ssh-agent>: cron cannot
answer a password prompt.

=head2 From cron

	# crontab -e, on each client
	* * * * * ionice -c3 /usr/local/bin/filesync sync --repo documents --quiet >/dev/null

The summary line is dropped so cron does not mail on every successful run;
diagnostics still go to standard error, so a failure is mailed.  Every attempt,
successful or not, is also appended to F<~/.filesync/logs/documents.jsonl>, and
C<filesync log --repo documents --exit 1> lists the ones that failed.

=head2 On Windows

Windows clients use a scheduled task rather than cron.  With the script in
F<C:\filesync> and Strawberry Perl installed, the same job is set up from a
command prompt:

	REM on the client, once
	C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync init ^
	  --repo documents --root C:\Users\foo\Documents --server foo@srv ^
	  --server-command /home/foo/bin/filesync-server-home

	REM then create the task; it runs every minute as the current user
	schtasks /Create /SC MINUTE /MO 1 /TN FileSync /F ^
	  /TR "C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync sync --repo documents --quiet"

The task runs only while that user is logged on, which suits a Documents
folder; its run log is still written under F<%USERPROFILE%\.filesync\logs>, so
C<filesync log --repo documents --warnings> works there too.

=head2 A root of /srv/filesync instead

To keep the master outside a home directory, create the default root once for
the account the clients log in to.  Then no C<--root> is needed on the server
commands, and no C<--server-command> on the client:

	# on the server, as an administrator
	sudo mkdir -p /srv/filesync
	sudo chown -R foo /srv/filesync

C<filesync-admin repo create documents> works as it is, and the master is
F</srv/filesync/master/documents>.

=head2 Backup and restore

The master directory is an ordinary directory tree, so it can be mirrored to a
backup directory from the server account's crontab.  Make the backup directory
once - rsync creates the last component only - then let cron keep it in step:

	# on the server, once
	mkdir -p /home/foo/backups/documents

	# crontab -e, on the server
	* * * * * ionice -c3 rsync -a --delete --exclude '.filesync-tmp-*' \
	    /home/foo/filesync/master/documents/ /home/foo/backups/documents/

Filesync writes each file to a temporary name and renames it into place, so the
mirror never catches a half-written upload; the exclusion keeps the temporary
files themselves out of the backup.  C<--delete> makes the copy a mirror: a
deletion that reaches the master also removes the backed-up file.

To restore the master from that backup, stop the client jobs (comment out their
cron lines, or disable the scheduled task) and the server's backup job, so the
backup job cannot copy a half-restored tree back into the backup.  Let any
running sync finish, then mirror the backup back:

	rsync -a --delete --checksum \
	    /home/foo/backups/documents/ /home/foo/filesync/master/documents/

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
	    /home/foo/backups/documents/ /home/foo/filesync/master/documents/

No output and exit 0 mean the master matches the backup.  Any line beginning
C<< >f >> names a path that still differs, and C<*deleting> names one the
rollback should have removed.  The index still describes the pre-rollback tree,
so C<filesync-admin verify> may report drift at this point; that is expected.
Rebuild it and check it:

	filesync-admin --root ~/filesync reindex documents
	filesync-admin --root ~/filesync verify documents --deep

C<reindex> hashes every file in the master and replaces the index atomically; it
refuses to run while a sync session holds the repo lock, and it names any paths
it could not index.  C<clean> and exit 0 from C<verify> confirm that the master
and its index agree.  Re-enable the jobs once that check passes.

To restore just one file or directory, copy that path back instead of mirroring
the whole tree, with the jobs paused as above so nothing changes the tree while
the copy runs:

	rsync -a --checksum /home/foo/backups/documents/notes/plan.txt \
	    /home/foo/filesync/master/documents/notes/
	rsync -a --checksum /home/foo/backups/documents/photos/ \
	    /home/foo/filesync/master/documents/photos/

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

=head1 LIMITATIONS

These are the design weaknesses a reviewer should weigh before relying on the
tool.  None of them loses data silently; most cost time or space.

=over 4

=item * B<One master.>  The topology is a star around one server.  The replica
is a pull-only mirror, not a failover: if the server is lost, clients stop
until an administrator points them at a rebuilt master.

=item * B<Every run exchanges the whole manifest.>  The client sends one entry
per file and the server answers with the whole plan as a single JSON line, so
a run costs O(files) in time, memory and bandwidth even when nothing changed.
A tree of a million files means a plan message of the order of a hundred
megabytes.  JSON goes through L<JSON::MaybeXS>, which installs and uses
L<Cpanel::JSON::XS> wherever there is a compiler: it decodes about 70 times
faster than the core L<JSON::PP> (0.2 seconds against 15 for a 100,000-file
manifest).  A pure-Perl install (C<PUREPERL_ONLY=1>) falls back to JSON::PP.  A change journal or Merkle summary would remove that, at the cost
of the "everything is inspectable with cat" property.

=item * B<No line-length cap on the wire.>  Because of the previous point, a
control message cannot be bounded without breaking large trees.  The peer is
authenticated by ssh and pinned by the forced command, so this is a resource
risk from a misbehaving client, not from the network.

=item * B<Lock-step protocol.>  One request is in flight at a time and each
256 KiB chunk waits for its acknowledgement, so throughput is bound by the
round-trip time on a high-latency link.

=item * B<Clock-dependent tie-breaks.>  When both sides changed a file, the
newer mtime wins (the master wins ties within 2 seconds).  A client with a
wrong clock picks the wrong winner; the loser is still kept as a conflict copy.

=item * B<No fsync.>  Renames are atomic between processes but not durable
across a power cut; see L<App::FileSync::IO/LIMITATIONS>.

=item * B<Pure-Perl deltas are bounded.>  Only the first 8 MiB after the
unchanged prefix are scanned for moved blocks; later changes go as literals.
See L<App::FileSync::Delta>.

=item * B<What is not synced.>  Symlinks, devices, sockets, extended attributes,
ACLs and ownership.  Permission bits are carried only between POSIX systems.

=item * B<Names.>  Unicode normalisation is not reconciled, so the same name
in NFC (Linux) and NFD (older macOS) is two different files.  A
case-insensitive client cannot hold two master paths that differ only in case.

=item * B<Encapsulation costs.>  Private methods use L<Sub::Private> in
C<enforce> mode, which costs about 1.4 microseconds per call (measured on
5.40).  Helpers that run per file or per JSON value (the merge comparisons,
the JSON byte downgrade, the rolling checksum) are therefore lexical code
references: private by scope, with no wrapper.  Both Sub::Private and
L<Sub::Protected> are bypassed while C<HARNESS_ACTIVE> is set.

=item * B<Log event names are English.>  Log lines carry a fixed event name
(C<sync finished>, C<session opened>) with structured fields, so that log
tools and tests can match them.  Those names are identifiers, not messages,
and are not translated; warnings and errors in the log go through the
message catalogue like everything else.

=item * B<Validation costs.>  L<Params::Validate::Strict> costs about 11
microseconds per call, so it guards the public entry points that run a few
times per command (constructors, admin and client operations).  Functions that
run per path or per protocol frame (L</validate_relpath>, the protocol
methods, the scanner) check their arguments by hand.

=item * B<Errors carry locations.>  Library errors are raised with C<croak> and
so end with C<at FILE line N.>; the commands strip that before printing, and
C<FILESYNC_TRACE=1> turns every error into a full stack trace instead.

=item * B<English only.>  The catalogue mechanism supports other languages,
plural forms and gender, but only the English catalogue ships.

=back

=head1 SEE ALSO

=over 4

=item * L<App::FileSync::I18N> - the message catalogue

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
