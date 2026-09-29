package App::Access2CSV::Exporter;

use strict;
use warnings;
use autodie qw(:all);

use Config;

# Sub::Private must be in enforce mode before it is loaded, so that
# private methods still work through $self->method dispatch
BEGIN { $Sub::Private::config{mode} = 'enforce' }

# Inherit i18n() and the protected _croak_i18n/_carp_i18n helpers
use parent 'App::Access2CSV::I18N';

use Encode qw(FB_CROAK find_encoding);
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use File::Which qw(which);
use IPC::Run3 qw(run3);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Return::Set qw(set_return);
use Scalar::Util qw(blessed);
use Sub::Private;
use Sub::Protected;

our $VERSION = '0.001.0';

# Stop Carp from reporting errors against the access-control wrappers
our @CARP_NOT = qw(Sub::Private Sub::Protected App::Access2CSV::I18N);

# Exit statuses returned by run()
Readonly::Scalar my $EXIT_OK      => 0;
Readonly::Scalar my $EXIT_FAILURE => 1;

# The mdbtools programs; mdb-count is only needed for --show-counts
Readonly::Scalar my $MDB_TABLES   => 'mdb-tables';
Readonly::Scalar my $MDB_EXPORT   => 'mdb-export';
Readonly::Scalar my $MDB_COUNT    => 'mdb-count';
Readonly::Array  my @REQUIRED_PROGRAMS => ($MDB_TABLES, $MDB_EXPORT);

# Output encodings accepted by --encoding
Readonly::Scalar my $ENC_UTF8     => 'utf8';
Readonly::Scalar my $ENC_UTF8_BOM => 'utf8-bom';
Readonly::Scalar my $ENC_CP1252   => 'cp1252';
Readonly::Array  my @ENCODINGS    => ($ENC_UTF8, $ENC_UTF8_BOM, $ENC_CP1252);

# Taint mode: a value is untainted only after it has been validated, by
# capturing it with this pattern (anything non-empty without a NUL byte:
# a NUL cannot be passed to the operating system at all)
Readonly::Scalar my $UNTAINT_RE => qr/\A([^\x00]+)\z/s;

# Environment variables that can change how a program is started (see
# perlsec); removed for the mdbtools processes
Readonly::Array my @UNSAFE_ENV => qw(IFS CDPATH ENV BASH_ENV);

# Encoding objects, looked up once: calling Encode::decode/encode by name
# repeats the lookup for every line, which made conversion about 4 times
# slower on large tables.  (Plain lexicals, not Readonly: Readonly's deep
# copy could interfere with the objects' internals.)
my $UTF8_CODEC   = find_encoding('UTF-8');
my $CP1252_CODEC = find_encoding('cp1252');

# Byte order mark written at the start of utf8-bom files (for Excel)
Readonly::Scalar my $UTF8_BOM     => "\xEF\xBB\xBF";

# Tables Access creates for itself: MSys*, USys* and ~temporary objects
Readonly::Scalar my $SYSTEM_TABLE_RE => qr/\A(?:MSys|USys|~)/i;

# Characters that are illegal in a file name on at least one common OS
Readonly::Scalar my $UNSAFE_CHARS_RE => qr/[<>:"\/\\|?*\x00-\x1F\x7F]/;

# Invisible text-direction controls (LRM, RLM, LRE, RLE, PDF, LRO, RLO,
# LRI, RLI, FSI, PDI).  They can make a file name display as something
# else ("report<RLO>vsc.exe.csv"), so they are unsafe like other control
# characters.  Matched both as Perl characters and as UTF-8 bytes, since
# table names from mdbtools arrive as bytes.
Readonly::Scalar my $BIDI_CONTROLS_RE => qr/
	  [\x{200E}\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}]   # as characters
	| \xE2 \x80 [\x8E\x8F\xAA-\xAE]                       # as UTF-8: marks, embeddings, overrides
	| \xE2 \x81 [\xA6-\xA9]                              # as UTF-8: isolates
/x;

# Device names Windows reserves whatever the extension (CON.csv is illegal)
Readonly::Scalar my $RESERVED_NAME_RE => qr/\A(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z/i;

# Name used when sanitising leaves nothing, and the extension we write
Readonly::Scalar my $UNNAMED      => 'unnamed';
Readonly::Scalar my $CSV_SUFFIX   => '.csv';

# Ends option parsing in mdbtools, so a table or database name that
# starts with "-" is never taken for an option (glib parses options
# anywhere on the command line, not only before the file name)
Readonly::Scalar my $END_OF_OPTIONS => '--';

# Temporary files are hidden and live next to the target for atomic rename
Readonly::Scalar my $TEMP_TEMPLATE => '.access2csv-XXXXXX';

# How much of an unreadable mdb-count answer to quote in the warning
Readonly::Scalar my $COUNT_SHOWN => 40;

# Shown in the dry run's ROWS column when a table could not be counted
Readonly::Scalar my $UNKNOWN_COUNT => '?';

# Dry-run table layout
Readonly::Scalar my $TABLE_COLUMN_WIDTH => 40;
Readonly::Scalar my $ROWS_COLUMN_WIDTH  => 10;
Readonly::Scalar my $RULE_WIDTH         => 70;

# Return schema of run(), shared by its two exits
Readonly::Hash my %RUN_STATUS_SCHEMA => (type => 'integer', min => $EXIT_OK, max => $EXIT_FAILURE);

# Mode bits for new files before the umask is applied
Readonly::Scalar my $FILE_MODE    => oct('666');

# Default settings; the flat scalar layout is compatible with Object::Configure
Readonly::Hash my %DEFAULTS => (
	output_dir  => File::Spec->curdir(),
	overwrite   => 0,
	verbose     => 0,
	dry_run     => 0,
	show_counts => 0,
	progress    => 1,
	encoding    => $ENC_UTF8,
);

# Constructor argument schema, shared by new() and the POD
Readonly::Hash my %NEW_SCHEMA => (
	output_dir  => { type => 'string', min => 1, optional => 1 },
	tables      => { type => 'arrayref', element_type => 'string', optional => 1 },
	overwrite   => { type => 'boolean', optional => 1 },
	verbose     => { type => 'boolean', optional => 1 },
	dry_run     => { type => 'boolean', optional => 1 },
	show_counts => { type => 'boolean', optional => 1 },
	progress    => { type => 'boolean', optional => 1 },
	encoding    => { type => 'string', memberof => [@ENCODINGS], optional => 1 },
	logger      => { type => 'object', can => ['debug', 'info', 'warn'], optional => 1 },
	language    => { type => 'string', optional => 1 },
);

=encoding utf8

=head1 NAME

App::Access2CSV::Exporter - Export the tables of a Microsoft Access database to CSV files

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

	use App::Access2CSV::Exporter;

	# 1. The simplest case: every table, into the current folder
	my $exporter = App::Access2CSV::Exporter->new();
	my $status = $exporter->run('shop.accdb');	# 0 = all OK, 1 = some failed

	# 2. Some tables, into a folder, for Excel, replacing old files
	my $exporter = App::Access2CSV::Exporter->new(
		output_dir => 'exports',
		tables     => ['Customers', 'Orders'],
		encoding   => 'utf8-bom',
		overwrite  => 1,
	);
	$exporter->run('shop.accdb');

	# 3. Only look: print the table list and row counts, write nothing
	App::Access2CSV::Exporter->new(dry_run => 1, show_counts => 1)->run('shop.accdb');

	# 4. Inside a larger program: no progress lines, a log, and full
	#    error handling
	use Log::Abstraction;

	my $exporter = App::Access2CSV::Exporter->new({
		output_dir => '/srv/exports',
		progress   => 0,
		logger     => Log::Abstraction->new(logger => '/var/log/export.log'),
	});
	my $status = eval { $exporter->run('/data/shop.accdb') };
	if(!defined $status) {
		die "Nothing was exported: $@";	# for example, the file is missing
	} elsif($status == 1) {
		warn "Some tables were not exported; see the log\n";
	}

=head1 DESCRIPTION

This module does the real work of the C<access2csv> program.  It writes
one CSV file for each table of a Microsoft Access database.

It runs three programs from the B<mdbtools> package: C<mdb-tables> (to
list the tables), C<mdb-export> (to get each table as CSV) and, only when
row counts are wanted, C<mdb-count>.  They must be in your C<PATH>.

Access's own internal tables (names starting with C<MSys>, C<USys> or
C<~>) are skipped.

