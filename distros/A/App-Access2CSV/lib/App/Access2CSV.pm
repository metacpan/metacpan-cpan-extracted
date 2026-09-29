package App::Access2CSV;

use strict;
use warnings;
use autodie qw(:all);

# Sub::Private must be in enforce mode before it is loaded, so that
# private class methods still work through $class->method dispatch
BEGIN { $Sub::Private::config{mode} = 'enforce' }

# Inherit i18n() and the protected _croak_i18n/_carp_i18n helpers
use parent 'App::Access2CSV::I18N';

use App::Access2CSV::Exporter;
use Fcntl qw(O_APPEND O_CREAT O_WRONLY);
use File::Temp;
use Getopt::Long qw(GetOptionsFromArray);
use Log::Abstraction;
use Pod::Usage qw(pod2usage);
use Readonly;
use Return::Set qw(set_return);
use Scalar::Util qw(blessed);
use Sub::Private;

our $VERSION = '0.001.0';

# ---------------------------------------------------------------------
# Roadmap (from the pre-release gap analysis)
#
# Features
# TODO: Pass mdbtools' CSV options through: --delimiter, --quote,
#	--date-format, --no-header, binary column handling (mdb-export's
#	-d, -q, -D, -H and -b).
# TODO: --schema: write each table's definition next to its data, using
#	mdb-schema.
# TODO: Export one table to standard output (--table X --output -), for
#	use in pipes.
# TODO: --gzip, or a single ZIP file holding all the CSV files.
# TODO: More output formats: JSON Lines, and SQL INSERT statements
#	(mdb-export -I).
# TODO: --jobs N: export several tables at once.  Starting one mdbtools
#	process per table is the main cost of a run.
# TODO: A second back end using ODBC (DBD::ODBC with the Microsoft Access
#	driver), so Windows does not need mdbtools.
# TODO: Ship at least one real translation (e.g. German) to prove the
#	message catalog end to end.
# TODO: Read settings from a configuration file via Object::Configure;
#	%DEFAULTS is already laid out for it.
# TODO: Optionally exit 130 on Ctrl-C (the shell convention), not 3.
#
# Technical debt
# TODO: Sub::Private/Sub::Protected hide the real subs from Devel::Cover
#	(worked around by the CHECK block in I18N.pm) and refuse
#	Test::Mockingbird hooks unless $Sub::*::BYPASS is set.  Fix both in
#	Sub::Private/Sub::Protected, then drop the workaround.
# TODO: Remove the IO::Handle::flush workaround in t/edge_cases.t once the
#	Test::Mockingbird fix for mocking inherited methods is released.
# TODO: IPC::Run3 does not reveal the child's process ID, so after SIGTERM
#	the running mdb-export is not stopped.  Moving to IPC::Run or
#	IPC::Open3 would allow that, and streaming for --jobs.
# TODO: The log symlink check and Log::Abstraction's own open are two
#	steps; closing that gap needs Log::Abstraction to accept an open
#	filehandle.
# TODO: I18N.pm also holds helpers unrelated to messages (_printable,
#	_interrupt_signals, the coverage CHECK block); move them to a small
#	shared module, and remove the duplicated control-character patterns
#	(I18N.pm and Exporter.pm) at the same time.
# TODO: The test files repeat the same helpers (slurp, new_database, cli,
#	stand-in set-up); a shared t/lib helper module would shrink them and
#	remove most Windows skips in one place.
# TODO: Tests read exporter internals ($e->{show_counts}, {used_names});
#	small read-only accessors would make refactoring safer.
# ---------------------------------------------------------------------

# Stop Carp from reporting errors against the access-control wrappers
our @CARP_NOT = qw(Sub::Private Sub::Protected App::Access2CSV::I18N);

# Exit statuses, documented in the POD below
Readonly::Scalar my $EXIT_OK      => 0;
Readonly::Scalar my $EXIT_FAILURE => 1;
Readonly::Scalar my $EXIT_USAGE   => 2;
Readonly::Scalar my $EXIT_FATAL   => 3;

# Pod::Usage verbosity levels for --help and --man, and for usage errors
Readonly::Scalar my $POD_SYNOPSIS => 0;
Readonly::Scalar my $POD_OPTIONS  => 1;
Readonly::Scalar my $POD_FULL     => 2;

# The database name that means "read it from standard input"
Readonly::Scalar my $STDIN_NAME => '-';

# Standard input is copied, in chunks of this many bytes, to a private
# temporary file named from this template (mdbtools need a real file)
Readonly::Scalar my $READ_CHUNK     => 65_536;
Readonly::Scalar my $STDIN_TEMPLATE => 'access2csv-stdin-XXXXXX';

# Log levels: --verbose adds the debug messages
Readonly::Scalar my $LOG_LEVEL         => 'info';
Readonly::Scalar my $LOG_LEVEL_VERBOSE => 'debug';