Each file is first written to a hidden temporary file in the output
folder, and renamed to its real name only when it is complete.  So a
failed export never leaves a half-written CSV file, and an old file is
only replaced by a complete new one.  New files get the usual
permissions (0666 minus your umask).

An exporter can be used for more than one C<run>.  Each C<run> starts
again with the same file names, so running twice gives the same files.

The mdbtools programs are looked up only in absolute C<PATH> folders, so
a program planted in the current folder is never run, and they are
started with a cleaned environment (see L<App::Access2CSV/SECURITY>).
The module works under taint mode (C<perl -T>).  Table names are
printed and logged with control characters escaped, so a hostile name
cannot send escape sequences to your terminal.

Table names and the database path are handed to mdbtools as separate
arguments, never through a shell, and after a C<--> marker.  So names
containing shell characters (C<; | E<gt> $( )>), spaces or newlines, or
starting with C<->, are always treated as names, never as commands or
options.  A table name can never place a file outside the output
folder: C</> and C<\> are replaced, and names cannot start with a dot.

An existing entry at the target name - including a symbolic link, even a
broken one - counts as "already exists".  With C<overwrite>, the link
itself is replaced; the file it pointed to is never written.

The rules for file names are described in
L<App::Access2CSV/How the CSV files are named>.

=head1 ENCODING

=over 4

=item * B<CSV data.>  mdbtools gives UTF-8.  With C<encoding> set to
C<utf8> or C<utf8-bom> the bytes are copied exactly, so every character,
including emoji and non-Latin scripts, is kept.  C<utf8-bom> also writes
the three-byte UTF-8 "byte order mark" first, which Microsoft Excel
needs.  With C<cp1252>, each line is converted to Windows-1252; if a line
has a character that Windows-1252 does not have (for example Greek,
Chinese or an emoji), that table fails and nothing is written for it.

=item * B<Database path and output_dir.>  These are passed to the operating
system unchanged.  Give them as byte strings (the form you get from
C<@ARGV> or C<readdir>).  Non-ASCII names work on systems whose file names
are UTF-8, such as Linux and macOS.

=item * B<Table names> (in C<tables>).  They are compared with the names
that C<mdb-tables> prints, which are UTF-8 bytes.  So give UTF-8 byte
strings, not decoded Perl character strings.  If you have a decoded
string, use C<Encode::encode('UTF-8', $name)> first.  The CSV file name is
made from the same bytes, so non-ASCII names and emoji are kept.

=item * B<Messages.>  All messages are plain ASCII English.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<undef means "use the default", not "false".>  In C<new>,
C<< overwrite => undef >> is the same as not giving C<overwrite> at all.
To switch something off, give C<0>.

=item * B<An empty table list exports nothing.>  C<< tables => undef >>
(or no C<tables>) means "all tables".  C<< tables => [] >> means "no
tables": nothing is exported, and C<run> returns 0.

=item * B<Table names are case-sensitive.>  C<'orders'> does not match the
table C<Orders>.  Names that do not match any table give a warning.

=item * B<A failing logger does not stop the export.>  If the logger dies
(for example, its disk is full), C<run> warns once with "Cannot write to
the log", stops logging for this exporter, and carries on exporting.

=item * B<run can croak.>  C<run> returns 1 when some tables fail, but it
croaks (throws an exception) when nothing can be exported at all: the
database is missing or unreadable, mdbtools is not installed, or the
output folder cannot be created.  Wrap C<run> in C<eval> if your program
must keep going.

=item * B<run may change the show_counts setting.>  If C<show_counts> is
on but C<mdb-count> cannot be found, C<run> warns and switches
C<show_counts> off for this exporter.

=item * B<Settings are copied, not shared.>  C<new> makes its own copy of
the C<tables> list; changing your array later has no effect.  Settings are
not merged in depth: a new C<tables> list replaces the default completely.

=item * B<Warnings go through carp.>  Failed tables and unknown table names
are reported with C<carp>, so they appear on standard error (or in your
C<$SIG{__WARN__}> handler) even when a logger is given.

=item * B<Load the module with use, not require.>  Protection of the
private methods is set up at compile time.  After a run-time
C<require> Perl prints "Too late to run CHECK block" and the protection is
missing.

=back

=head1 METHODS

=head2 new

=head3 Purpose

Make a new exporter with your settings.  Nothing is checked on disk yet.

=head3 Arguments

Named arguments, either as a list or as one hash reference.  All of them
are optional.  An argument whose value is C<undef> is ignored, so its
default is used.

=over 4

=item C<output_dir> - the folder for the CSV files.  Default: the current folder.

=item C<tables> - an array reference of table names to export.  Default:
all tables.  An empty array means no tables.

=item C<overwrite> - true to replace CSV files that already exist.  Default: false.

=item C<verbose> - true to log extra detail.  Default: false.

=item C<dry_run> - true to only print what would be written.  Default: false.

=item C<show_counts> - true to report row counts (needs C<mdb-count>).  Default: false.

=item C<progress> - true to print C<[n/total] table> lines to standard
error.  Default: true.

=item C<encoding> - C<utf8>, C<utf8-bom> or C<cp1252>.  Default: C<utf8>.

=item C<logger> - an object with C<debug>, C<info> and C<warn> methods,
such as a L<Log::Abstraction> object.  Default: no logging.

=item C<language> - a language code such as C<en> for messages.  Default:
taken from the locale (see L<App::Access2CSV::I18N>).

=back

=head3 Returns

A new C<App::Access2CSV::Exporter> object.

=head3 Side Effects

None.  Your C<$@>, C<$!> and C<$_> are left as they were.

=head3 Usage

	my $exporter = App::Access2CSV::Exporter->new({ dry_run => 1 });

=head3 EXAMPLE

	# Export two tables as Windows-1252, replacing older files, with a log
	my $exporter = App::Access2CSV::Exporter->new(
		output_dir => 'out',
		tables     => ['Customers', 'Orders'],
		encoding   => 'cp1252',
		overwrite  => 1,
		logger     => Log::Abstraction->new(logger => 'export.log'),
	);

=head3 API SPECIFICATION

=head4 Input

	{
		output_dir  => { type => 'string', min => 1, optional => 1 },
		tables      => { type => 'arrayref', element_type => 'string', optional => 1 },
		overwrite   => { type => 'boolean', optional => 1 },
		verbose     => { type => 'boolean', optional => 1 },
		dry_run     => { type => 'boolean', optional => 1 },
		show_counts => { type => 'boolean', optional => 1 },
		progress    => { type => 'boolean', optional => 1 },
		encoding    => { type => 'string', memberof => ['utf8', 'utf8-bom', 'cp1252'], optional => 1 },
		logger      => { type => 'object', can => ['debug', 'info', 'warn'], optional => 1 },
		language    => { type => 'string', optional => 1 },
	}

Valid and invalid values (tested in F<t/domain.t>):

	output_dir  valid:   any path of 1 character or more ("0" is valid),
	                     including non-ASCII names given as UTF-8 bytes
	            invalid: "" (below the minimum), references
	tables      valid:   undef (all tables), [] (no tables), one name,
	                     many names; names are matched byte for byte
	            invalid: anything but an array reference; elements
	                     that are references
	booleans    valid:   exactly 1 true TRUE yes on  /  0 false FALSE no off
	(overwrite, invalid: everything else, e.g. "", 2, -1, "True", "Yes",
	 verbose,            "0.0", " 1"
	 dry_run, show_counts, progress)
	encoding    valid:   exactly utf8, utf8-bom, cp1252
	            invalid: other spellings (UTF8, utf-8, CP1252, " utf8")
	logger      valid:   an object with debug, info and warn methods
	            invalid: an object missing any of them, a plain hash,
	                     a string
	language    valid:   any string; "" means "use the environment"
	            invalid: references