# Command-line defaults; the flat layout is compatible with Object::Configure
Readonly::Hash my %DEFAULTS => (
	output_dir  => '.',
	overwrite   => 0,
	verbose     => 0,
	dry_run     => 0,
	show_counts => 0,
	progress    => 1,
	encoding    => 'utf8',
	log         => 'access2csv.log',
);

=encoding utf8

=head1 NAME

App::Access2CSV - Export the tables of a Microsoft Access database to CSV files

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

	# Export every table to the current directory
	access2csv shop.accdb

	# See what would be written, with row counts, without writing anything
	access2csv --dry-run --show-counts shop.accdb

	# Export only two tables, into a folder called "exports"
	access2csv --output-dir exports --table Customers --table Orders shop.mdb

	# Make files that Excel opens correctly, replace old files, no log file
	access2csv --encoding utf8-bom --overwrite --no-log shop.accdb

	# Read the database from standard input ("-"), e.g. from a download
	curl -s https://example.com/shop.accdb | access2csv --output-dir exports -

	# Nightly job: quiet, with a log in a fixed place, and stop on failure
	access2csv --no-progress --log /var/log/access2csv.log \
		--output-dir /srv/exports --overwrite shop.accdb || exit 1

=head1 DESCRIPTION

Microsoft Access keeps its data in C<.mdb> or C<.accdb> files.
C<access2csv> reads one of these files and writes one CSV file
(comma-separated values, a plain-text table) for each table in it.

It does not read the Access file itself.  It runs three small programs
from the free B<mdbtools> package:

=over 4

=item * C<mdb-tables> - to get the list of tables

=item * C<mdb-export> - to get the data of each table as CSV

=item * C<mdb-count> - to count rows (only when you use B<--show-counts>)

=back

These programs must be installed and must be in your C<PATH>.

Access also keeps its own internal tables in the file.  Their names start
with C<MSys>, C<USys> or C<~>.  They are skipped.

=head2 How the CSV files are named