=head4 Output

	{
		type => 'object',
		isa  => 'App::Access2CSV::Exporter',
	}

=head3 MESSAGES

All are fatal, and read "Invalid setting: REASON".  The REASON part
comes from L<Params::Validate::Strict> and is not translated; for example:

	+--------------------------------------+------------------------------+-----------------------------+
	| Message                              | Meaning                      | What to do                  |
	+--------------------------------------+------------------------------+-----------------------------+
	| Invalid setting: Unknown parameter   | X is not a known setting     | Remove X, or fix its        |
	|  'X'                                 |                              | spelling                    |
	| Invalid setting: Parameter           | This encoding is not         | Use utf8, utf8-bom or       |
	|  'encoding' (X) must be one of utf8, | supported                    | cp1252                      |
	|  utf8-bom, cp1252                    |                              |                             |
	| Invalid setting: Parameter 'logger'  | logger is not an object      | Give a logger object        |
	|  must be an object                   |                              |                             |
	| Invalid setting: Parameter 'tables'  | tables is not an array       | Give an array reference     |
	|  must be ...                         | reference                    |                             |
	+--------------------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	# Validation uses eval internally; the caller's $@ must survive
	local $@;

	# Drop undefined values so that "not given" means "use the default"
	my $args = get_params(undef, \@_) || {};
	my %given = map { $_ => $args->{$_} } grep { defined $args->{$_} } keys %{$args};

	# A bad setting is reported in plain words ("Invalid setting: ..."),
	# not with Params::Validate::Strict's internal prefix and location
	my $params = eval { validate_strict(schema => { %NEW_SCHEMA }, input => \%given) }
		or $class->_croak_i18n('invalid_setting', { params => [_validation_reason($@)] });

	# Copy the table list so later changes by the caller cannot affect us
	$params->{tables} = [ @{ $params->{tables} } ] if $params->{tables};

	# The output folder is the invoking user's own choice; it is only used
	# as a folder name, so it is untainted here (see _untaint)
	$params->{output_dir} = _untaint($params->{output_dir}) if defined $params->{output_dir};

	my $self = bless { %DEFAULTS, %{$params}, used_names => {}, next_suffix => {}, programs => {} }, $class;
	return set_return($self, { type => 'object' });
}

=head2 run

=head3 Purpose

Export the selected tables of one database to CSV files.  In dry-run mode,
only print what would be exported.

=head3 Arguments

=over 4

=item C<database> (string, required) - the path of the C<.mdb> or C<.accdb> file.
The name is taken literally: C<-> is a file called C<->.  (Reading from
standard input is a feature of the command-line program; see
L<App::Access2CSV/Reading the database from standard input>.)

=back

You can give it on its own, C<< $exporter->run('shop.accdb') >>, or as a
hash reference, C<< $exporter->run({ database => 'shop.accdb' }) >>.

=head3 Returns

C<0> if every selected table was exported, or in dry-run mode.
C<1> if at least one table was not exported (the others were).

=head3 Side Effects

=over 4

=item * Creates the output folder if needed (not in dry-run mode, and
not when no table is selected).

=item * Writes one CSV file per table (not in dry-run mode).

=item * Prints progress lines to standard error, if C<progress> is on.

=item * Prints the dry-run list to standard output, in dry-run mode.

=item * Sends messages to the logger, if there is one.

=item * Warns (with C<carp>) about each table that failed, about unknown
names in C<tables>, and about a missing C<mdb-count>.

=item * Croaks, before writing anything, if the database cannot be read, a
needed mdbtools program is missing, C<mdb-tables> fails, or the output
folder cannot be created.

=item * Switches C<show_counts> off for this exporter if C<mdb-count> is
missing.

=item * While it runs, handles the signals INT, QUIT, TERM and HUP (only
those you have not set a handler for yourself; they are restored when
C<run> returns).  Any of them stops the run: the table being exported is
discarded - its temporary file deleted, any old CSV file left as it was -
no further table is started, and C<run> croaks.  Pressing Ctrl-C, which
also stops the mdbtools program, has the same effect.

=item * Leaves your C<$@>, C<$!>, C<$?>, C<$_>, C<$.> and any pending C<alarm>
as they were (except that a croak sets C<$@> in your C<eval>, as usual).

=back

=head3 Usage

	exit $exporter->run('shop.accdb');

=head3 EXAMPLE

	my $exporter = App::Access2CSV::Exporter->new(output_dir => 'out');

	# eval catches the fatal errors; the return value covers the rest
	my $status = eval { $exporter->run('shop.accdb') };
	if(!defined $status) {
		print STDERR "Nothing was exported: $@";
	} elsif($status) {
		print STDERR "Some tables failed; see the warnings above\n";
	} else {
		print "Done\n";
	}

=head3 API SPECIFICATION

=head4 Input

	{
		database => {
			type     => 'string',
			min      => 1,
			optional => 0,
		},
	}

Valid and invalid values (tested in F<t/domain.t>):

	database    valid:   a readable regular file
	            invalid: "" (below the 1-character minimum), undef,
	                     a missing file, a folder, a device or FIFO,
	                     an unreadable file
	            edges:   each part of the path may be up to 255 bytes;
	                     256 gives "File name too long"

The table names that mdbtools reports are data, not arguments, but they
have limits of their own:

	length      a CSV file name is the table name plus ".csv", and the
	            file system limits file names, so table names up to 251
	            units work and longer ones fail (that table only).  The
	            unit depends on the file system: Linux counts bytes (125
	            u-umlauts, 2 bytes each, fit; 126 do not), macOS counts
	            characters (up to 251 of any letter fit).  Access allows
	            at most 64 characters, well within either limit.
	characters  non-ASCII letters, emoji, joined emoji, combining marks
	            and right-to-left text are kept byte for byte.
	            Characters that are unsafe in file names - including
	            invisible text-direction controls such as U+202E - are
	            replaced by "_".
	collisions  the first name has no suffix, then _2, _3, ... _10 ...
	cp1252      U+00FF and the Euro sign convert; U+0100 and above
	            (except the few Windows-1252 symbols), the C1 controls
	            U+0080-U+009F and emoji make the table fail.

=head4 Output

	{
		type => 'integer',
		min  => 0,
		max  => 1,
	}

=head3 MESSAGES