Each file has the name of its table plus C<.csv>, for example
C<Orders.csv>.  Some characters are not allowed in file names on some
computers (C<< < > : " / \ | ? * >> and control characters).  They are
changed to C<_>, and so are invisible text-direction controls (such as
U+202E, "right-to-left override"), which could make a file name look
like something else.  Spaces and dots at the end, and spaces at the start,
are removed.  A name such as C<CON> or C<NUL> (reserved on Windows) gets a
C<_> in front.  An empty name becomes C<unnamed>.

If two tables would get the same file name, the second one gets C<_2>,
the third C<_3>, and so on.  Upper and lower case count as the same here,
because Windows and macOS treat C<Orders.csv> and C<ORDERS.csv> as one file.

=head2 Reading the database from standard input

If the database name is C<->, the database is read from standard input
instead of a file, so it can be piped in.  mdbtools can only read a real
file, so the data is first copied to a private temporary file (readable
by you only) in the temporary folder (C<TMPDIR>, or F</tmp>), and that
copy is deleted when the program ends - whether it succeeds, fails or is
interrupted.

C<-> is refused if standard input is a terminal (there is nothing to
read but the keyboard), and empty input is an error.  To use a file that
is really called C<->, write F<./->.

=head2 How files are written

Each file is first written to a hidden temporary file (its name starts
with C<.access2csv->) in the output directory.  Only when it is complete
is it renamed to its real name.  So if something goes wrong, you never
get a half-written CSV file, and an old file is only replaced by a
complete new one.

=head1 REQUIREMENTS

The mdbtools programs C<mdb-tables> and C<mdb-export> must be installed
and in your C<PATH>; C<mdb-count> is needed only for B<--show-counts>.
They are not Perl modules, so the CPAN installer cannot install them for
you.  Install them with your system's package manager, for example:

	sudo apt install mdbtools       # Debian, Ubuntu
	sudo dnf install mdbtools       # Fedora
	brew install mdbtools           # macOS (Homebrew)
	pacman -S mingw-w64-x86_64-mdbtools   # Windows (MSYS2)

Without them the program stops with "Required program not found in
PATH".  Project home: L<https://github.com/mdbtools/mdbtools>.

=head1 USING FROM PERL

The program is a very thin wrapper.  You can call the same code from Perl:

	use App::Access2CSV;

	my $status = App::Access2CSV->run('--no-log', '--output-dir', 'out', 'shop.accdb');

For more control, use L<App::Access2CSV::Exporter> directly.

=head1 OPTIONS

=over 4

=item B<--output-dir> I<DIR>

The folder to write the CSV files to.  It is created if it does not exist.
Default: the current folder.

=item B<--table> I<NAME>

Export only this table.  You can use this option more than once.
Names must match exactly, including upper and lower case.  A name that is
not in the database gives a warning.

=item B<--overwrite>

Replace CSV files that already exist.  Without this option, a table whose
CSV file already exists is not exported, and it counts as a failure.

=item B<--verbose>

Write more detail to the log (where each mdbtools program was found).
Also show the Perl file and line number in fatal error messages.

=item B<--dry-run>

Only print a list of the tables and the file names they would get.
Nothing is written.  The output folder is not created.

=item B<--show-counts>

Show the number of rows of each table: in the dry-run list, and in the
log.  This needs C<mdb-count>.  Without it you get a warning, and the
export goes on without counts.

=item B<--no-progress>

Do not print the C<[1/5] Customers> progress lines.  (These lines go to
standard error, not standard output.)

=item B<--encoding> I<utf8|utf8-bom|cp1252>

The character encoding of the CSV files.  See L</ENCODING>.
Default: C<utf8>.

=item B<--log> I<FILE>

Add log messages to the end of I<FILE>.  Default: F<access2csv.log> in
the current folder.  An empty name (C<--log ''>) means no log.  I<FILE>
must not be a symbolic link (see L</SECURITY>).

=item B<--no-log>

Do not write a log file.

=item B<--help>, B<-h>

Print the synopsis and the options, then stop.

=item B<--man>

Print this whole manual, then stop.

=item B<--version>

Print the version ("access2csv version 0.001.0"), then stop.

=back

=head1 EXIT STATUS

The program ends with one of these numbers.  Scripts can test it.

	0  Every selected table was exported.  Also used for --dry-run,
	   --help, --man and --version.
	1  At least one table was not exported.  The other tables were.
	2  The command line was wrong, for example an unknown option, an
	   invalid value (--encoding latin1), no database name, or "-" while
	   standard input is a terminal.  Nothing has been done.
	3  A fatal error happened before any table was exported, for example
	   the database does not exist or mdbtools is not installed.

=head1 ENCODING

=head2 The data in the CSV files

mdbtools gives the table data as UTF-8, the encoding that can hold every
character, including accented letters, Chinese and Japanese text, and
emoji.

=over 4

=item * C<utf8> (the default) - the data is copied exactly as mdbtools
gives it.  Every character, including emoji, is kept.

=item * C<utf8-bom> - the same, plus three bytes at the very start of each
file (a "byte order mark").  These bytes tell Microsoft Excel that the file
is UTF-8.  Without them, Excel may show accented letters wrongly.  Some
other programs show the mark as strange characters in the first column
name.

=item * C<cp1252> - Windows-1252, an old Western European encoding.  It has
only 256 characters: English letters, most Western European accented
letters, and a few symbols such as the Euro sign.  It has no Greek,
Cyrillic, Chinese, Japanese or emoji.  If a table contains a character
that Windows-1252 cannot hold, that table is B<not> exported, and the
error message gives the line number.  Nothing is silently replaced.

=back

=head2 Names on the command line

Database paths, folder names, log file names and table names are used
exactly as the operating system gives them to the program (as bytes).
On Linux and macOS, where the terminal uses UTF-8, names with accented
letters, non-Latin scripts and emoji work.  On Windows, the command line
uses the system code page, so names outside that code page may not work.

=head2 Messages

All messages that the program prints and logs are in plain ASCII English.

=head1 ENVIRONMENT

=over 4

=item C<PATH>

Used to find C<mdb-tables>, C<mdb-export> and C<mdb-count>.  Only
absolute folders in C<PATH> are used: relative entries such as C<.> are
ignored, so a program planted in the current folder is never run.

=item C<LANGUAGE>, C<LC_ALL>, C<LC_MESSAGES>, C<LANG>

Choose the language of messages (see L<App::Access2CSV::I18N>).  Only the
language code at the start is used; any other value means English.

=item C<TMPDIR>

Where a database read from standard input (C<->) is copied while it is
exported.  Default: F</tmp>.

=item C<MDB_ICONV>

Not read by this program, but by mdbtools: it sets the character set
mdbtools converts to.  Leave it unset, so that the output is UTF-8.

=back

=head1 SECURITY

The program treats the database as untrusted: an Access file received
from someone else may contain table names and data designed to cause
harm.

=over 4

=item * B<No shell, no option injection.>  Programs are run directly
(never through a shell), and table and file names are passed after a
C<--> marker, so names containing C<; | $( ) `> or starting with C<->
are only ever names.

=item * B<No planted programs.>  Relative C<PATH> entries are ignored
(see L</ENVIRONMENT>).  The mdbtools programs are started with a cleaned
environment: C<PATH> holds only absolute folders, and C<IFS>, C<CDPATH>,
C<ENV> and C<BASH_ENV> are removed.

=item * B<Taint mode.>  The program runs under Perl's taint mode
(C<perl -T>).  Every outside value - the database path, table names,
C<--output-dir>, C<--log> and the program paths found in C<PATH> - is
checked first and only then marked as safe.  Under C<-T>, Perl also
refuses to start mdbtools while C<PATH> contains a folder other users can
write to; the program then stops with "Insecure directory in
$ENV{PATH}".

=item * B<Private copies of piped input.>  A database read from standard
input is copied with L<File::Temp> (a new, unpredictable name, readable
by you only) and deleted when the program ends, also after an error or
an interruption.

=item * B<Safe file names.>  Table names cannot place a file outside the
output folder, and control characters - including invisible
text-direction controls and C1 controls - are replaced by C<_>.

=item * B<Safe terminal and log output.>  Table names and mdbtools error
text are printed with control characters shown as escapes such as
C<\x1B>.  So a table name cannot retitle or clear your terminal, hide
text, or forge lines in the log.

=item * B<No writing through symbolic links.>  If the log file is a
symbolic link (for example one planted in a shared folder such as
F</tmp>), the program stops instead of writing to the file it points at.
Existing CSV files that are links are replaced, never written through.

=item * B<Spreadsheet formulas are NOT neutralised.>  A value such as
C<=cmd|' /C calc'!A0> is copied into the CSV exactly as it is in the
database, because changing data would corrupt genuine values.  Some
spreadsheet programs run such formulas when a CSV is opened.  Do not open
CSV files exported from an untrusted database in a spreadsheet without
checking them, or import them as text.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<A log file appears in the current folder.>  By default the log is
F<access2csv.log> in the folder you run the program from.  Use B<--log> to
choose another place, or B<--no-log>.

=item * B<The second run fails.>  If the CSV files already exist, each table
fails (exit status 1) unless you give B<--overwrite>.

=item * B<--table does not find my table.>  Table names are case-sensitive:
C<--table orders> does not match C<Orders>.  Use B<--dry-run> to see the
exact names.

=item * B<A file is called Orders_2.csv.>  Two tables had names that give
the same file name (for example C<Orders> and C<ORDERS>, or C<A/B> and
C<A:B>).

=item * B<Progress lines appear even though I redirected the output.>
Progress lines go to standard error.  Use B<--no-progress>, or redirect
standard error too (C<2E<gt>/dev/null>).

=item * B<run() does not end the program.>  When calling from Perl,
C<< App::Access2CSV->run(...) >> returns the exit status.  It does not
call C<exit>.  Write C<< exit App::Access2CSV->run(@ARGV) >> if you want
the program to end.

=item * B<Pass a list, not an array reference.>  Write
C<< App::Access2CSV->run(@args) >>, not C<< App::Access2CSV->run(\@args) >>.

=item * B<A file called "-".>  C<-> means standard input, even after
C<-->.  Write F<./-> for a file with that name.

=item * B<Piped databases need temporary space.>  The whole database is
copied to the temporary folder first; if that folder is small, set
C<TMPDIR> to one with room.

=back

=head1 METHODS

=head2 run

=head3 Purpose

This is the whole C<access2csv> program.  It reads the command-line
options, opens the log, and runs an L<App::Access2CSV::Exporter>.

=head3 Arguments

The command-line arguments, as a list of strings (normally C<@ARGV>).
Your array is copied first, so it is not changed.

=head3 Returns

A number from 0 to 3, as described in L</EXIT STATUS>.
C<run> never calls C<exit> itself.

=head3 Side Effects

=over 4

=item * Everything that L<App::Access2CSV::Exporter/run> does: it creates
the output folder, writes CSV files, and prints progress to standard error.

=item * It prints help or usage text (help to standard output, usage errors
to standard error).

=item * It prints a fatal error, if there is one, to standard error as one
line that starts with C<access2csv:>.

=item * It creates or adds to the log file, unless logging is off.

=item * It leaves your C<$@>, C<$!>, C<$_> and any pending C<alarm> as
they were.

=back

=head3 Usage

	exit App::Access2CSV->run(@ARGV);

=head3 EXAMPLE

	use App::Access2CSV;

	# Export to ./out without a log file, then check what happened
	my $status = App::Access2CSV->run('--output-dir', 'out', '--no-log', 'shop.accdb');

	if($status == 0) {
		print "All tables were exported\n";
	} elsif($status == 1) {
		print "Some tables could not be exported\n";
	} elsif($status == 2) {
		print "The arguments were wrong\n";
	} else {
		print "Nothing was exported\n";
	}

=head3 API SPECIFICATION

=head4 Input

	{
		argv => {
			type         => 'arrayref',
			optional     => 1,
			element_type => 'string',
			description  => 'Command-line arguments, passed as a list',
		},
	}

Valid and invalid values (tested in F<t/domain.t>):

	database names  exactly 1; 0 or 2 or more give exit status 2.
	                "-" means standard input (exit 2 if it is a
	                terminal, 3 if it is empty or unreadable)
	--encoding      utf8, utf8-bom or cp1252; anything else gives exit 2
	--table         0 times (all tables), once, or many times; names
	                may be non-ASCII
	--log           a file name; '' means no log, like --no-log

=head4 Output

	{
		type => 'integer',
		min  => 0,
		max  => 3,
	}

=head3 MESSAGES

	+-------------------------------------+-------------------------------+------------------------------+
	| Message                             | Meaning                       | What to do                   |
	+-------------------------------------+-------------------------------+------------------------------+
	| Unknown option: X (exit 2)          | X is not an option of this    | See --help                   |
	|                                     | program                       |                              |
	| Option X requires an argument       | An option such as --log was   | Give a value after it        |
	|  (exit 2)                           | the last word                 |                              |
	| Invalid setting: REASON (exit 2)    | An option value is not        | Use a documented value (see  |
	|                                     | allowed, e.g. --encoding      | OPTIONS)                     |
	|                                     | latin1; REASON says which     |                              |
	| Missing database filename (exit 2)  | No database name was given,   | Give exactly one database    |
	|                                     | it was empty, or more than    |                              |
	|                                     | one was given                 |                              |
	| Standard input is a terminal: pipe  | "-" was given, but nothing is | Pipe the database in, or     |
	|  the database in, or give its file  | piped in                      | give its file name           |
	|  name (exit 2)                      |                               |                              |
	| access2csv: Standard input is empty:| "-" was given, but the pipe   | Check the command that       |
	|  no database was piped in (exit 3)  | delivered nothing             | produces the database        |
	| access2csv: Cannot read standard    | Reading the pipe failed; E is | See E                        |
	|  input: E (exit 3)                  | the reason                    |                              |
	| access2csv: Interrupted by SIGx     | Stopped (Ctrl-C, kill) while  | Run again                    |
	|  while reading the database from    | waiting for piped input; the  |                              |
	|  standard input (exit 3)            | partial copy was deleted      |                              |
	| access2csv: Cannot open log file F: | The log file cannot be        | Use --log with another file, |
	|  E (exit 3)                         | written; E is the reason from | or --no-log                  |
	|                                     | the operating system, "no     |                              |
	|                                     | logger was created", or "it   |                              |
	|                                     | is a symbolic link"           |                              |
	| access2csv: MESSAGE (exit 3)        | Any fatal error from the      | See MESSAGES in              |
	|                                     | exporter                      | App::Access2CSV::Exporter    |
	+-------------------------------------+-------------------------------+------------------------------+

=head3 PSEUDOCODE

	options := default settings
	read the command line into options
	if the command line is wrong: print usage, return 2
	if --help or --man: print the documentation, return 0
	if there is not exactly one database name: print usage, return 2
	try:
		open the log, unless logging is off
		status := new Exporter(options).run(database)
	if that failed:
		print "access2csv: <reason>" to standard error
		status := 3
	return status

=cut

sub run {
	my ($class, @argv) = @_;

	# Option parsing, file tests and the eval below would otherwise leave
	# their marks in the caller's $@ and $!
	local ($@, $!);

	# Parsing may already decide the outcome (--help, bad options, ...)
	my %opt = %DEFAULTS;
	my $status = $class->_parse_options(\@argv, \%opt);

	# CHECKING SETTINGS: a bad option value (e.g. --encoding latin1) is a
	# command-line mistake like any other: a usage error (exit 2), found
	# before anything with a side effect happens - before standard input
	# is copied and before the log file is created
	my %settings = map { $_ => $opt{$_} } grep { $_ ne 'log' } keys %opt;
	if(!defined($status) && !eval { App::Access2CSV::Exporter->new(%settings); 1 }) {
		$status = $class->_usage($EXIT_USAGE, $POD_SYNOPSIS, _strip_location($@));
	}

	if(!defined $status) {
		# Any croak from here on is a fatal error: report it, don't die
		$status = eval {
			# READING STDIN: "-" means standard input.  mdbtools can only
			# read a real file, so the data is copied to a private temporary
			# file first; the copy is deleted when $piped goes out of scope,
			# whatever happens
			my $piped = ($argv[0] eq $STDIN_NAME) ? $class->_read_stdin() : undef;
			my $database = $piped ? $piped->filename() : $argv[0];

			# OPENING LOG, then EXPORTING
			my $logger = $class->_make_logger(\%opt);
			App::Access2CSV::Exporter->new(%settings, ($logger ? (logger => $logger) : ()))->run($database);
		};
		$status = $class->_report_fatal($@, $opt{verbose}) unless defined $status;
	}

	return set_return($status, { type => 'integer', min => $EXIT_OK, max => $EXIT_FATAL });
}

# _parse_options
# Purpose:        Turn the command line into settings.
# Entry Criteria: $argv is an arrayref (modified in place: options are
#                 removed, leaving the positional arguments); $opt is a
#                 hashref of defaults.
# Exit Status:    Returns undef if the export should go ahead, otherwise
#                 the exit status to return straight away.
# Side Effects:   Fills in $opt; prints help, the manual or usage text.
sub _parse_options :Private {
	my ($class, $argv, $opt) = @_;

	my ($help, $show_version) = (0, 0);
	my $parsed = GetOptionsFromArray(
		$argv,
		'output-dir=s' => \$opt->{output_dir},
		'table=s@'     => \$opt->{tables},
		'overwrite!'   => \$opt->{overwrite},
		'verbose!'     => \$opt->{verbose},
		'dry-run!'     => \$opt->{dry_run},
		'show-counts!' => \$opt->{show_counts},
		'progress!'    => \$opt->{progress},
		'encoding=s'   => \$opt->{encoding},
		'log=s'        => \$opt->{log},
		'no-log'       => sub { $opt->{log} = undef },
		'help|h'       => sub { $help = $POD_OPTIONS },
		'man'          => sub { $help = $POD_FULL },
		'version'      => \$show_version,
	);

	# Only one of these applies; the first match decides the exit status.
	# Getopt::Long has already warned about any unknown option.
	return $class->_usage($EXIT_USAGE, $POD_SYNOPSIS) unless $parsed;
	return $class->_usage($EXIT_OK, $help) if $help;
	if($show_version) {
		print $class->i18n('version', { params => [$VERSION] }), "\n";
		return $EXIT_OK;
	}
	# An empty or undefined name is as good as no name at all.  length()
	# of an empty string is 0, so one length test covers "", and "// ''"
	# turns undef into "" first.
	if(@{$argv} != 1 || !length($argv->[0] // '')) {
		return $class->_usage($EXIT_USAGE, $POD_SYNOPSIS, $class->i18n('missing_database'));
	}

	# Reading a database from a terminal would only wait for keystrokes
	if($argv->[0] eq $STDIN_NAME && -t STDIN) {
		return $class->_usage($EXIT_USAGE, $POD_SYNOPSIS, $class->i18n('stdin_is_terminal'));
	}
	return;
}

# _usage
# Purpose:        Print documentation from this module's POD.
# Entry Criteria: $status is the exit status to return; $verbose is a
#                 Pod::Usage verbosity; $message is an optional error.
# Exit Status:    Returns $status.
# Side Effects:   Prints to STDOUT (help) or STDERR (errors).
sub _usage :Private {
	my ($class, $status, $verbose, $message) = @_;

	# The POD lives here, not in bin/access2csv, so point Pod::Usage at
	# this file; NOEXIT keeps run() testable
	pod2usage(
		-input   => __FILE__,
		-verbose => $verbose,
		-exitval => 'NOEXIT',
		-output  => $status == $EXIT_OK ? \*STDOUT : \*STDERR,
		(defined($message) ? (-message => $message) : ()),
	);
	return $status;
}

# _make_logger
# Purpose:        Create the log, unless logging is switched off.
# Entry Criteria: $opt->{log} is a file name, or undef/'' for no log.
# Exit Status:    Returns a Log::Abstraction object or undef; croaks if the
#                 file cannot be appended to.
# Side Effects:   Creates the log file if it does not exist.
sub _make_logger :Private {
	my ($class, $opt) = @_;

	return unless length($opt->{log} // '');

	my $file = $opt->{log};

	# Never write through a symbolic link: in a shared folder such as /tmp
	# anyone could plant "access2csv.log" pointing at a file of yours
	if(-l $file) {
		$class->_croak_i18n('log_open_failed', { params => [$file, $class->i18n('log_is_symlink')] });
	}

	# The log file is the invoking user's own choice and is not a link, so
	# it is untainted (for taint mode); a NUL byte cannot name a file at all
	($file) = $file =~ /\A([^\x00]+)\z/s or $class->_croak_i18n('log_open_failed', { params => [$opt->{log}, $class->i18n('invalid_name')] });

	# Log::Abstraction silently ignores an unwritable file, which would lose
	# the log without telling anyone, so prove that we can append first.
	# O_NOFOLLOW (where the OS has it) closes the gap between the -l test
	# above and the open.  The eval must not overwrite the caller's $@.
	local $@;
	eval {
		sysopen my $fh, $file, O_WRONLY | O_APPEND | O_CREAT | _no_follow();
		close $fh;
		1;
	} or $class->_croak_i18n('log_open_failed', { params => [$file, _failure_reason($@)] });

	my $logger = Log::Abstraction->new(
		logger => $file,
		level  => $opt->{verbose} ? $LOG_LEVEL_VERBOSE : $LOG_LEVEL,
	);

	# The user asked for a log; carrying on without one would silently
	# break that promise
	$logger or $class->_croak_i18n('log_open_failed', { params => [$file, $class->i18n('logger_unavailable')] });
	return $logger;
}

# _read_stdin
# Purpose:        Copy the database piped in on standard input to a
#                 private temporary file, because mdbtools can only read
#                 a real, seekable file.
# Entry Criteria: STDIN is not a terminal (checked by _parse_options).
# Exit Status:    Returns the File::Temp object; the file is deleted when
#                 the object is destroyed.  Croaks if the input is empty,
#                 cannot be read, cannot be stored, or the copy is
#                 interrupted.
# Side Effects:   Reads all of STDIN; writes a file (mode 0600) in the
#                 temporary folder (TMPDIR).
sub _read_stdin :Private {
	my $class = shift;

	# Perl's default action for INT/TERM/... exits at once, which would
	# leave the copy behind in the temporary folder.  Raise an exception
	# instead, so the File::Temp object is destroyed and deletes the file.
	my $interrupted;
	my @ours = @{ $class->_interrupt_signals() };
	local @SIG{@ours} = (sub { $interrupted = $_[0]; die "\n" }) x @ours;

	my $copy = File::Temp->new(TEMPLATE => $STDIN_TEMPLATE, TMPDIR => 1, UNLINK => 1);
	binmode $copy, ':raw';
	binmode STDIN, ':raw';

	# Copy in chunks: a large database is never held in memory at once
	my $total = 0;
	local $@;
	eval {
		while(my $got = read(STDIN, my $buffer, $READ_CHUNK)) {
			print {$copy} $buffer;
			$total += $got;
		}
		1;
	} or do {
		$class->_croak_i18n('interrupted_reading', { params => [$interrupted] }) if $interrupted;
		$class->_croak_i18n('stdin_read_failed', { params => [_failure_reason($@)] });
	};

	$class->_croak_i18n('stdin_empty') unless $total;

	# Make sure every byte reached the file (e.g. the disk may be full)
	$copy->flush() or $class->_croak_i18n('write_failed', { params => [$copy->filename(), "$!"] });
	return $copy;
}

# _strip_location
# Purpose:        Remove the " at FILE line N." that Carp appends, which is
#                 noise for a command-line user.
# Entry Criteria: $text is an error message.
# Exit Status:    Returns the message without the location or newline.
# Side Effects:   None.  A plain function, not a method.
#
# The file name may contain spaces ("My Documents"), so it cannot be
# matched as \S+.  Instead: " at ", then the shortest run of characters
# that does not contain another " at ", then " line N." at the very end.
# The (?! at ) guard keeps this linear: each attempt stops at the next
# " at ", so no character is scanned by more than one attempt.
sub _strip_location :Private {
	my $text = shift;

	$text =~ s/
		[ ] at [ ]                  # Carp's separator
		(?: (?! [ ] at [ ] ) . )*?  # the file name: anything but another " at "
		[ ] line [ ] \d+ \.?        # " line 42."
		\n? \z                      # at the very end
	//x;
	chomp $text;
	return $text;
}

# _failure_reason
# Purpose:        Explain why an eval failed.  An autodie exception carries
#                 the operating system's reason; anything else (such as a
#                 taint-mode "Insecure dependency") is reported as it is,
#                 not replaced by a stale $! from some earlier call.
# Entry Criteria: $error is the eval's $@.
# Exit Status:    Returns a one-line string.
# Side Effects:   None.  A plain function, not a method.
sub _failure_reason :Private {
	my $error = shift;

	my $reason = (blessed($error) && $error->can('errno') && length($error->errno())) ? $error->errno() : "$error";
	return _strip_location($reason);
}

# _no_follow
# Purpose:        The O_NOFOLLOW open flag, or 0 where the OS lacks it.
# Entry Criteria: None.
# Exit Status:    Returns an integer flag.
# Side Effects:   None.
sub _no_follow :Private {
	return eval { Fcntl::O_NOFOLLOW() } || 0;
}

# _report_fatal
# Purpose:        Tell the user why the program stopped.
# Entry Criteria: $error is the exception from eval; $verbose is the
#                 --verbose flag.
# Exit Status:    Returns the fatal exit status.
# Side Effects:   Prints to STDERR.
sub _report_fatal :Private {
	my ($class, $error, $verbose) = @_;

	# Carp appends " at FILE line N."; that is noise for a command-line
	# user, but useful when debugging, so keep it with --verbose
	my $text = length($error // '') ? "$error" : 'Unknown error';
	$text = $verbose ? $text : _strip_location($text);
	chomp $text;

	# The reason may quote a hostile table name or file name: escape it
	print STDERR $class->_printable($class->i18n('fatal', { params => [$text] })), "\n";
	return $EXIT_FATAL;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The real work is done by the external mdbtools programs.  Their
bugs, and their CSV style (quoting, date format, binary columns), are
passed on unchanged.  No maintained CPAN module can read C<.accdb> files,
so there is no pure-Perl alternative today.

=item * The reason inside "Invalid setting: ..." comes from
L<Params::Validate::Strict>, and messages from L<Getopt::Long> and
L<autodie> come from those modules; none of them is translated.

=item * B<Windows.>  The code handles Windows (its C<PATH> separator, the
absence of Unix permission bits and of signals), and the core export
tests (F<t/exporter.t>, F<t/app.t>) run there.  Most other test files
use Unix-only facilities (signals, symbolic links, F</proc>, taint-mode
child processes, terminals) and are skipped on Windows, so those
features are tested on Unix only.

=item * The default log file is created in the current folder, which may
surprise users.

=item * Settings come from the command line only.  C<%DEFAULTS> is laid out
so that L<Object::Configure> could read them from a configuration file,
but this is not connected yet.

=back

=head1 TESTING WITH REAL DATABASES

Most tests use stand-in mdbtools programs.  F<t/real-mdbtools.t> checks
the program against the real mdbtools and real Access files: every CSV
must be byte for byte what C<mdb-export> prints.  No database ships with
this distribution; point C<ACCESS2CSV_TEST_DATA> at a folder of
C<.mdb>/C<.accdb> files, for example the mdbtools project's test data:

	git clone --depth 1 https://github.com/mdbtools/mdbtestdata
	ACCESS2CSV_TEST_DATA=mdbtestdata/data prove -l t/real-mdbtools.t

The continuous-integration workflow does this on Linux.

=head1 SEE ALSO

L<App::Access2CSV::Exporter>, L<App::Access2CSV::I18N>, L<Log::Abstraction>,
L<https://github.com/mdbtools/mdbtools>

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/App-access2csv/coverage/>

=back

=head1 FORMAL SPECIFICATION

These schemas use the Z notation.  C<?> marks an input and C<!> an output.
You do not need to read this section to use the program.

=head2 run

	┌─ Run ──────────────────────────────────────────────────────
	│ argv? : seq STRING ; status! : 0 ‥ 3
	│ opts : OPTION ⇸ VALUE ; rest : seq STRING
	├────────────────────────────────────────────────────────────
	│ (opts, rest) = getopt(DEFAULTS, argv?)
	│ ¬ parsed(argv?) ⇒ status! = 2
	│ parsed(argv?) ∧ help ∈ dom opts ⇒ status! = 0
	│ parsed(argv?) ∧ help ∉ dom opts ∧ #rest ≠ 1 ⇒ status! = 2
	│ parsed(argv?) ∧ help ∉ dom opts ∧ #rest = 1 ∧ head rest = "-" ∧
	│   isTerminal(stdin) ⇒ status! = 2
	│ ¬ valid(opts) ⇒ status! = 2 ∧ files' = files   -- checked first: no copy, no log
	│ db = (if head rest = "-" then copy(stdin) else head rest)
	│ parsed(argv?) ∧ help ∉ dom opts ∧ #rest = 1 ∧
	│   ¬ (head rest = "-" ∧ isTerminal(stdin)) ⇒
	│   (fatal(Exporter.Run(db)) ⇒ status! = 3) ∧
	│   (¬ fatal(Exporter.Run(db)) ⇒ status! = Exporter.Run(db).status!)
	│ files'(copy(stdin)) undefined          -- the copy never outlives the run
	└────────────────────────────────────────────────────────────

=head2 Printable output

Every message shown on the terminal or written to the log first passes
through this filter.  C<CTRL> is the set of control characters: C0
except tab, DEL, C1 and the text-direction controls.

	┌─ Printable ────────────────────────────────────────────────
	│ text? : seq CHAR ; shown! : seq CHAR
	├────────────────────────────────────────────────────────────
	│ shown! = ⁀/ ⟨ c : text? • (if c ∈ CTRL then escape(c) else ⟨c⟩) ⟩
	│ ran shown! ∩ CTRL = ∅
	└────────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

One call of C<run>, from start to exit status.  Each box is a state.
Each arrow shows what moves the program to the next state, and what
happens on the way.

	                  run(@argv)
	                      |
	                      v
	              +---------------+
	              |    PARSING    |  read options into the settings
	              +---------------+
	               |      |      |
	 bad option,   |      |      | --help / --man / --version
	 missing value,|      |      | action: print it to STDOUT
	 not exactly   |      |      v
	 one database, |      |   +--------+
	 or "-" while  |      |   |  HELP  |---> return 0
	 standard input|      |   +--------+
	 is a terminal |      |
	               |      | options parsed, one database
	               |      v
	               |   +--------------------+
	               |   | CHECKING SETTINGS  |
	               |   +--------------------+
	               |      |               |
	               |<-----+ invalid value | valid
	               |        (e.g.         |
	               |        --encoding    |
	 action: print |        latin1)       v
	 the reason    |              +--------------------+  empty, unreadable,
	 and usage to  |              |   READING STDIN    |  or interrupted
	 STDERR        v              | (only for "-")     |  (croak) ------------+
	      +-------------+         +--------------------+                      |
	      | USAGE ERROR |           | action: copy standard input to a        |
	      +-------------+           |   private temporary file                |
	          |                     v                                         |
	 return 2 <           +--------------------+  log cannot be opened        |
	                      |    OPENING LOG     |  (croak)                     |
	                      | (not with --no-log)|------------------------------+
	                      +--------------------+                              |
	                        | log is writable                                 |
	                        v                                                 |
	              +--------------------+                                      |
	              | EXPORTING          |  fatal error (croak)                 |
	              | (Exporter->run,    |--------------------------------------+
	              |  see its STATE     |                                      |
	              |  DIAGRAM)          |                                      v
	              +--------------------+                           +------------------+
	                 |              |                              |      FATAL       |
	   all tables OK,|              | some table                   +------------------+
	   or dry run    |              | failed                       action: print
	                 v              v                              "access2csv: <reason>"
	             return 0       return 1                           to STDERR; return 3

Whichever way the run ends, a copy made of standard input is deleted.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