"fatal" means C<run> croaks and nothing is exported.  "per table" means
only that table fails; C<run> warns, logs, and carries on.

	+-----------------------------------------+------------------------------+-------------------------------+
	| Message                                 | Meaning                      | What to do                    |
	+-----------------------------------------+------------------------------+-------------------------------+
	| Interrupted by SIGx: stopped, and the   | Ctrl-C, Ctrl-\\, kill or a   | Run again; tables finished    |
	|  table being exported was discarded     | closed terminal stopped the  | before the interruption are   |
	|  (fatal)                                | run                          | complete                      |
	| run() must be called on an object       | run was called on the class  | Call new() first, then run()  |
	|  created by new() (fatal)               | or on something that is not  | on the object it returns      |
	|                                         | an exporter                  |                               |
	| Cannot read database F: E (fatal)       | F does not exist, or cannot  | Check the path                |
	|                                         | be reached; E is the reason  |                               |
	|                                         | from the operating system    |                               |
	| Database F is not a regular file (fatal)| F is a folder or a device    | Give the database file        |
	| Database F is not readable (fatal)      | No permission to read F      | Fix the permissions           |
	|                                         | (never happens for root)     |                               |
	| Required program not found in PATH: P   | mdbtools is not installed,   | Install mdbtools, or fix PATH |
	|  (fatal)                                | or not in PATH               |                               |
	| mdb-tables failed with exit status N: E | mdbtools cannot read the     | Check that F is a real Access |
	|  (fatal)                                | file                         | database                      |
	| Cannot create output directory D: E     | The folder cannot be made;   | Check permissions and path    |
	|  (fatal)                                | E is the reason for D itself |                               |
	|                                         | (e.g. "Not a directory" when |                               |
	|                                         | a file is in the way)        |                               |
	| Cannot count the rows of T: E (warning) | mdb-count failed for table T | The table is still exported   |
	|                                         | (only with show_counts)      | (dry run: count shown as "?") |
	|  ... mdb-count printed no number: "X"   | mdb-count's answer was not   | As above; X shows what it     |
	|                                         | just a number                | printed                       |
	| Tables not found in database: T         | Names in tables are not in   | Check spelling and case       |
	|  (warning)                              | the database                 |                               |
	| mdb-count not found in PATH; row counts | show_counts is on, but       | Install mdb-count, or turn    |
	|  are unavailable (warning)              | mdb-count is missing         | show_counts off               |
	| FAILED: T: E (warning, logged)          | Table T was not exported,    | See E, one of the messages    |
	|                                         | because of E                 | below                         |
	| Output file already exists: F (use      | F exists (a symbolic link,   | Set overwrite, or use another |
	|  --overwrite to replace it) (per table) | even a broken one, counts)   | output_dir                    |
	|                                         | and overwrite is off         |                               |
	| mdb-export failed with exit status N: E | mdbtools could not read this | Check the table in Access     |
	|  (per table)                            | table                        |                               |
	| P was killed by signal N (per table,    | The program was stopped from | Check memory and system       |
	|  or fatal for mdb-tables)               | outside                      | limits                        |
	| P could not be run: E (per table, or    | The program was found but    | Check its permissions and     |
	|  fatal for mdb-tables)                  | could not be started         | that it is a real program     |
	| Table T, line N: cannot be represented  | A character is not in        | Use utf8 or utf8-bom          |
	|  in cp1252 (per table)                  | Windows-1252                 |                               |
	| Table T, line N: output of mdb-export   | mdbtools gave bytes that are | Check the MDB_ICONV setting   |
	|  is not valid UTF-8 (per table)         | not UTF-8                    |                               |
	| Cannot write F: E (per table)           | The file could not be        | Check permissions and free    |
	|                                         | written or renamed into place| disk space                    |
	| Cannot write to the log: E (warning,    | The logger failed.  Exports  | Check the log's disk or       |
	|  once)                                  | go on; logging stops         | destination                   |
	+-----------------------------------------+------------------------------+-------------------------------+

=head3 PSEUDOCODE

	check the argument
	stop (croak) unless the database is a readable file
	find mdb-tables and mdb-export (croak if missing),
	     and mdb-count if row counts are wanted (warn if missing)
	forget the file names given out by any earlier run
	tables := the sorted user tables, filtered by "tables"
	          (warn about names that are not found)
	if dry run:
		print the table -> file list (row count "?" with a warning
		      if a count fails)
		return 0
	if there are tables to export:
		create the output folder (croak if that fails)
	for each table:
		print "[n/total] table" if progress is on
		try to export the table
		if that failed: warn, log, and count the failure
		(a failed row count after the file is in place is only a
		 warning; the table still counts as exported)
	log the summary
	return 1 if any table failed, else 0

=cut

sub run {
	my $self = shift;

	# State machine guard: run() is only a transition out of READY, which
	# only new() can create.  Refuse anything else before doing any work.
	# (Reported through the class: $self may not even be an object.)
	blessed($self) && $self->isa(__PACKAGE__) or __PACKAGE__->_croak_i18n('needs_object');

	# File tests, evals and child processes below would otherwise leave
	# their marks in the caller's $@ and $!
	local ($@, $!);

	# An undef database is a missing one, not a file called "".  Work on a
	# copy: get_params hands back the caller's own hash when given one.
	# (Params::Get either dies or returns a hash reference - proved in
	# t/path.t - so no test of what it returned is needed.)
	my $input = { %{ get_params('database', \@_) } };
	delete $input->{database} unless defined $input->{database};
	my $params = validate_strict(
		schema => { database => { type => 'string', min => 1 } },
		input  => $input,
	);
	my $database = $params->{database};

	# Fail fast, before any output, on problems that affect every table
	$self->_check_database($database)
		->_verify_dependencies()
		->_reset_names();

	# Stopping part-way must behave like a failed transaction: the table
	# being exported is discarded (its temporary file deleted) and no
	# further table is started.  Perl's default action for these signals
	# is to exit at once, skipping the clean-up, so while run() is active
	# they raise an exception instead.  A handler the caller has set is
	# left alone; everything is restored when run() returns.
	local $self->{interrupted};
	my @ours = @{ $self->_interrupt_signals() };
	local @SIG{@ours} = (sub {
		$self->{interrupted} = $_[0];
		die $self->_printable($self->i18n('interrupted', { params => [$_[0]] })), "\n";
	}) x @ours;

	# Premise: the database is now known to be a readable regular file, and
	# it is only ever passed to mdbtools as one list argument after "--".
	# Conclusion: it is safe to untaint.
	$database = _untaint($database);

	my $tables = $self->_select_tables($self->_get_tables($database));

	# Guard clause: a dry run must not touch the file system, so it leaves
	# before mkdir.  Premise: _dry_run writes nothing that can fail a table.
	# Conclusion: a dry run always succeeds.
	if($self->{dry_run}) {
		$self->_dry_run($database, $tables);
		return set_return($EXIT_OK, { %RUN_STATUS_SCHEMA });
	}

	# The output folder is only made when there is something to put in it;
	# with no tables selected the run goes straight to the summary
	my $failed = (@{$tables} ? $self->_make_output_dir() : $self)->_export_all($database, $tables);
	return set_return($failed ? $EXIT_FAILURE : $EXIT_OK, { %RUN_STATUS_SCHEMA });
}

# _check_database
# Purpose:        Make sure the database is a readable regular file.
# Entry Criteria: $database is a defined, non-empty path.
# Exit Status:    Returns $self for chaining; croaks otherwise.
# Side Effects:   stat()s the file; sets $!.
sub _check_database :Private {
	my ($self, $database) = @_;

	# The stat result is reused via "_" so the file is only examined once;
	# $! is captured straight away because later calls may overwrite it
	if(!-e $database) {
		$self->_croak_i18n('database_not_found', { params => [$database, "$!"] });
	}
	$self->_croak_i18n('database_not_file', { params => [$database] }) unless -f _;
	$self->_croak_i18n('database_unreadable', { params => [$database] }) unless -r _;

	return $self;
}

# _verify_dependencies
# Purpose:        Locate the mdbtools programs in PATH.
# Entry Criteria: None.
# Exit Status:    Returns $self; croaks if a required program is missing.
# Side Effects:   Sets $self->{programs}; may switch off show_counts (with a
#                 warning) when mdb-count is unavailable; logs at debug level.
sub _verify_dependencies :Private {
	my $self = shift;

	my %programs;
	foreach my $program (@REQUIRED_PROGRAMS) {
		$programs{$program} = $self->_find_program($program)
			or $self->_croak_i18n('program_missing', { params => [$program] });
	}

	# mdb-count is only needed for row counts, so its absence is not fatal.
	# _find_program returns a path or false, so one branch decides both
	# "store it" and "switch counts off" (nothing is stored and removed).
	if($self->{show_counts}) {
		if(my $path = $self->_find_program($MDB_COUNT)) {
			$programs{$MDB_COUNT} = $path;
		} else {
			$self->{show_counts} = 0;
			$self->_warn('no_row_counter');
		}
	}

	$self->{programs} = \%programs;
	return $self;
}

# _find_program
# Purpose:        Look up one program in PATH and note where it was found.
# Entry Criteria: $program is a bare program name.
# Exit Status:    Returns the full path, or undef if not found.
# Side Effects:   Logs the location at debug level when --verbose is on.
sub _find_program :Private {
	my ($self, $program) = @_;

	# Only absolute paths are trusted.  A relative entry in PATH (".", or
	# an empty one) would run whatever file of that name is in the current
	# folder - a classic way to plant a program.
	my ($path) = grep { defined && File::Spec->file_name_is_absolute($_) } which($program);

	# An absolute path to an existing program: safe to untaint
	$path = _untaint($path) if defined $path;
	if($path && $self->{verbose}) {
		$self->_log(debug => 'program_found', { params => [$program, $path] });
	}
	return $path;
}

# _reset_names
# Purpose:        Forget file names allocated by a previous run() so that
#                 running the same exporter twice gives the same names.
# Entry Criteria: None.
# Exit Status:    Returns $self.
# Side Effects:   Empties $self->{used_names}.
sub _reset_names :Private {
	my $self = shift;

	$self->{used_names} = {};
	$self->{next_suffix} = {};
	return $self;
}

# _get_tables
# Purpose:        List the user tables in the database.
# Entry Criteria: _verify_dependencies() has run.
# Exit Status:    Returns an arrayref of table names, sorted; croaks if
#                 mdb-tables fails.
# Side Effects:   Runs mdb-tables.
sub _get_tables :Protected {
	my ($self, $database) = @_;

	# -1 puts one table per line, so names containing spaces survive;
	# "--" stops a database path starting with "-" being read as an option
	my $stdout = '';
	$self->_run_program($MDB_TABLES, ['-1', $END_OF_OPTIONS, $database], \$stdout);

	# \r? copes with mdbtools builds that emit CRLF line endings; a program
	# that printed nothing may leave $stdout undefined
	# Table names are untainted: they are only used as one list argument
	# after "--", and in file names only after _csv_filename has made them
	# safe
	my @tables = sort map { _untaint($_) } grep { length($_) && !$self->_is_system_table($_) } split /\r?\n/, $stdout // '';
	return \@tables;
}

# _is_system_table
# Purpose:        Decide whether a table is Access's own rather than the user's.
# Entry Criteria: $table is a table name.
# Exit Status:    Returns 1 for system tables, 0 otherwise.
# Side Effects:   None.  Protected so that subclasses can widen the filter.
sub _is_system_table :Protected {
	my ($self, $table) = @_;

	return ($table =~ $SYSTEM_TABLE_RE) ? 1 : 0;
}

# _select_tables
# Purpose:        Apply the --table filter to the list of tables.
# Entry Criteria: $tables is the arrayref from _get_tables().
# Exit Status:    Returns an arrayref, in database (sorted) order.
# Side Effects:   Warns and logs about requested tables that do not exist.
sub _select_tables :Private {
	my ($self, $tables) = @_;

	return $tables unless $self->{tables};

	# Matching is exact, as mdb-export itself is case-sensitive
	my %available = map { $_ => 1 } @{$tables};
	my %wanted    = map { $_ => 1 } @{ $self->{tables} };

	my @missing = sort grep { !$available{$_} } keys %wanted;
	if(@missing) {
		$self->_warn('unknown_tables', { params => [join(', ', @missing)], count => scalar(@missing) });
	}

	return [ grep { $wanted{$_} } @{$tables} ];
}

# _make_output_dir
# Purpose:        Create the output directory (and parents) if necessary.
# Entry Criteria: Not in dry-run mode.
# Exit Status:    Returns $self; croaks if the directory cannot be created.
# Side Effects:   Creates directories.
sub _make_output_dir :Private {
	my $self = shift;

	my $dir = $self->{output_dir};
	return $self if -d $dir;

	# Ask File::Path to report errors rather than carp/croak on its own,
	# so the message can be translated and names the directory we wanted
	make_path($dir, { error => \my $errors });
	if(@{$errors} || !-d $dir) {
		# File::Path may also report a parent (e.g. "File exists" for a
		# plain file in the way); the reason for $dir itself, or failing
		# that the last one, is what explains the failure
		my ($mine) = grep { exists $_->{$dir} } @{$errors};
		my $detail = $mine ? $mine->{$dir} : (@{$errors} ? (values %{ $errors->[-1] })[0] : undef);
		$self->_croak_i18n('mkdir_failed', { params => [$dir, $detail || "$!"] });
	}
	return $self;
}

# _export_all
# Purpose:        Export each table, carrying on past individual failures.
# Entry Criteria: The output directory exists.
# Exit Status:    Returns the number of tables that failed.
# Side Effects:   Writes CSV files; prints progress; warns; logs.
sub _export_all :Private {
	my ($self, $database, $tables) = @_;

	my $total  = scalar @{$tables};
	my $failed = 0;

	# eval below would otherwise overwrite the caller's $@
	local $@;

	# An index loop, not each(), which shares the array's iterator with the
	# caller and would silently skip tables if it was already part-way
	foreach my $index (0 .. $#{$tables}) {
		my $table = $tables->[$index];
		# Progress goes to STDERR so that STDOUT can be redirected cleanly
		if($self->{progress}) {
			print STDERR $self->_printable($self->i18n('progress', { params => [$index + 1, $total, $table] })), "\n";
		}

		# One bad table should not stop the rest from being exported
		next if eval { $self->_export_table($database, $table); 1 };

		# ... but an interruption stops them all: the failed table has been
		# discarded (its temporary file went with the exception), and no
		# further table is started
		$self->_croak_i18n('interrupted', { params => [$self->{interrupted}] }) if $self->{interrupted};

		my $error = $@ || 'Unknown error';
		chomp $error;
		++$failed;
		$self->_warn('export_failed', { params => [$table, $error] });
	}

	$self->_log(info => 'summary', { params => [$total, $failed], count => $total });
	return $failed;
}

# _export_table
# Purpose:        Export one table to its CSV file.
# Entry Criteria: _verify_dependencies() and _make_output_dir() have run.
# Exit Status:    Returns $self; croaks on any failure, leaving no partial file.
# Side Effects:   Runs mdb-export (and mdb-count); creates or replaces a file.
sub _export_table :Protected {
	my ($self, $database, $table) = @_;

	my $outfile = File::Spec->catfile($self->{output_dir}, $self->_csv_filename($table));

	# Check before exporting so that we do not waste time on a big table
	# -l as well as -e: a dangling symlink is an existing entry too, and
	# must not be silently replaced.  The overwrite flag is tested first:
	# when it is set the answer is already known, so no file test is needed.
	if(!$self->{overwrite} && (-e $outfile || -l $outfile)) {
		$self->_croak_i18n('output_exists', { params => [$outfile] });
	}

	# Write into a temporary file next to the target; it is deleted
	# automatically if anything below croaks
	my $tmp = File::Temp->new(DIR => $self->{output_dir}, TEMPLATE => $TEMP_TEMPLATE, UNLINK => 1);
	binmode $tmp, ':raw';

	if($self->{encoding} eq $ENC_CP1252) {
		$self->_export_transcoded($database, $table, $tmp);
	} else {
		# The BOM must reach the file before mdb-export starts writing to
		# the same descriptor, hence the explicit flush
		print {$tmp} $UTF8_BOM if $self->{encoding} eq $ENC_UTF8_BOM;
		$tmp->flush() or $self->_croak_i18n('write_failed', { params => [$outfile, "$!"] });
		$self->_run_program($MDB_EXPORT, [$END_OF_OPTIONS, $database, $table], $tmp);
	}

	$self->_install_file($tmp, $outfile);

	# The file is now in place, so the table has been exported.  Row counts
	# are optional extras: if counting fails it is only a warning (see
	# _try_count_rows), and the export is logged without a count.
	my $rows = $self->{show_counts} ? $self->_try_count_rows($database, $table) : undef;
	if(defined $rows) {
		$self->_log(info => 'exported_rows', { params => [$table, $outfile, $rows], count => $rows });
	} else {
		$self->_log(info => 'exported', { params => [$table, $outfile] });
	}
	return $self;
}

# _export_transcoded
# Purpose:        Export a table and convert it from UTF-8 to Windows-1252.
# Entry Criteria: $out is an open, raw, writable filehandle.
# Exit Status:    Returns $self; croaks on invalid UTF-8 or on a character
#                 that has no cp1252 equivalent (rather than silently
#                 replacing it with '?').
# Side Effects:   Runs mdb-export into a second temporary file.
sub _export_transcoded :Private {
	my ($self, $database, $table, $out) = @_;

	# Reading the spool changes $. and the evals change $@; keep the
	# caller's values
	local $.;
	local $@;

	# Spool to disk rather than memory, so huge tables do not exhaust RAM
	my $spool = File::Temp->new(DIR => $self->{output_dir}, TEMPLATE => $TEMP_TEMPLATE, UNLINK => 1);
	binmode $spool, ':raw';
	$self->_run_program($MDB_EXPORT, [$END_OF_OPTIONS, $database, $table], $spool);
	seek $spool, 0, 0;

	# Convert line by line; $. gives the user a line number to look at
	while(my $line = <$spool>) {
		my $chars = eval { $UTF8_CODEC->decode($line, FB_CROAK) };
		$self->_croak_i18n('invalid_utf8', { params => [$table, $.] }) unless defined $chars;

		my $bytes = eval { $CP1252_CODEC->encode($chars, FB_CROAK) };
		$self->_croak_i18n('unmappable', { params => [$table, $., $ENC_CP1252] }) unless defined $bytes;

		print {$out} $bytes;
	}

	# Close the spool explicitly once it has been read.  (On a croak above,
	# File::Temp's destructor closes and deletes it.)
	close $spool;
	return $self;
}

# _install_file
# Purpose:        Move a finished temporary file to its final name.
# Entry Criteria: $tmp is a File::Temp holding the complete CSV.
# Exit Status:    Returns $self; croaks if the rename or chmod fails.
# Side Effects:   Replaces $outfile; the temporary file is no longer
#                 auto-deleted.
sub _install_file :Private {
	my ($self, $tmp, $outfile) = @_;

	# The eval must not overwrite the caller's $@
	local $@;

	# File::Temp creates files as 0600; give the CSV the permissions a
	# normal open() would have, i.e. 0666 less the umask
	my $ok = eval {
		close $tmp;
		chmod $FILE_MODE & ~umask(), $tmp->filename();
		rename $tmp->filename(), $outfile;
		1;
	};
	$self->_croak_i18n('write_failed', { params => [$outfile, _os_error($@)] }) unless $ok;

	$tmp->unlink_on_destroy(0);
	return $self;
}

# _count_rows
# Purpose:        Ask mdb-count how many rows a table has.
# Entry Criteria: $self->{programs}{'mdb-count'} is set.
# Exit Status:    Returns a non-negative integer; croaks if mdb-count fails.
# Side Effects:   Runs mdb-count.
sub _count_rows :Private {
	my ($self, $database, $table) = @_;

	my $stdout = '';
	$self->_run_program($MDB_COUNT, [$END_OF_OPTIONS, $database, $table], \$stdout);

	# mdb-count prints just the number (perhaps with spaces around it).
	# Anything else - nothing, "-5", an error text - is not a count, and
	# must not quietly become 0: it is reported (as a warning, by
	# _try_count_rows)
	my ($rows) = ($stdout // '') =~ /\A\s*(\d+)\s*\z/;
	defined($rows) or $self->_croak_i18n('count_unreadable', { params => [$self->_printable(substr($stdout // '', 0, $COUNT_SHOWN))] });
	return $rows;
}

# _try_count_rows
# Purpose:        Count a table's rows, where a failure is only a warning.
#                 Row counts are optional extras: they must never make an
#                 exported table count as failed, nor end a dry run.
# Entry Criteria: $self->{programs}{'mdb-count'} is set.
# Exit Status:    Returns the count, or undef if it could not be had.
# Side Effects:   Runs mdb-count; on failure warns and logs "Cannot count
#                 the rows of T: E".  An interruption is not a failure to
#                 count: it is passed on, to stop the run.
sub _try_count_rows :Private {
	my ($self, $database, $table) = @_;

	local $@;
	my $rows = eval { $self->_count_rows($database, $table) };
	return $rows if defined $rows;

	die $@ if $self->{interrupted};
	my $error = $@;
	chomp $error;
	$self->_warn('count_failed', { params => [$table, $error] });
	return;
}

# _run_program
# Purpose:        Run an mdbtools program and check that it succeeded.
#                 Shared by every call to mdbtools, so that failures are
#                 reported consistently.
# Entry Criteria: $name is a key of $self->{programs}; $args is an arrayref;
#                 $stdout is a scalar ref or a filehandle for run3().
# Exit Status:    Returns $self; croaks if the program exits non-zero or
#                 dies from a signal.
# Side Effects:   Runs a child process; writes to $stdout; sets $?.
sub _run_program :Private {
	my ($self, $name, $args, $stdout) = @_;

	# run3 sets $?, and reads captured output back from a temporary file,
	# which changes the handle $. refers to; keep the caller's values
	local ($?, $.);

	# Start the program in a clean environment (as perlsec asks, and as
	# taint mode requires): PATH keeps only absolute folders, and variables
	# that can change how a program is started are removed
	# (File::Spec->path and path_sep, not ":": Windows separates PATH with
	# ";" and its paths contain ":", as in C:\\)
	local $ENV{PATH} = join($Config{path_sep}, map { _untaint($_) } grep { length && File::Spec->file_name_is_absolute($_) } File::Spec->path());
	local @ENV{@UNSAFE_ENV};
	delete @ENV{@UNSAFE_ENV};

	# A list (not a string) is passed, so no shell ever sees the file or
	# table name and quoting cannot be abused
	my $stderr = '';
	run3([$self->{programs}{$name}, @{$args}], \undef, $stdout, \$stderr);

	# Distinguish "never started" (-1) and a signal from an ordinary
	# non-zero exit status; $! only means something in the first case
	my ($status, $reason) = ($?, "$!");
	chomp $stderr;
	if($status == -1) {
		$self->_croak_i18n('program_not_run', { params => [$name, $reason] });
	}
	if($status & 127) {
		# While system() waits, Perl ignores INT and QUIT in this process,
		# so Ctrl-C shows up only as the child dying of SIGINT.  Treat
		# that as the user stopping the whole run, not as a bad table.
		my $signal = (split ' ', $Config{sig_name})[$status & 127] // '';
		if($signal eq 'INT' || $signal eq 'QUIT') {
			$self->{interrupted} = $signal;
			$self->_croak_i18n('interrupted', { params => [$signal] });
		}
		$self->_croak_i18n('program_signalled', { params => [$name, $status & 127] });
	}
	if($status) {
		$self->_croak_i18n('program_failed', { params => [$name, $status >> 8, $stderr] });
	}
	return $self;
}

# _csv_filename
# Purpose:        Turn a table name into a safe, unique CSV file name.
# Entry Criteria: $table is a table name (possibly empty).
# Exit Status:    Returns a file name (no directory) ending in ".csv".
# Side Effects:   Records the name in $self->{used_names}.
#
# Names are compared case-insensitively, because Windows and macOS file
# systems are, so "Orders" and "ORDERS" do not overwrite each other.
# The loop (rather than a single suffix) guarantees uniqueness even when
# another table is literally called "Orders_2".
sub _csv_filename :Protected {
	my ($self, $table) = @_;

	my $name = $table // '';

	# Replace characters that are illegal somewhere, then strip leading
	# and trailing whitespace; Windows also silently drops trailing dots
	$name =~ s/$UNSAFE_CHARS_RE/_/g;
	$name =~ s/$BIDI_CONTROLS_RE/_/g;

	# C1 controls (U+0080-U+009F; U+009B acts like ESC [ on terminals).
	# In a byte string they must be matched as their UTF-8 form, because a
	# bare [\x80-\x9F] would also hit the continuation bytes of ordinary
	# characters such as the Euro sign (E2 82 AC)
	if(utf8::is_utf8($name)) {
		$name =~ s/[\x{80}-\x{9F}]/_/g;
	} else {
		$name =~ s/\xC2[\x80-\x9F]/_/g;
	}
	$name =~ s/\A\s+//;
	$name =~ s/[\s.]+\z//;

	# Avoid hidden files, Windows device names and empty names
	$name =~ s/\A\./_/;
	$name = "_$name" if $name =~ $RESERVED_NAME_RE;
	$name = $UNNAMED unless length $name;

	# Find the smallest free suffix (_2, _3, ...).  Start from where this
	# name's last search ended rather than from 2: every suffix below that
	# point was taken then and is still taken (names are never released
	# during a run), so the answer is the same, but N tables with the same
	# name cost O(N) in total instead of O(N squared).
	my $used = $self->{used_names};
	my $base = lc $name;
	my $file = $name . $CSV_SUFFIX;
	if(exists $used->{lc $file}) {
		my $n = $self->{next_suffix}{$base} // 2;
		$n++ while exists $used->{lc "${name}_$n$CSV_SUFFIX"};
		$file = "${name}_$n$CSV_SUFFIX";
		$self->{next_suffix}{$base} = $n + 1;
	}
	$used->{lc $file} = 1;

	return $file;
}

# _dry_run
# Purpose:        Print the table -> file mapping without writing anything.
# Entry Criteria: $tables is the arrayref of selected tables.
# Exit Status:    Returns $self.
# Side Effects:   Prints to STDOUT; runs mdb-count when show_counts is on.
sub _dry_run :Private {
	my ($self, $database, $tables) = @_;

	# Only show the ROWS column when counts are actually available
	my $counts = $self->{show_counts};
	my $format = $counts
		? "%-${TABLE_COLUMN_WIDTH}s %${ROWS_COLUMN_WIDTH}s  %s\n"
		: "%-${TABLE_COLUMN_WIDTH}s %s\n";
	my @header = map { $self->i18n($_) } ($counts ? qw(column_table column_rows column_output) : qw(column_table column_output));

	# Underline the title to the length of whatever the translation is
	my $title = $self->i18n('dry_run_title');
	print "\n$title\n", '=' x length($title), "\n\n";
	printf $format, @header;
	print '-' x $RULE_WIDTH, "\n";

	foreach my $table (@{$tables}) {
		my @row = ($table);
		# A count that cannot be had is shown as "?" (with a warning), so a
		# dry run still lists every table and succeeds
		push @row, $self->_try_count_rows($database, $table) // $UNKNOWN_COUNT if $counts;
		# The table name comes from the database, so show it escaped (the
		# file name is already safe; escaping it too costs nothing)
		$row[0] = $self->_printable($row[0]);
		printf $format, @row, $self->_printable($self->_csv_filename($table));
	}
	print "\n";

	return $self;
}

# _warn
# Purpose:        Warn the user and record the same text in the log.
# Entry Criteria: $key is a catalog key; $args an optional i18n() hashref.
# Exit Status:    Returns $self.
# Side Effects:   carp()s; logs at warn level.
sub _warn :Private {
	my ($self, $key, $args) = @_;

	$self->_carp_i18n($key, $args);
	return $self->_log(warn => $key, $args);
}

# _log
# Purpose:        Send a localised message to the logger, if there is one.
# Entry Criteria: $level is a logger method name (debug, info or warn).
# Exit Status:    Returns $self.
# Side Effects:   Calls $self->{logger}->$level().
sub _log :Private {
	my ($self, $level, $key, $args) = @_;

	my $logger = $self->{logger} or return $self;

	# Logging is secondary: a logger that dies (full disk, closed socket)
	# must not make a finished export look failed.  Say so once and stop
	# using it.
	local $@;
	# Escaped, so a hostile table name cannot forge log lines (CR, LF)
	# or send escape sequences to whoever views the log
	if(!eval { $logger->$level($self->_printable($self->i18n($key, $args))); 1 }) {
		my $error = $@;
		chomp $error;
		delete $self->{logger};
		$self->_carp_i18n('log_failed', { params => [$error] });
	}
	return $self;
}

# _validation_reason
# Purpose:        Reduce a Params::Validate::Strict error to its meaning,
#                 e.g. "Parameter 'encoding' (latin1) must be one of utf8,
#                 utf8-bom, cp1252", dropping the module's own prefix
#                 ("Params::Validate::Strict line N: validate_strict: ")
#                 and the Perl location it appends.
# Entry Criteria: $error is the exception from validate_strict.
# Exit Status:    Returns a one-line string.
# Side Effects:   None.  A plain function, not a method.
sub _validation_reason :Private {
	my $error = shift;

	my $reason = "$error";
	$reason =~ s/\AParams::Validate::Strict line \d+: //;
	$reason =~ s/\Avalidate_strict: //;
	$reason =~ s/ at \S+ line \d+\.?\n?\z//;
	chomp $reason;
	return $reason;
}

# _untaint
# Purpose:        Mark a value that has already been validated as safe for
#                 taint mode.
# Entry Criteria: $value has been checked by the caller (see each call).
# Exit Status:    Returns the untainted value; returns $value unchanged if
#                 it is empty or contains a NUL (it will then fail safely
#                 at the operating system, still tainted).
# Side Effects:   None.  A plain function, not a method.
sub _untaint :Private {
	my $value = shift;

	return ($value // '') =~ $UNTAINT_RE ? $1 : $value;
}

# _os_error
# Purpose:        Get a readable OS error from an autodie exception or string.
# Entry Criteria: $error is whatever eval left in $@.
# Exit Status:    Returns a string.
# Side Effects:   None.  A plain function, not a method.
sub _os_error :Private {
	my $error = shift;

	# autodie::exception keeps the original $! for us.  blessed(), not
	# ref(): asking an unblessed reference ->can() would die and hide
	# the real error.
	my $text = (blessed($error) && $error->can('errno')) ? $error->errno() : "$error";
	chomp $text;
	return $text;
}

1;

__END__

=head1 DESIGN NOTES

Some checks are done once, early, and deliberately not repeated later.
The reasoning, in plain words:

=over 4

=item * B<Settings are checked once.>  Premise 1: C<new> refuses any
setting outside its documented values.  Premise 2: settings cannot be
changed through the API afterwards.  Conclusion: the rest of the code can
trust them; for example, C<encoding> is always one of the three names,
so no "unknown encoding" branch is needed.

=item * B<Fail fast, in a fixed order.>  C<run> checks the database, then
finds the programs, then lists the tables, then makes the folder.
Premise 1: each step needs the one before it.  Premise 2: a failure in
one step is fatal.  Conclusion: when a step fails, nothing after it
runs - no program is looked up for a missing database, no program is run
when one is missing, and no folder is made when the table list fails.

=item * B<A dry run always succeeds.>  Premise 1: a dry run writes no
files.  Premise 2: only writing a file can fail a table.  Conclusion: a
dry run returns 0 without reaching the export loop.

=item * B<"Could not start" is tested before "killed by a signal".>
Premise 1: when a program cannot be started, the exit status C<$?> is -1.
Premise 2: the signal number is C<$? & 127>, and C<-1 & 127> is 127.
Conclusion: testing for a signal first would wrongly report signal 127.

=item * B<The overwrite setting is tested before the file.>  Premise 1: a
table is refused only if overwrite is off B<and> the name exists.
Premise 2: when overwrite is on, the answer is already "go ahead".
Conclusion: the file tests are skipped in that case.

=back

=head1 LIMITATIONS

=over 4

=item * mdbtools is expected to give UTF-8.  This is what it does when it is
built with iconv (the normal case).  If the C<MDB_ICONV> environment
variable selects another character set, C<cp1252> conversion reports
invalid UTF-8.

=item * C<cp1252> conversion stops at the first character that Windows-1252
does not have, and that table fails.  It never writes C<?> instead.  Line
numbers count lines in the file, so a text field that contains line
breaks covers several lines.

=item * Checking that a file already exists and renaming the new file into
place are two separate steps.  If another program creates the same file
between them, that file is replaced.

=item * File names are made safe for Windows, macOS and Unix, but are not
shortened.  Access table names are at most 64 characters, which is well
within normal limits.

=item * Row counts need one extra C<mdb-count> run for each table.

=item * When the program itself is sent SIGTERM or SIGHUP (not Ctrl-C),
the mdbtools program it was running is not stopped: it runs to the end,
writing only to the temporary file that has already been deleted.
L<IPC::Run3> does not say which process it started, so it cannot be
signalled.

=item * The private and protected methods are protected by L<Sub::Private>
and L<Sub::Protected> only when this module is loaded with C<use>.  When
C<$ENV{HARNESS_ACTIVE}> is set (under C<prove>), the checks are turned
off so that tests can call these methods.

=back

=head1 SEE ALSO

L<App::Access2CSV>, L<App::Access2CSV::I18N>, L<https://github.com/mdbtools/mdbtools>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=head1 FORMAL SPECIFICATION

These schemas use the Z notation.  C<?> marks an input, C<!> an output,
C<'> the state after the operation, "Delta" a changed state and "Xi" an
unchanged state.  You do not need to read this section to use the module.

	┌─ Exporter ─────────────────────────────────────────────────
	│ settings : SETTING ⇸ VALUE
	│ used_names : ℙ FILENAME
	│ next_suffix : NAME ⇸ ℕ
	│ programs : PROGRAM ⇸ PATH
	├────────────────────────────────────────────────────────────
	│ settings(encoding) ∈ {utf8, utf8-bom, cp1252}
	│ ∀ n₁, n₂ : used_names • lower(n₁) = lower(n₂) ⇒ n₁ = n₂
	│ ∀ b : dom next_suffix; k : ℕ | 2 ≤ k < next_suffix(b) •
	│     lower(b ⁀ "_" ⁀ k ⁀ ".csv") ∈ lower⦇used_names⦈
	└────────────────────────────────────────────────────────────

The last line is what makes the file-name search fast: every suffix
below the remembered starting point is already taken, so starting there
finds the same (smallest free) suffix as starting from 2.

=head2 csv_name

	┌─ CsvName ──────────────────────────────────────────────────
	│ ΔExporter
	│ table? : NAME ; file! : FILENAME
	├────────────────────────────────────────────────────────────
	│ b = safe(table?)
	│ file! = (if lower(b ⁀ ".csv") ∉ lower⦇used_names⦈ then b ⁀ ".csv"
	│          else b ⁀ "_" ⁀ min{ k : ℕ | k ≥ 2 ∧
	│                 lower(b ⁀ "_" ⁀ k ⁀ ".csv") ∉ lower⦇used_names⦈ } ⁀ ".csv")
	│ used_names' = used_names ∪ {file!}
	└────────────────────────────────────────────────────────────

=head2 new

	┌─ NewExporter ──────────────────────────────────────────────
	│ Exporter'
	│ args? : SETTING ⇸ VALUE
	├────────────────────────────────────────────────────────────
	│ dom args? ⊆ dom NEW_SCHEMA
	│ ∀ k : dom args? • valid(NEW_SCHEMA(k), args?(k))
	│ settings' = DEFAULTS ⊕ { k : dom args? | args?(k) ≠ undef • k ↦ args?(k) }
	│ used_names' = ∅
	│ next_suffix' = ∅
	│ programs' = ∅
	└────────────────────────────────────────────────────────────

=head2 run

	┌─ Run ──────────────────────────────────────────────────────
	│ ΔExporter ; ΔFileSystem
	│ database? : PATH ; status! : {0, 1}
	│ all, selected : iseq TABLE ; failed : ℙ TABLE
	├────────────────────────────────────────────────────────────
	│ database? ∈ readableFiles
	│ {mdb-tables, mdb-export} ⊆ dom PATH
	│ all = sort({ t : tablesOf(database?) | ¬ system(t) })
	│ selected = (if tables ∉ dom settings then all
	│             else all ↾ ran settings(tables))
	│ settings(dry_run) ⇒ files' = files ∧ status! = 0
	│ ¬ settings(dry_run) ⇒
	│   failed = { t : ran selected | ¬ exported(t) } ∧
	│   (∀ t : ran selected \ failed •
	│      files'(output_dir / csvName(t)) = encode(encoding, csv(t))) ∧
	│   (∀ t : failed • files'(output_dir / csvName(t)) = files(output_dir / csvName(t))) ∧
	│   status! = (if failed = ∅ then 0 else 1)
	└────────────────────────────────────────────────────────────

	┌─ RunFatal ─────────────────────────────────────────────────
	│ ΞFileSystem
	│ database? : PATH ; error! : MESSAGE
	├────────────────────────────────────────────────────────────
	│ database? ∉ readableFiles ∨ {mdb-tables, mdb-export} ⊈ dom PATH
	│   ∨ mdbTablesFails(database?)
	│ error! ≠ ∅
	└────────────────────────────────────────────────────────────

	ExporterRun ≙ Run ∨ RunFatal

=head1 STATE DIAGRAM

The life of one exporter object, and of one call to C<run>.  Each box is
a state.  Each arrow shows what causes the change, and what happens on
the way.

	            new(%settings)
	            action: validate settings, apply defaults
	                  |
	                  v
	          +----------------+ <-------------------------------------+
	          |     READY      |                                       |
	          +----------------+                                       |
	                  | run($database)                                 |
	                  v                                                |
	          +----------------+  database missing or unreadable,     |
	          |   CHECKING     |  mdb-tables/mdb-export not found     |
	          | database and   |-------------------------------+       |
	          | programs       |                               |       |
	          +----------------+                               |       |
	                  | OK; action: forget old file names;     |       |
	                  |   warn if mdb-count is missing and     |       |
	                  |   switch show_counts off               |       |
	                  v                                        |       |
	          +----------------+  mdb-tables fails             |       |
	          |    LISTING     |-------------------------------+       |
	          | tables         |                               |       |
	          +----------------+                               |       |
	                  | action: drop system tables, sort,      |       |
	                  |   filter by "tables", warn about       |       |
	                  |   unknown names                        |       |
	     +------------+-------------+                          |       |
	     | dry_run    | no tables   | tables to export         |       |
	     v            | selected    v                          |       |
	 +------------+   |    +----------------+  mkdir fails     |       |
	 |  DRY RUN   |   |    |   PREPARING    |------------------+       |
	 | print list |   |    | output folder  |                  |       |
	 | to STDOUT  |   |    +----------------+                  v       |
	 +------------+   |            | folder exists     +--------------+|
	     |            |            v                   |    FATAL     ||
	     |            |    +----------------+          | croak; no    ||
	     |            |    |   EXPORTING    |<--+      | file written |+
	     |            |    | one table      |   |      +--------------+
	     |            |    +----------------+   | next table
	     |            |      |           |      |
	     |            |      | success   | failure (file exists,
	     |            |      | action:   |   mdb-export fails, bad
	     |            |      | rename    |   character, ...)
	     |            |      | temp file |   action: delete temp file,
	     |            |      | into      |   carp, log, count failure
	     |            |      | place,    |      |
	     |            |      | log       +------+
	     |            |      +------------------+
	     |            |              | no tables left
	     |            v              v
	     |           +------------------+
	     |           |     SUMMARY      |  action: log "Processed N tables,
	     |           +------------------+          M failed"
	     |              |            |
	     v              v            v
	 return 0       return 0     return 1
	 (to READY)     (M = 0)      (M > 0)
	               (to READY)   (to READY)

Row counts (C<show_counts>) are counted in DRY RUN and after a table's
file is in place.  A count that fails is only a warning ("Cannot count
the rows of T"): the dry run shows C<?>, and an exported table still
counts as a success.

Not drawn above, because it can happen in every state after READY: an
interruption (SIGINT, SIGQUIT, SIGTERM or SIGHUP) goes to FATAL at once.
Its action: discard the table being exported (delete its temporary file),
start no further table, croak "Interrupted by SIGx".

=cut
