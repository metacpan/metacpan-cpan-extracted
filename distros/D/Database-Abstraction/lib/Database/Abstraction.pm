package Database::Abstraction;

# Author Nigel Horne: njh@nigelhorne.com
# Copyright (C) 2015-2026, Nigel Horne

# Usage is subject to licence terms.

# TODO:	Switch "entry" to off by default, and enable by passing 'entry'
#	though that wouldn't be so nice for AUTOLOAD
# TODO:	support a directory hierarchy of databases
# TODO:	consider returning an object or array of objects, rather than hashes
# TODO:	Add redis database - could be of use for Geo::Coder::Free
#	use select() to select a database - use the table arg
#	new(database => 'redis://servername');
# TODO:	Add a "key" property, defaulting to "entry", which would be the name of the key
# TODO:	The maximum number to return should be tuneable (as a LIMIT)
# TODO:	Add full CRUD support
# TODO:	It would be better for the default sep_char to be ',' rather than '!'
# TODO:	Other databases e.g., Redis, noSQL, remote databases such as MySQL, PostgreSQL
# TODO: The no_entry/entry terminology is confusing.  Replace with no_id/id_column
# TODO: Log queries and the time that they took to execute per database
# TODO: Use DBD::JSON if one is ever written

use warnings;
use strict;
use autodie qw(:all);

use boolean;
use Carp;
use Class::Abstract;
use Data::Reuse;
use DBI;
use Fcntl;	# For O_RDONLY
use Cwd;
use File::Spec;
use File::Temp;
use List::Util qw(all any);
use Log::Abstraction 0.33;
use Object::Configure 0.16;
use Params::Get 0.17;
use Return::Set qw(set_return);
use Scalar::Util;
use Sub::Private;
use Sub::Protected;

# File::Slurp::Remote is loaded lazily in _open() when host => '...' is given.

our %defaults;
use constant	DEFAULT_MAX_SLURP_SIZE => 16 * 1024;	# CSV files <= than this size are read into memory

# Compiled once at module load; reused in every identifier-safety check.
# Using \A/\z (true string anchors) rather than ^/$ which match around \n.
# SAFE_IDENTIFIER: bare SQL identifier — letters, digits, underscore.
# SAFE_QUALIFIED:  allows a single dot for table.column notation in JOINs.
my $SAFE_IDENTIFIER = qr/\A[a-zA-Z_][a-zA-Z0-9_]*\z/;
my $SAFE_QUALIFIED  = qr/\A[a-zA-Z_][a-zA-Z0-9_.]*\z/;

# Type-inference regexes and sample size for schema() when infer_types => 1.
# Compiled once at load; reused in _infer_type() across all schema() calls.
use constant INFER_TYPE_SAMPLE_SIZE => 100;
my $INFER_INT_RE  = qr/\A-?\d+\z/;
my $INFER_REAL_RE = qr/
    \A              # start of string
    -?              # optional leading minus
    \d+             # integer part -- required
    (?:\.\d+)?      # optional decimal part
    (?:             # optional exponent block:
        [eE]        #   e or E marker
        [+-]?       #   optional sign
        \d+         #   exponent digits
    )?
    \z              # end of string
/x;
# No \z anchor: intentionally matches any valid timestamp prefix so that full
# timestamps with seconds, fractional seconds, or timezone offsets are still
# classified as TIMESTAMP -- e.g. 2024-01-01 12:34:00.000+05:30
my $INFER_TS_RE   = qr/
    \A                              # start of string
    \d{4}                           # 4-digit year
    - (?:0[1-9]|1[0-2])            # month 01-12
    - (?:0[1-9]|[12]\d|3[01])      # day   01-31
    [T\ ]                           # ISO 8601 date-time separator: T or space
    \d{2}:\d{2}                     # HH:MM -- no end anchor, see note above
/x;
my $INFER_DATE_RE = qr/
    \A                              # start of string
    \d{4}                           # 4-digit year
    - (?:0[1-9]|1[0-2])            # month 01-12
    - (?:0[1-9]|[12]\d|3[01])      # day   01-31
    \z                              # end of string
/x;

# Module-level constant: valid JOIN types after uc() normalisation.
# Built once at compile time; reused by every _build_joins call.
my %VALID_JOIN_TYPES = map { $_ => 1 } qw(INNER LEFT RIGHT FULL CROSS);

=head1 NAME

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

=head1 VERSION

Version 0.47

=cut

our $VERSION = '0.47';

=head1 DESCRIPTION

C<Database::Abstraction> is a read-only ORM for Perl that gives a uniform
interface over CSV, PSV, TSV, JSON, XML, SQLite, DBM::Deep, BerkeleyDB, and
Excel (XLS/XLSX) files - local, remote (via SSH), or fetched from a URL -
without writing any SQL.
Effectively it allows you to access a database table, of many different
database formats, as an object.

Key features:

=over 4

=item *

B<No SQL required.>  Use plain Perl method calls for simple lookups and
scans; switch storage formats without changing application code.

=item *

B<Rich query criteria.>  Pass plain values, SQL wildcards, C<undef> (IS NULL),
comparison operators (C<< > >> C<< < >> C<< >= >> C<< <= >> C<!=>), pattern
operators (C<-like>, C<-not_like>), set operators (C<-in>, C<-not_in>,
C<-between>), and logical groupings (C<-or>, C<-and>).

=item *

B<Automatic joins.>  Add a C<join> parameter to any select method to
combine tables with INNER, LEFT, RIGHT, FULL, or CROSS joins.

=item *

B<Chained query builder.>  The C<query()> method returns a
L<Database::Abstraction::Query> object for fluent, composable queries:
C<< $db->query->where(...)->order_by(...)->limit(...)->all() >>.

=item *

B<Schema introspection.>  C<columns()> lists column names; C<schema()>
returns full type/nullability metadata, using native driver introspection
(C<PRAGMA table_info> for SQLite, C<column_info> for others).

=item *

B<DSN portability.>  Pass a C<dsn> (plus optional C<username>/C<password>)
to connect to any DBI-supported database (SQLite, PostgreSQL, MySQL, ...)
instead of pointing at a local file.

=item *

B<Performance.>  Small files are slurped into a RAM hash for sub-millisecond
lookups.  All DBI statement handles are cached with C<prepare_cached()>.
A CHI-compatible cache layer is also supported.

=back

=head1 SYNOPSIS

    # 1. Create a thin subclass for your table (e.g. Database/Foo.pm)
    package Database::Foo;
    use parent 'Database::Abstraction';

    # 2. Open the database - file is auto-detected from the class name
    #    (looks for foo.sql / foo.sqlite / foo.sqlite3 / foo.psv / foo.tsv / foo.csv / foo.xlsx / foo.xml / foo.json / foo.db)
    my $db = Database::Foo->new(directory => '/path/to/data');

    # 3. Simple lookups -----------------------------------------------

    # Fetch one row
    my $row = $db->fetchrow_hashref(entry => 'key1');

    # Fetch all rows matching a criterion
    my $rows = $db->selectall_arrayref(status => 'active');

    # Column shortcut via AUTOLOAD
    my $name = $db->name(entry => 'key1');

    # 4. Rich criteria ------------------------------------------------

    # Comparison operators
    my $high = $db->selectall_arrayref(score => { '>' => 90 });

    # Set membership
    my $selected = $db->selectall_arrayref(
        name => { -in => ['Alice', 'Bob'] }
    );

    # Range
    my $mid = $db->selectall_arrayref(
        score => { -between => [60, 80] }
    );

    # OR grouping
    my $either = $db->selectall_arrayref(
        -or => [
            { status => 'active'    },
            { score  => { '>' => 95 } },
        ]
    );

    # 5. Joins --------------------------------------------------------

    my $joined = $db->selectall_arrayref(
        join => { table => 'dept', on => 'foo.dept_id = dept.id', type => 'LEFT' }
    );

    # 6. Chained query builder ----------------------------------------

    my $results = $db->query
        ->where(status => 'active')
        ->where(score  => { '>=' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->all();

    my $first = $db->query->where(name => 'Alice')->first();
    my $count = $db->query->where(status => 'active')->count();

    # 7. Connect via DSN (PostgreSQL, MySQL, SQLite, ...) ---------------

    my $db2 = Database::Foo->new(
        dsn      => 'dbi:Pg:dbname=mydb;host=db.example.com',
        username => 'myuser',
        password => 's3cret',
    );

    # 8. Schema introspection -----------------------------------------

    my $cols   = $db->columns();  # ['entry', 'name', 'score', ...]
    my $schema = $db->schema();   # { name => { type=>'TEXT', nullable=>1, ... }, ... }

=head1 QUICK START EXAMPLE

If F</var/dat/foo.csv> contains:

    "customer_id","name"
    "plugh","John"
    "xyzzy","Jane"

Create a driver in F<.../Database/foo.pm>:

    package Database::foo;
    use parent 'Database::Abstraction';

    # Regular CSV: no entry column, comma-separated
    sub new {
        my ($class, %args) = @_;
        return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

Then query it:

    my $foo = Database::foo->new(directory => '/var/dat');

    # Prints "John"
    print 'Customer: ', $foo->name(customer_id => 'plugh'), "\n";

    # Returns { customer_id => 'xyzzy', name => 'Jane' }
    my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');

=head1 FILE FORMATS

The module probes the C<directory> for files in this priority order:

=over 4

=item 1. C<SQLite>

File ending C<.sql>, C<.sqlite>, or C<.sqlite3>.
Requires L<DBD::SQLite>.

=item 2. C<Deep>

DBM::Deep file ending C<.dbm> or C<.deep>.  The entire file is slurped
into a plain Perl hash on open; all in-memory fast-paths apply.
Requires L<DBM::Deep> (loaded lazily).

=item 3. C<PSV>

Pipe-separated file, ending C<.psv>.

=item 4. C<TSV>

Tab-separated file, ending C<.tsv>.

=item 5. C<CSV>

Comma (or custom) separated file, ending C<.csv> or C<.db>; can be
gzipped (C<.csv.gz> or C<.db.gz>).
B<Note:> the default separator is C<!> not C<,> for historical
reasons - pass C<< sep_char => ',' >> for standard CSVs.
Requires L<Text::xSV::Slurp> for the slurp fast-path (loaded lazily).

=item 6. C<Excel> (C<.xls>) and C<XLSX> (C<.xlsx>)

Two separate Excel backends - one per file format:

=over 4

=item B<.xls> - old binary format, opened via L<DBD::Excel> (which uses
L<Spreadsheet::ParseExcel> internally).  All queries go through DBI/SQL;
no in-memory slurp path.  C<max_slurp_size> has no effect.

=item B<.xlsx> - modern OOXML format, parsed directly via
L<Spreadsheet::ParseXLSX> and slurped into an in-memory hash (keyed mode)
or array (C<no_entry> mode).  No DBI handle is created; all queries use
the in-memory fast-path.  Complex criteria (operator hashes, C<-or>/C<-and>)
will fall through to the SQL path and croak - use simple scalar criteria.

=back

For both formats, each worksheet is a separate logical table; the active
worksheet is determined by the class-derived table name (or the C<table>
constructor parameter).  Both modules are loaded lazily.

=item 7. C<XML>

File ending C<.xml>.
Requires L<XML::Simple> for the slurp fast-path (loaded lazily).

=item 8. C<JSON>

File ending C<.json>, slurped into memory via L<JSON::MaybeXS> (loaded
lazily).

The file may contain either a JSON array of row objects:

    [
      { "entry": "key1", "col": "val1" },
      { "entry": "key2", "col": "val2" }
    ]

or a JSON object whose keys are the primary-key values:

    {
      "key1": { "col": "val1" },
      "key2": { "col": "val2" }
    }

In the object form, each key is injected into its row hash under the C<id>
column name (default C<entry>), so all normal lookups work identically to
the array form.

A zero-byte or whitespace-only file is treated as empty - all query methods
return 0 / C<undef> / C<[]> without throwing.
Requires L<JSON::MaybeXS> (loaded lazily).

=item 9. C<BerkeleyDB>

Binary key-value file ending C<.db>.

=item 10. C<HTML>

HTML page fetched via a C<url>.  Pass C<url => 'https://...'> instead of
C<directory>; the module fetches the page with L<LWP::UserAgent::Cached>, parses all
C<< <table> >> elements with L<HTML::TableExtract>, and slurps the first (or
C<html_table_index>-selected) table into memory.  The first row of the table
is treated as column headers.  Both modules are loaded lazily and are not
required for other backends.

=back

Pass C<dsn> to bypass file detection entirely and connect via any DBI driver.
Pass C<url> to fetch and slurp data from a remote source without a local
directory.  When the URL returns C<Content-Type: application/json> or the URL
path ends in C<.json>, the response is parsed as JSON (see item 8 above).
Otherwise the response is parsed as an HTML page (item 10).

Example - fetching CPAN Testers results:

    package Database::cpantesters;
    use parent 'Database::Abstraction';

    my $db = Database::cpantesters->new(
        url      => 'https://www.cpantesters.org/show/Database-Abstraction.json',
        no_entry => 1,
    );
    my $passes = $db->selectall_arrayref(grade => 'PASS');

=head1 QUERY CRITERIA

All select methods (C<selectall_arrayref>, C<selectall_array>,
C<fetchrow_hashref>, C<count>) accept the same criteria syntax.

=head2 Plain value

    status => 'active'          # status = 'active'
    name   => undef             # name IS NULL

Values containing C<%> or C<_> are matched with C<LIKE>:

    name => 'A%'                # name LIKE 'A%'

=head2 Comparison operator hashref

    score => { '>'  => 90  }   # score > 90
    score => { '<'  => 50  }   # score < 50
    score => { '>=' => 80  }   # score >= 80
    score => { '<=' => 100 }   # score <= 100
    score => { '!=' => 0   }   # score != 0

Multiple operators on one column are ANDed:

    score => { '>' => 60, '<' => 90 }   # 60 < score < 90

=head2 Pattern matching

    name => { -like     => 'A%'  }   # name LIKE 'A%'
    name => { -not_like => 'Z%'  }   # name NOT LIKE 'Z%'

=head2 Set membership

    name => { -in     => ['Alice', 'Bob'] }   # name IN (...)
    name => { -not_in => ['Alice', 'Bob'] }   # name NOT IN (...)

=head2 Range

    score => { -between => [60, 90] }   # score BETWEEN 60 AND 90

=head2 Logical groupings

C<-or> and C<-and> take an arrayref of condition hashrefs:

    -or => [
        { status => 'active'        },
        { score  => { '>' => 95 }   },
    ]

    -and => [
        { status => 'active'        },
        { score  => { '>=' => 80 }  },
    ]

=head2 Joins

Any select method accepts a C<join> key with a hashref (or arrayref of
hashrefs) describing the join:

    join => {
        table => 'dept',
        on    => 'employees.dept_id = dept.id',
        type  => 'LEFT',    # INNER (default) | LEFT | RIGHT | FULL | CROSS
    }

    # Multiple joins
    join => [
        { table => 'dept',    on => 'e.dept_id   = dept.id'   },
        { table => 'country', on => 'e.country_id = country.id' },
    ]

=head1 SUBROUTINES/METHODS

=head2 init

Set class-level defaults shared by all instances.

    Database::Abstraction::init(directory => '../data');

Accepts the same parameters as L</new>.  Returns a reference to the
current defaults hash, so you can read them back:

    my $defaults = Database::Abstraction::init();
    print $defaults->{'directory'}, "\n";

=cut

# Subroutine to initialize with args
sub init
{
	if(my $params = Params::Get::get_params(undef, @_)) {
		if(($params->{'expires_in'} && !$params->{'cache_duration'})) {
			# Compatibility with CHI
			$params->{'cache_duration'} = $params->{'expires_in'};
		}

		%defaults = (%defaults, %{$params});
		$defaults{'cache_duration'} ||= '1 hour';
	}

	return \%defaults
}

=head2 import

The module can be initialised by the C<use> directive.

    use Database::Abstraction 'directory' => '/etc/data';

or

    use Database::Abstraction { 'directory' => '/etc/data' };

=cut

sub import
{
	my $pkg = shift;

	if((scalar(@_) == 0) && (ref($pkg) eq 'HASH')) {
		init(Object::Configure::configure(__PACKAGE__, $pkg));
	} elsif((scalar(@_) % 2) == 0) {
		my %h = @_;
		init(Object::Configure::configure($pkg, \%h));
	} elsif((scalar(@_) == 1) && (ref($_[0]) eq 'HASH')) {
		init(Object::Configure::configure($pkg, $_[0]));
	} elsif(scalar(@_) > 0) {	# >= 3 would also work here
		init(\@_);
	}
}

=head2 new

Create an object pointing to a read-only database.

Accepts arguments as a hash, a hashref, or - as a shortcut - a single bare
string which is taken to be C<directory>.

=head3 Connection parameters

=over 4

=item * C<directory>

Directory containing the data files.  The module probes this directory for
files named after the subclass (see L</FILE FORMATS>).  Required unless
C<dsn> is given.

=item * C<dsn>

A DBI data-source string (e.g. C<dbi:SQLite:dbname=/path/to/db> or
C<dbi:Pg:dbname=mydb;host=db.example.com>).  When present, file detection
is skipped entirely and the DSN is used directly.  The SQL dialect is
inferred from the DSN prefix (C<sqlite>, C<postgres>, C<mysql>).

=item * C<username>

Database username.  Used only with C<dsn>; ignored for file-based backends.

=item * C<password>

Database password.  Used only with C<dsn>; ignored for file-based backends.

=item * C<dbname>

Override the filename stem searched in C<directory> (default: the table
name derived from the class name).

=item * C<table>

Override the table (or worksheet) name used in SQL queries for this object.
Default is the class-name-derived table name (e.g. C<Database::Foo> =>
C<foo>).  Particularly useful for Excel workbooks where a single F<.xlsx>
file contains multiple worksheets: pass C<< table => 'Summary' >> to query
the C<Summary> worksheet without creating a dedicated subclass.  Also works
with SQLite/DSN connections to select a table other than the class-derived
default.  The filename stem (C<dbname>) continues to fall back to the class
name, so the correct file is opened regardless of this override.  The value
is validated against C<$SAFE_QUALIFIED> at construction time.

=item * C<filename>

Override the full filename (relative to C<directory>).  Takes precedence
over C<dbname>.

=item * C<host>

Remote hostname (or C<user@host>) from which to fetch the data file(s) via
SSH/SCP.  When present, each candidate filename is fetched with
L<File::Slurp::Remote> into a local temporary directory; the existing
extension-based file-type detection then runs against that directory.
C<directory> is treated as the remote path (no local canonicalization is
applied).  Using C<filename> together with C<host> avoids probing multiple
extensions and is therefore more efficient.  L<File::Slurp::Remote> must be
installed; it is loaded lazily (only when C<host> is given).

=item * C<url>

A URL (C<http://> or C<https://>) pointing to an HTML page that contains one
or more C<< <table> >> elements.  When present, C<directory> is not required.
The first row of the selected table is used as column headers.
Requires L<LWP::UserAgent::Cached> and L<HTML::TableExtract> (both loaded lazily).

=back

=head3 Behaviour parameters

=over 4

=item * C<no_entry>

Set to C<1> when the table has no key column (standard CSVs, for example).
Default is C<0> (keyed on C<entry>).

=item * C<id>

Name of the key column.  Default is C<entry>.

=item * C<sep_char>

Field separator for CSV/PSV files.
Default is C<!> - pass C<< sep_char => ',' >>
for standard comma-separated files.

=item * C<max_slurp_size>

Files smaller than this (in bytes) are loaded entirely into memory for fast
lookups.  Default is 16 KB.  Set to C<0> to force SQL mode for all sizes.

=item * C<no_fixate>

Set to C<1> to return mutable arrays.  Default is C<0> (arrays are made
read-only via L<Data::Reuse>).

=item * C<auto_load>

Set to C<0> to disable the AUTOLOAD column shortcut.  Default is C<1>
(enabled).

=item * C<html_table_index>

Zero-based index of the HTML C<< <table> >> to extract when the C<url>
backend is used.  Default is C<0> (the first table on the page).

=item * C<infer_types>

Set to C<1> to enable heuristic type inference in C<schema()> for
slurp-backed sources (CSV, JSON, XLSX, XML, HTML URL, DBM::Deep).
Default is C<0> (off; all columns reported as C<TEXT> for backward
compatibility).

When enabled, C<schema()> scans the first 100 rows and promotes column
types: all-integer values => C<INTEGER>; all-floating-point values =>
C<REAL>; all ISO-8601 timestamps => C<TIMESTAMP>; all ISO-8601 dates =>
C<DATE>; otherwise C<TEXT>.  C<NULL> (C<undef> or empty string) values
are skipped during the scan.

=item * C<base_criteria>

A hashref of column-value pairs that is ANDed into B<every> SELECT
automatically.  Callers do not need to repeat these criteria on each
call.  Common use cases:

=over 4

=item * Row-level security: C<< base_criteria => { tenant_id => $tid } >>

=item * Soft-delete filtering: C<< base_criteria => { deleted_at => undef } >>

=item * Status gates: C<< base_criteria => { active => 1 } >>

=back

The hashref is shallow-copied at construction time so later mutations to
the original do not affect the object.  Column names are validated
against the same identifier rules as the C<id> parameter.  C<-or> and
C<-and> groupings are allowed as keys.

B<SQL path>: the criteria are merged into the C<WHERE> clause before
the caller-supplied criteria (caller values win on key collision).

B<Slurp/in-memory path>: the criteria are applied as an additional
filter.  The C<fetchrow_hashref> entry-key fast path checks
C<base_criteria> against the returned row before returning it.

B<Query builder>: C<base_criteria> are merged into the C<WHERE> clause
generated by C<_build_sql>, so C<< $db->query->where(...)->all() >>
also respects them.

=back

=head3 Caching and logging

=over 4

=item * C<cache>

A L<CHI>-compatible cache object.  When set, query results are stored and
retrieved from the cache.

=item * C<cache_duration> / C<expires_in>

TTL for cached results.  Default is C<'1 hour'>.  C<expires_in> is a
synonym for compatibility with L<CHI>.

=item * C<logger>

An object that understands C<warn()> and C<trace()> (e.g.
L<Log::Log4perl>, L<Log::Any>), a code reference, or a filename.

=item * C<config_file>

Path to a YAML, XML, or INI configuration file whose keys are merged into
the constructor arguments.  Loaded via L<Object::Configure>.

=back

=head3 Notes

=over 4

=item *

If no arguments are set, class-level defaults set via C<init()> or C<use>
are used.

=item *

Slurp mode assumes the key column (C<entry>) is unique.  If it is not,
searches will be incomplete - disable slurp mode by setting
C<< max_slurp_size => 0 >>.

=item *

Passing an existing object as C<$class> clones it, merging any new
arguments.

=back

=cut

sub new {
	my $class = shift;
	my %args;

	Class::Abstract::check_abstract($class);	# enforces abstract contract

	# Handle hash or hashref arguments
	if((scalar(@_) == 1) && !ref($_[0])) {
		$args{'directory'} = $_[0];
	} elsif(my $params = Params::Get::get_params(undef, @_)) {
		%args = %{$params};
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using Database::Abstraction->new(), not Database::Abstraction::new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif($class eq __PACKAGE__) {
		croak("$class: abstract class");
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments.
		# Validate 'id' and 'table' before merging — the validation block below is
		# skipped by this early return, so hostile clone args would otherwise bypass
		# all guards and be interpolated directly into SQL.
		if(defined $args{'id'}) {
			croak(ref($class), ": unsafe id column name '$args{id}'")
				unless $args{'id'} =~ $SAFE_IDENTIFIER;
		}
		if(defined $args{'table'}) {
			croak(ref($class), ": unsafe table name '$args{table}'")
				unless $args{'table'} =~ $SAFE_QUALIFIED;
		}
		return bless { %{$class}, %args }, ref($class);
	}

	# Load the configuration from a config file, if provided
	%args = %{Object::Configure::configure($class, \%args)};

	# Normalise logger: wrap code-refs, filenames, and strings in Log::Abstraction
	# so that the rest of the code can always call ->$level(...) uniformly.
	if(defined $args{'logger'} && !Scalar::Util::blessed($args{'logger'})) {
		$args{'logger'} = Log::Abstraction->new($args{'logger'});
	}

	unless($args{'dsn'} || $defaults{'dsn'} || $args{'url'} || $defaults{'url'}) {
		croak("$class: where are the files?") unless($args{'directory'} || $defaults{'directory'});

		# Skip the local -d check only for genuinely remote hosts.
		# localhost / 127.0.0.1 / current hostname are treated as local.
		my $given_host = $args{'host'} // $defaults{'host'};
		unless($given_host && !$class->_is_local_host($given_host)) {
			croak("$class: ", $args{'directory'} || $defaults{'directory'}, ' is not a directory') unless(-d ($args{'directory'} || $defaults{'directory'}));
		}
	}

	# Validate the primary-key column name to prevent SQL injection via ORDER BY / WHERE
	for my $src (\%defaults, \%args) {
		if(defined $src->{'id'}) {
			croak("$class: unsafe id column name '$src->{id}'")
				unless $src->{'id'} =~ $SAFE_IDENTIFIER;
		}
		if(defined $src->{'host'}) {
			croak("$class: unsafe host '$src->{host}'")
				unless $src->{'host'} =~ /\A
					(?:                   # optional "user\@" prefix
						[a-zA-Z0-9]       # username: first char must be alnum
						[a-zA-Z0-9._-]*   # username: rest may include dots and hyphens
						\@                # literal at-sign; \@ prevents array interpolation
					)?
					[a-zA-Z0-9:]          # first char of host or IP; colon allows IPv6
					[a-zA-Z0-9._:-]*      # rest: hostname, dotted IPv4, or IPv6 hex groups
				\z/x;
		}
		if(defined $src->{'url'}) {
			croak("$class: unsafe url '$src->{url}'")
				unless $src->{'url'} =~ m{\Ahttps?://}i;
		}
		if(defined $src->{'table'}) {
			croak("$class: unsafe table name '$src->{table}'")
				unless $src->{'table'} =~ $SAFE_QUALIFIED;
		}
		if(defined $src->{'base_criteria'}) {
			my $bc = $src->{'base_criteria'};
			croak("$class: base_criteria must be a hashref")
				unless ref($bc) eq 'HASH';
			for my $k (keys %{$bc}) {
				next if $k =~ /\A-/;	# allow -or/-and groupings
				croak("$class: unsafe base_criteria key '$k'")
					unless $k =~ $SAFE_QUALIFIED;
			}
			$src->{'base_criteria'} = { %{$bc} };	# shallow copy for safety
		}
	}

	# Defaults are set first so that %args keys override them
	return bless {
		no_entry => 0,
		no_fixate => 0,
		id => 'entry',
		cache_duration => '1 hour',
		max_slurp_size => DEFAULT_MAX_SLURP_SIZE,
		%defaults,
		%args,
	}, $class;
}

=head2	set_logger

Sets the class, code reference, or file that will be used for logging.

=cut

sub set_logger
{
	my $self = shift;
	my $params = Params::Get::get_params('logger', @_);

	if(my $logger = $params->{'logger'}) {
		if(Scalar::Util::blessed($logger)) {
			$self->{'logger'} = $logger;
		} else {
			$self->{'logger'} = Log::Abstraction->new($logger);
		}
		return $self;
	}
	Carp::croak('Usage: set_logger(logger => $logger)')
}

# Open the database connection based on the specified type (e.g., SQLite, CSV).
# Read the data into memory or establish a connection to the database file.
# column_names allows the column names to be overridden on CSV files

sub _open :Protected
{
	# Enforce that _open is only reachable from within this class hierarchy;
	# caller() returns the calling package name as a plain string.
	do { my $c = (caller)[0]; Carp::croak('Illegal Operation: _open may only be called within ', __PACKAGE__) unless $c && $c->isa(__PACKAGE__) };

	my $self = shift;
	my $params = Params::Get::get_params(undef, @_);

	$params->{'sep_char'} ||= $self->{'sep_char'} ? $self->{'sep_char'} : '!';
	my $max_slurp_size = $params->{'max_slurp_size'} || $self->{'max_slurp_size'};

	my $table = $self->{'table'} || ref($self);
	$table =~ s/\A.*:://;

	$self->_trace(ref($self), ": _open $table");

	return if($self->{$table});

	# Read in the database
	my $dbh;

	# DSN-based connection bypasses file detection entirely
	if(my $dsn = $self->{'dsn'} || $defaults{'dsn'}) {
		my $dialect = 'generic';
		if    ($dsn =~ /\Adbi:SQLite:/i) { $dialect = 'sqlite'   }
		elsif ($dsn =~ /\Adbi:Pg:/i)     { $dialect = 'postgres' }
		elsif ($dsn =~ /\Adbi:mysql:/i)  { $dialect = 'mysql'    }
		$self->{'_dialect'} = $dialect;

		$dbh = DBI->connect(
			$dsn,
			$self->{'username'},
			$self->{'password'},
			{ RaiseError => 1, AutoCommit => 1 },
		) or Carp::croak(ref($self), ": cannot connect: $DBI::errstr");

		if($dialect eq 'sqlite') {
			$dbh->do('PRAGMA synchronous = OFF');
			$dbh->do('PRAGMA cache_size = -4096');
			$dbh->do('PRAGMA journal_mode = OFF');
			$dbh->do('PRAGMA temp_store = MEMORY');
			$dbh->do('PRAGMA mmap_size = 1048576');
			$dbh->sqlite_busy_timeout(100000);
		}

		$self->{'type'} = 'DBI';
		$self->{$table} = $dbh;
		$self->{'_updated'} = time();
		return $self;
	}

	# URL-based backend — handles both JSON and HTML table responses.
	# LWP::UserAgent::Cached is always required; JSON::MaybeXS and
	# HTML::TableExtract are loaded lazily based on the response Content-Type.
	if(my $url = $self->{'url'} || $defaults{'url'}) {
		require LWP::UserAgent::Cached;

		my $ua = $self->{ua} // LWP::UserAgent::Cached->new(timeout => 30, agent => __PACKAGE__ . '/' . $VERSION);
		$ua->env_proxy(1);
		my $response = $ua->get($url);
		Carp::croak(ref($self), ": cannot fetch '$url': ", $response->status_line)
			unless $response->is_success;

		my $content_type = $response->content_type() // '';
		if($content_type =~ m{\bapplication/json\b}i || $url =~ /\.json(?:[?#]|\z)/i) {
			# JSON URL backend — lazy-loads JSON::MaybeXS.
			# Detects by Content-Type: application/json or a .json URL suffix.
			require JSON::MaybeXS;
			my $parsed = JSON::MaybeXS::decode_json($response->decoded_content);
			my @data;
			if(ref($parsed) eq 'ARRAY') {
				@data = @{$parsed};
			} elsif(ref($parsed) eq 'HASH') {
				# Object keyed by primary-key value — inject id column into each row
				my $id_col = $self->{'id'};
				for my $k (sort keys %{$parsed}) {
					my $row = $parsed->{$k};
					if(ref($row) eq 'HASH') {
						push @data, { $id_col => $k, %{$row} };
					} else {
						push @data, { $id_col => $k, value => $row };
					}
				}
			} else {
				Carp::croak(ref($self), ": JSON URL: unexpected top-level structure from '$url'");
			}
			if($self->{'no_entry'}) {
				$self->{'data'} = @data ? \@data : undef;
			} else {
				$self->{'data'} = { map { $_->{$self->{'id'}} => $_ } @data };
			}
			$self->{'type'} = 'JSON';
		} else {
			# HTML table backend — lazy-loads HTML::TableExtract.
			require HTML::TableExtract;

			my $te = HTML::TableExtract->new();
			$te->parse($response->decoded_content);

			my $tidx = $self->{'html_table_index'} // $defaults{'html_table_index'} // 0;
			my @tables = $te->tables;
			Carp::croak(ref($self), ": no HTML tables found at '$url'")
				unless @tables;
			Carp::croak(ref($self), ": html_table_index $tidx out of range (", scalar @tables, " tables) at '$url'")
				if $tidx >= @tables;

			my @rows = $tables[$tidx]->rows;
			Carp::croak(ref($self), ": empty HTML table at '$url'")
				unless @rows;

			my @headers = map { defined($_) ? "$_" : '' } @{$rows[0]};
			my $id = $self->{'id'};

			if($self->{'no_entry'}) {
				my @data;
				for my $i (1 .. $#rows) {
					my %row;
					@row{@headers} = map { defined($_) ? "$_" : undef } @{$rows[$i]};
					push @data, \%row;
				}
				$self->{'data'} = \@data;
			} else {
				my %data;
				for my $i (1 .. $#rows) {
					my %row;
					@row{@headers} = map { defined($_) ? "$_" : undef } @{$rows[$i]};
					my $key = $row{$id};
					next unless defined $key;
					$data{$key} = \%row;
				}
				$self->{'data'} = \%data;
			}
			$self->{'type'} = 'HTML';
		}

		$self->{'_updated'} = time();
		$self->_fixate($self->{'data'}) if $self->{'data'} && ref($self->{'data'}) eq 'HASH';
		$self->{$table} = undef;	# No DBI handle; all queries use the in-memory data path
		return $self;
	}

	# Derive the filename stem from the class name, NOT from any $table override.
	# This allows table => 'Sheet2' to query a different worksheet within the same
	# file (e.g. test1.xlsx with a 'sheet2' worksheet) without needing an explicit
	# dbname. When dbname is set explicitly it always wins.
	my $class_stem = ref($self);
	$class_stem =~ s/\A.*:://;
	my $dbname = $self->{'dbname'} || $defaults{'dbname'} || $class_stem;
	# \A/\z (not ^/$) so a trailing newline cannot sneak past the $ anchor.
	Carp::croak(ref($self), ": unsafe dbname '$dbname'")
		unless $dbname =~ /\A[a-zA-Z0-9_.-]+\z/ && $dbname !~ /\.\./;

	# When a remote host is given, fetch all candidate files into a local temp
	# directory via File::Slurp::Remote (SSH/SCP).  localhost / 127.0.0.1 / the
	# current machine's hostname are treated as local (no SSH, no temp dir).
	my $dir;
	if(my $host = $self->{'host'} || $defaults{'host'}) {
		if($self->_is_local_host($host)) {
			$self->_debug("host '$host' is local; reading directory directly");
			my $raw_dir = $self->{'directory'} || $defaults{'directory'};
			Carp::croak(ref($self), ': no directory specified') unless $raw_dir;
			$dir = Cwd::abs_path($raw_dir);
		} else {
			require File::Slurp::Remote;
			require POSIX;
			my $remote_dir = $self->{'directory'} || $defaults{'directory'};
			my $tmpdir_obj = File::Temp->newdir(CLEANUP => 1);
			$self->{'_remote_tmpdir'} = $tmpdir_obj;	# auto-cleans on DESTROY
			my $tmpdir = $tmpdir_obj->dirname();
			my @probe_exts = qw(sql sqlite sqlite3 dbm deep db csv.gz db.gz psv tsv xls xlsx csv xml json);

			if(my $filename = $self->{'filename'} || $defaults{'filename'}) {
				# Explicit filename given — one SSH fetch, no extension probing needed.
				# Validate the same way _open() will when it processes the filename later.
				Carp::croak(ref($self), ": unsafe filename '$filename'")
					unless $filename =~ /\A[a-zA-Z0-9_.-]+\z/ && $filename !~ /\.\./;
				my $remote_file = "$remote_dir/$filename";
				my $content = eval { scalar File::Slurp::Remote::read_remote_file($host, $remote_file) };
				if(defined($content) && length($content)) {
					my $local = File::Spec->catfile($tmpdir, $filename);
					open(my $fh, '>', $local);
					binmode $fh;
					print $fh $content;
					close $fh;
					$self->_debug("fetched remote $host:$remote_file");
				}
			} else {
				# No explicit filename — probe all candidate extensions.
				# Fork one child per extension so all SSH calls run concurrently.
				# Falls back to sequential for any extension whose fork() fails.
				# Children MUST exit via POSIX::_exit(0) to skip Perl's cleanup
				# phase; a normal exit(0) would run DESTROY on the inherited
				# File::Temp::Dir, deleting the tmpdir while the parent still needs it.
				my (@pids, @fallback_exts);
				for my $ext (@probe_exts) {
					my $pid = eval { fork() };
					if(!defined $pid) {
						# fork() failed or unavailable — defer to sequential pass
						push @fallback_exts, $ext;
						next;
					}
					if($pid == 0) {
						# child: fetch one extension; eval guards against autodie croaks
						eval {
							my $remote_file = "$remote_dir/$dbname.$ext";
							my $content = File::Slurp::Remote::read_remote_file($host, $remote_file);
							if(defined($content) && length($content)) {
								my $local = File::Spec->catfile($tmpdir, "$dbname.$ext");
								open(my $fh, '>', $local);
								binmode $fh;
								print $fh $content;
								close $fh;
							}
						};
						POSIX::_exit(0);
					}
					push @pids, $pid;
				}
				waitpid($_, 0) for @pids;

				# Sequential pass for any extensions that couldn't be forked
				for my $ext (@fallback_exts) {
					my $remote_file = "$remote_dir/$dbname.$ext";
					my $content = eval { scalar File::Slurp::Remote::read_remote_file($host, $remote_file) };
					next unless defined($content) && length($content);
					my $local = File::Spec->catfile($tmpdir, "$dbname.$ext");
					open(my $fh, '>', $local);
					binmode $fh;
					print $fh $content;
					close $fh;
					$self->_debug("fetched remote $host:$remote_file");
				}
			}
			$dir = $tmpdir;
		}
	} else {
		my $raw_dir = $self->{'directory'} || $defaults{'directory'};
		Carp::croak(ref($self), ': no directory specified') unless $raw_dir;
		$dir = Cwd::abs_path($raw_dir);
	}
	# Probe for SQLite files (.sql, .sqlite, .sqlite3)
	my $slurp_file;
	for my $ext (qw(sql sqlite sqlite3)) {
		my $candidate = File::Spec->catfile($dir, "$dbname.$ext");
		if(-r $candidate) { $slurp_file = $candidate; last }
	}
	$slurp_file //= File::Spec->catfile($dir, "$dbname.sql");

	$self->_debug("_open: try to open $slurp_file");

	# Probe for DBM::Deep files (.dbm or .deep) before the CSV/BerkeleyDB fallback.
	# Loaded lazily so the DBM::Deep module is not required for other backends.
	my $deep_file;
	for my $ext (qw(dbm deep)) {
		my $candidate = File::Spec->catfile($dir, "$dbname.$ext");
		if(-r $candidate) { $deep_file = $candidate; last }
	}
	# Also detect DBM::Deep files by magic bytes (covers .db files and arbitrary extensions).
	if(!$deep_file) {
		my $db_candidate = File::Spec->catfile($dir, "$dbname.db");
		$deep_file = $db_candidate if -r $db_candidate && $self->_is_deep_db($db_candidate);
	}

	# Look at various places to find the file and derive the file type from the file's name
	if(-r $slurp_file) {
		# SQLite file
		require DBD::SQLite::Constants;
		$dbh = DBI->connect("dbi:SQLite:dbname=$slurp_file", undef, undef, {
			sqlite_open_flags => DBD::SQLite::Constants::SQLITE_OPEN_READONLY(),
		});
	}
	if($dbh) {
		$dbh->do('PRAGMA synchronous = OFF');
		$dbh->do('PRAGMA cache_size = -4096');	# Use 4MB cache - negative = KB)
		$dbh->do('PRAGMA journal_mode = OFF');	# Read-only, no journal needed
		$dbh->do('PRAGMA temp_store = MEMORY');	# Store temp data in RAM
		$dbh->do('PRAGMA mmap_size = 1048576');	# Use 1MB memory-mapped I/O
		$dbh->sqlite_busy_timeout(100000);	# 10s
		$self->_debug("read in $table from SQLite $slurp_file");
		$self->{'type'} = 'DBI';
	} elsif($deep_file) {
		# DBM::Deep file (.dbm or .deep) — slurp the entire tied hash into a plain
		# Perl hash so all existing in-memory fast-paths work without modification.
		require DBM::Deep;
		my $deep = DBM::Deep->new({ file => $deep_file, read_only => 1 });
		my $id = $self->{'id'};
		if($self->{'no_entry'}) {
			# Not keyed — produce an ordered arrayref of row hashrefs, same as CSV no_entry.
			my @data;
			for my $k (sort keys %{$deep}) {
				my $row = $deep->{$k};
				# Use reftype (not ref) so blessed DBM::Deep::Hash objects are recognised.
				# Inject the outer key as the id column so criteria on that column work.
				push @data, (Scalar::Util::reftype($row) // '') eq 'HASH'
					? { $id => $k, %{$row} }
					: { $id => $k, value => $row };
			}
			$self->{'data'} = @data ? \@data : undef;
		} else {
			# Keyed on the primary-key column (default: 'entry') for O(1) lookups.
			# Each row hash must contain the id column (like CSV rows), so that
			# selectall_arrayref and AUTOLOAD can access it by name.
			my %data;
			for my $k (keys %{$deep}) {
				my $row = $deep->{$k};
				$data{$k} = (Scalar::Util::reftype($row) // '') eq 'HASH'
					? { $id => $k, %{$row} }
					: { $id => $k, value => $row };
			}
			$self->{'data'} = %data ? \%data : undef;
		}
		$slurp_file = $deep_file;
		$self->_debug("read in $table from DBM::Deep $deep_file");
		$self->{'type'} = 'Deep';
	} elsif($self->_is_berkeley_db(File::Spec->catfile($dir, "$dbname.db"))) {
		$self->_debug("$table is a BerkeleyDB file");
		$self->{'type'} = 'BerkeleyDB';
	} else {
		my $fin;
		# File::pfopen splits $path on ':' which breaks Windows drive letters
		# (C:\foo becomes ['C', '\foo']).  Since we always have a single directory
		# we use File::Spec->catfile directly — same behaviour, portable.
		my $gz_file;
		for my $ext (qw(csv.gz db.gz)) {
			my $candidate = File::Spec->catfile($dir, "$dbname.$ext");
			next unless -r $candidate;
			open($fin, '<', $candidate);
			$gz_file = $candidate;
			last;
		}
		if($gz_file) {
			require Gzip::Faster;

			close($fin);
			$fin = File::Temp->new(SUFFIX => '.csv', UNLINK => 1, CLEANUP => 1);
			print $fin Gzip::Faster::gunzip_file($gz_file);
			$fin->flush();
			$slurp_file = $fin->filename();
			$self->{'_temp_fh'} = $fin;	# Keep object alive; auto-unlinks at DESTROY
		} else {
			my $psv = File::Spec->catfile($dir, "$dbname.psv");
			if(-r $psv) {
				open($fin, '<', $psv);
				# Pipe separated file
				$slurp_file = $psv;
				$params->{'sep_char'} = '|';
			} else {
				my $tsv = File::Spec->catfile($dir, "$dbname.tsv");
				if(-r $tsv) {
					open($fin, '<', $tsv);
					# Tab separated file
					$slurp_file = $tsv;
					$params->{'sep_char'} = "\t";
				} else {
					# CSV or BerkeleyDB-extension file
					for my $ext (qw(csv db)) {
						my $candidate = File::Spec->catfile($dir, "$dbname.$ext");
						next unless -r $candidate;
						open($fin, '<', $candidate);
						$slurp_file = $candidate;
						last;
					}
				}
			}
		}
		if(my $filename = $self->{'filename'} || $defaults{'filename'}) {
			Carp::croak(ref($self), ": unsafe filename '$filename'")
				unless $filename =~ /\A[a-zA-Z0-9_.-]+\z/ && $filename !~ /\.\./;
			$self->_debug("Looking for $filename in $dir");
			$slurp_file = File::Spec->catfile($dir, $filename);
		}
		if(defined($slurp_file) && (-r $slurp_file)) {
			close($fin) if(defined($fin));
			my $sep_char = $params->{'sep_char'};

			$self->_debug(__LINE__, ' of ', __PACKAGE__, ": slurp_file = $slurp_file, sep_char = $sep_char");

			if($params->{'column_names'}) {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef,
					{
						csv_sep_char => $sep_char,
						csv_tables => {
							$table => {
								col_names => $params->{'column_names'},
							},
						},
						f_dir      => $dir,
						RaiseError => 1,
						PrintError => 0
					}
				);
			} else {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef, { csv_sep_char => $sep_char, f_dir => $dir, RaiseError => 1 });
			}
			$dbh->{'RaiseError'} = 1;

			$self->_debug("read in $table from CSV $slurp_file");

			$dbh->{csv_tables}->{$table} = {
				allow_loose_quotes => 1,
				blank_is_undef => 1,
				empty_is_undef => 1,
				binary => 1,
				f_file => $slurp_file,
				escape_char => '\\',
				sep_char => $sep_char,
				# Don't do this, causes "Bizarre copy of HASH
				#	in scalar assignment in error_diag
				#	RT121127
				# auto_diag => 1,
				auto_diag => 0,
				# Don't do this, it causes "Attempt to free unreferenced scalar"
				# callbacks => {
					# after_parse => sub {
						# my ($csv, @rows) = @_;
						# my @rc;
						# foreach my $row(@rows) {
							# if($row->[0] !~ /^#/) {
								# push @rc, $row;
							# }
						# }
						# return @rc;
					# }
				# }
			};

			# Text::xSV::Slurp cannot override column names, so skip slurp when
			# column_names is set — the DBI CSV connection will supply names instead.
			if(((-s $slurp_file) <= $max_slurp_size) && !$params->{'column_names'}) {
				if((-s $slurp_file) == 0) {
					# Empty file — mirror what the newline-only path stores so
					# fast-path query methods return 0/undef/[] instead of falling
					# through to DBI (which croaks on a 0-column table).
					$self->{'data'} = $self->{'no_entry'} ? undef : {};
				} else {
					require Text::xSV::Slurp;

					$self->_debug('slurp in');

					my $dataref = Text::xSV::Slurp::xsv_slurp(
						shape => 'aoh',
						text_csv => {
							sep_char => $sep_char,
							allow_loose_quotes => 1,
							blank_is_undef => 1,
							empty_is_undef => 1,
							binary => 1,
							escape_char => '\\',
						},
						# string => \join('', grep(!/^\s*(#|$)/, <DATA>))
						file => $slurp_file
					);

					# Filter out blank lines and comment rows (lines starting with #)
					# Two passes replaced with one: pre-compute id column to avoid N hash
				# lookups per element, and combine both conditions into one grep.
				my $id_col = $self->{'id'};
				my @data = grep { defined($_->{$id_col}) && $_->{$id_col} !~ /\A\s*#/ } @{$dataref};

					if($self->{'no_entry'}) {
						# Not keyed on a primary column — keep as ordered list.
						# Only store a reference when rows were found; an empty-array ref
						# is truthy, which would activate the in-memory fast-path and
						# silently return 0 results instead of falling through to SQL.
						$self->{'data'} = @data ? \@data : undef;
					} else {
						# Key the hash by $self->{'id'} for O(1) entry lookups
						$self->{'data'} = { map { $_->{$self->{'id'}} => $_ } @data };
					}
				}
			}
			$self->{'type'} = 'CSV';
		} else {
			my $xls_file = File::Spec->catfile($dir, "$dbname.xls");
			if(-r $xls_file) {
				# Old binary XLS format via DBD::Excel (Spreadsheet::ParseExcel).
				# All queries go through DBI/SQL; no in-memory slurp path.
				require DBD::Excel;
				$dbh = DBI->connect("dbi:Excel:file=$xls_file", undef, undef, {
					RaiseError => 1,
					PrintError => 0,
				}) or Carp::croak(ref($self), ": can't open $xls_file: $DBI::errstr");
				$self->{'type'} = 'Excel';
				$slurp_file = $xls_file;
			} else {
			my $xlsx_file = File::Spec->catfile($dir, "$dbname.xlsx");
			if(-r $xlsx_file) {
				# Modern OOXML format via Spreadsheet::ParseXLSX — slurped into
				# an in-memory hash (keyed) or array (no_entry).  No DBI handle.
				require Spreadsheet::ParseXLSX;
				my $workbook = Spreadsheet::ParseXLSX->new()->parse($xlsx_file)
					or Carp::croak(ref($self), ": can't parse $xlsx_file");
				my ($sheet) = grep { $_->get_name() eq $table } $workbook->worksheets();
				$sheet //= ($workbook->worksheets())[0];
				Carp::croak(ref($self), ": no worksheet in $xlsx_file") unless $sheet;
				my ($row_min, $row_max) = $sheet->row_range();
				my ($col_min, $col_max) = $sheet->col_range();
				my @headers;
				for my $c ($col_min .. $col_max) {
					my $cell = $sheet->get_cell($row_min, $c);
					push @headers, $cell ? $cell->value() : "col$c";
				}
				my @data;
				for my $r ($row_min + 1 .. $row_max) {
					my %row;
					for my $c ($col_min .. $col_max) {
						my $cell = $sheet->get_cell($r, $c);
						$row{$headers[$c - $col_min]} = $cell ? $cell->value() : undef;
					}
					push @data, \%row;
				}
				if($self->{'no_entry'}) {
					$self->{'data'} = @data ? \@data : undef;
				} else {
					$self->{'data'} = { map { $_->{$self->{'id'}} => $_ } @data };
				}
				$self->{'type'} = 'XLSX';
				$slurp_file = $xlsx_file;
			} else {
				$slurp_file = File::Spec->catfile($dir, "$dbname.xml");
				if(-r $slurp_file) {
					if((-s $slurp_file) <= $max_slurp_size) {
						require XML::Simple;

						my $xml = XML::Simple::XMLin($slurp_file);
						my @keys = keys %{$xml};
						my $key = $keys[0];
						my @data;
						if(ref($xml->{$key}) eq 'ARRAY') {
							@data = @{$xml->{$key}};
						} elsif(ref($xml) eq 'ARRAY') {
							@data = @{$xml};
						} elsif((ref($xml) eq 'HASH') && !$self->{'no_entry'}) {
							if(scalar(keys %{$xml}) == 1) {
								if($xml->{$table}) {
									@data = $xml->{$table};
								} else {
									Carp::croak('XML slurp: complex documents with an "entry" field are not yet supported');
								}
							} else {
								Carp::croak('XML slurp: multi-key documents are not yet supported');
							}
						} else {
							Carp::croak('XML slurp: cannot handle ', ref($xml), ' structure');
						}
						if($self->{'no_entry'}) {
							# Not keyed, will need to scan each entry
							my $i = 0;
							foreach my $d(@data) {
								$self->{'data'}->{$i++} = $d;
							}
						} else {
							# keyed on the $self->{'id'} (default: "entry") column
							foreach my $d(@data) {
								$self->{'data'}->{$d->{$self->{'id'}}} = $d;
							}
						}
					} else {
						$dbh = DBI->connect('dbi:XMLSimple(RaiseError=>1):');
						$dbh->{'RaiseError'} = 1;
						$self->_debug("read in $table from XML $slurp_file");
						$dbh->func($table, 'XML', $slurp_file, 'xmlsimple_import');
					}
				} else {
					my $json_file = File::Spec->catfile($dir, "$dbname.json");
					if(-r $json_file) {
						if((-s $json_file) == 0) {
							$self->{'data'} = $self->{'no_entry'} ? undef : {};
						} else {
							require JSON::MaybeXS;

							open(my $jfh, '<', $json_file);
							local $/;
							my $raw = <$jfh>;
							close $jfh;
							if(!defined($raw) || $raw =~ /\A\s*\z/) {
								# Whitespace-only — treat as empty, same as zero-byte
								$self->{'data'} = $self->{'no_entry'} ? undef : {};
							} else {
								my $parsed = JSON::MaybeXS::decode_json($raw);
								my @data;
								if(ref($parsed) eq 'ARRAY') {
									@data = @{$parsed};
								} elsif(ref($parsed) eq 'HASH') {
									# Hash of id => row — inject id column into each row
									my $id_col = $self->{'id'};
									for my $k (sort keys %{$parsed}) {
										my $row = $parsed->{$k};
										if(ref($row) eq 'HASH') {
											push @data, { $id_col => $k, %{$row} };
										} else {
											push @data, { $id_col => $k, value => $row };
										}
									}
								} else {
									Carp::croak(ref($self), ": JSON slurp: unexpected top-level structure in $json_file");
								}
								if($self->{'no_entry'}) {
									$self->{'data'} = @data ? \@data : undef;
								} else {
									$self->{'data'} = { map { $_->{$self->{'id'}} => $_ } @data };
								}
							}
						}
						$slurp_file = $json_file;
						$self->_debug("read in $table from JSON $json_file");
						$self->{'type'} = 'JSON';
					} else {
					# throw Error(-file => "$dir/$table");
					$self->_fatal("Can't find a file called '$dbname' for the table $table in $dir");
					}
				}
				$self->{'type'} //= 'XML';
			}
		}	# end: xlsx else (xml path)
		}	# end: xls else
	}

	# ref() must be called on the variable, not on the result of 'eq'
	$self->_fixate($self->{'data'}) if($self->{'data'} && (ref($self->{'data'}) eq 'HASH'));

	$self->{$table} = $dbh;
	my @statb = stat($slurp_file);
	$self->{'_updated'} = $statb[9];

	return $self;
}

=head2 selectall_arrayref

Returns a reference to an array of hash references for every row that
matches the given criteria, or C<undef> when there are no matches.

    my $rows = $db->selectall_arrayref();                    # all rows
    my $rows = $db->selectall_arrayref(status => 'active');  # exact match
    my $rows = $db->selectall_arrayref(score => { '>' => 8 });  # operator

The full criteria syntax is described in L</QUERY CRITERIA>.

Pass a C<join> key to combine with another table:

    my $rows = $db->selectall_arrayref(
        dept_name => 'Engineering',
        join      => { table => 'dept', on => 'e.dept_id = dept.id' },
    );

Pass C<limit =E<gt> N> and/or C<offset =E<gt> M> for pagination:

    my $page = $db->selectall_arrayref(status => 'active', limit => 10, offset => 20);

Both values must be non-negative integers; invalid values are ignored with a
C<carp> warning.  When C<offset> is given without C<limit> the SQL backend
uses C<LIMIT -1> on SQLite (meaning "no upper bound") so the C<OFFSET> clause
is legal.

Pass C<sort_by =E<gt> 'col'> (ascending) or C<sort_by =E<gt> ['col', 'DESC']>
to request a specific sort column and direction instead of the default primary-key
ordering:

    my $rows = $db->selectall_arrayref(sort_by => 'name');
    my $rows = $db->selectall_arrayref(sort_by => ['score', 'DESC']);

The column name is validated against the same identifier rules as all other
column parameters.  An unsafe name or an unrecognised direction (anything other
than C<ASC> or C<DESC>, case-insensitive) is ignored with a C<carp> warning and
the default sort order is used instead.  Sorting is applied before
C<limit>/C<offset> pagination.

Results are returned in the cache (if configured) and the returned array
reference is made read-only unless C<no_fixate> was set.

B<Note:> this always returns all matching rows.  Use L</selectall_array>
in scalar context, or C<< $db->query->limit(1)->all() >>, to fetch just one row.

=head3 PSEUDOCODE

    1. Parse criteria; extract and build any JOIN clause.
    2. If data is slurped AND no joins AND criteria are simple:
       a. No criteria -> return all rows as arrayref.
       b. entry-only lookup -> return [$data{entry}].
       c. Otherwise -> scan rows in-memory with _match_criterion.
       In all slurp cases: sort by sort_by column (if given), then apply offset/limit.
    3. Otherwise build SQL: SELECT * FROM table [JOIN] [WHERE]
       ORDER BY sort_by [else id] [LIMIT] [OFFSET].
    4. Check cache; return cached arrayref on HIT.
    5. prepare_cached + execute; fetch all rows.
    6. Store result in cache; fixate the array; return arrayref.

=cut

sub selectall_arrayref {
	my $self = shift;

	# Fire _open() first so $self->{'berkeley'} is known before we parse @_.
	# BerkeleyDB param parsing must use get_params(undef, \@_) so that
	# key-value pairs like (join => {...}) are not mangled by the positional
	# 'entry' mapping that non-BerkeleyDB paths use.
	$self->_open_table({});

	my $params;

	if($self->{'berkeley'}) {
		$params = Params::Get::get_params(undef, \@_) // {};
		my $bl = delete $params->{'limit'};
		my $bo = delete $params->{'offset'};
		my ($bsc, $bsd) = _parse_sort_by(delete($params->{'sort_by'}), 'selectall_arrayref');
		if(defined($bl) && $bl !~ /\A\d+\z/) {
			Carp::carp('selectall_arrayref: limit must be a non-negative integer, ignoring');
			undef $bl;
		}
		if(defined($bo) && $bo !~ /\A\d+\z/) {
			Carp::carp('selectall_arrayref: offset must be a non-negative integer, ignoring');
			undef $bo;
		}
		$params = $self->_merge_base_criteria($params);
		my $rows = $self->_scan_berkeley($params);
		if(defined $bsc) {
			if($bsd eq 'DESC') {
				@{$rows} = sort { ($b->{$bsc} // '') cmp ($a->{$bsc} // '') } @{$rows};
			} else {
				@{$rows} = sort { ($a->{$bsc} // '') cmp ($b->{$bsc} // '') } @{$rows};
			}
		}
		if(defined($bl) || defined($bo)) {
			splice(@{$rows}, 0, int($bo)) if $bo;
			splice(@{$rows}, int($bl))    if defined $bl;
		}
		return set_return($rows, { type => 'arrayref' });
	}

	if($self->{'no_entry'}) {
		$params = Params::Get::get_params(undef, \@_);
	} elsif(scalar(@_)) {
		$params = Params::Get::get_params('entry', @_);
	}

	my $table = $self->_open_table($params);

	$params //= {};

	my $join_clause = '';
	if(my $join_spec = delete $params->{'join'}) {
		$join_clause = $self->_build_joins($join_spec);
	}

	my $limit  = delete $params->{'limit'};
	my $offset = delete $params->{'offset'};
	if(defined $limit) {
		if($limit !~ /\A\d+\z/) {
			Carp::carp('selectall_arrayref: limit must be a non-negative integer, ignoring');
			undef $limit;
		} else {
			$limit = int($limit);
		}
	}
	if(defined $offset) {
		if($offset !~ /\A\d+\z/) {
			Carp::carp('selectall_arrayref: offset must be a non-negative integer, ignoring');
			undef $offset;
		} else {
			$offset = int($offset);
		}
	}

	my ($sort_col, $sort_dir) = _parse_sort_by(delete($params->{'sort_by'}), 'selectall_arrayref');
	$params = $self->_merge_base_criteria($params);

	if(!$join_clause && $self->{'data'} && !$self->_has_complex_criteria($params)) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: selectall_arrayref fast track return");
			my @rc;
			if(ref($self->{'data'}) eq 'HASH') {
				$self->_debug("$table: returning ", scalar keys %{$self->{'data'}}, ' entries');
				if(scalar keys %{$self->{'data'}} <= 10) {
					$self->_debug(do { require Data::Dumper; Data::Dumper::Dumper($self->{'data'}) });
				}
				@rc = values %{$self->{'data'}};
			} else {
				@rc = @{$self->{'data'}};
			}
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return set_return(\@rc, { type => 'arrayref' });
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			# exists() guard: fixate() locks all keys in the slurp hash; return []
			# (not [undef]) when the key is missing so callers get an empty result
			return set_return([], { type => 'arrayref' })
				unless exists($self->{'data'}->{$params->{'entry'}});
			my @rc = ($self->{'data'}->{$params->{'entry'}});
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return set_return(\@rc, { type => 'arrayref' });
		} elsif(ref($self->{'data'}) eq 'HASH') {
			# Scan in-memory hash for simple column criteria without touching DBI.
			# fixate() locks hash keys, so use exists() to avoid throwing on unknown columns.
			$self->_debug("$table: selectall_arrayref in-memory scan with criteria");
			# Pre-compute param keys once — avoids re-running keys() inside the inner
			# closure on every row iteration (N hash-key extractions → 1).
			my @param_keys = keys %{$params};
			my @rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} values %{$self->{'data'}};
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return set_return(\@rc, { type => 'arrayref' });
		} elsif(ref($self->{'data'}) eq 'ARRAY' && !$self->{$table}) {
			# In-memory scan for array-backed no_entry stores (JSON, XLSX, HTML URL)
			# where there is no DBI handle.  Mirrors the equivalent path in count().
			$self->_debug("$table: selectall_arrayref in-memory array scan with criteria");
			my @param_keys = keys %{$params};
			my @rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} @{$self->{'data'}};
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return set_return(\@rc, { type => 'arrayref' });
		}
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $table";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
	if(defined $sort_col) {
		$query .= " ORDER BY $sort_col $sort_dir";
	} elsif(!$self->{'no_entry'}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}
	if(defined($limit)) {
		$query .= ' LIMIT ?';
		push @query_args, $limit;
	} elsif(defined($offset)) {
		# SQLite requires a LIMIT clause when OFFSET is present; -1 means no limit
		my $dbh = $self->{$table};
		$query .= ' LIMIT -1'
			if ($dbh && (($dbh->{Driver}{Name} // '') eq 'SQLite'))
			|| (($self->{'_dialect'} // '') eq 'sqlite');
	}
	if(defined($offset)) {
		$query .= ' OFFSET ?';
		push @query_args, $offset;
	}

	if(defined($query_args[0])) {
		$self->_debug("selectall_arrayref $query: ", join(', ', @query_args));
	} else {
		$self->_debug("selectall_arrayref $query");
	}

	my $key;
	my $c;
	if($c = $self->{cache}) {
		$key = ref($self) . "::$query array";
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		$self->_debug("cache key = '$key'");
		if(my $rc = $c->get($key)) {
			$self->_debug('cache HIT');
			return $rc;	# We stored a ref to the array

			# This use of a temporary variable is to avoid
			#	"Implicit scalar context for array in return"
			# my @rc = @{$rc};
			# return @rc;
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare_cached($query)) {
		$sth->execute(@query_args) || croak("$query: @query_args");

		my $rc;
		while(my $href = $sth->fetchrow_hashref()) {
			push @{$rc}, $href;
		}
		$c->set($key, $rc, $self->{'cache_duration'}) if $c;

		if($rc && !$self->{'no_fixate'}) {
			$self->_fixate($rc);
		}

		return $rc;
	}
	$self->_warn("selectall_arrayref failure on $query: @query_args");
	croak("$query: @query_args");
}

=head2 selectall_hashref

Deprecated alias for L</selectall_arrayref>.  Use C<selectall_arrayref> in
new code.

=cut

sub selectall_hashref
{
	my $self = shift;
	return $self->selectall_arrayref(@_);
}

=head2 each_row

    $db->each_row(\&callback);
    $db->each_row(\&callback, status => 'active');
    $db->each_row(\&callback, sort_by => 'name', limit => 100, offset => 20);

Iterates over matching rows one at a time, calling C<\&callback> once per
row with the row hashref as the sole argument.  Uses B<constant memory> on
the SQL path: rows are fetched from the database one at a time via
C<fetchrow_hashref> without materialising the full result array.  On the
slurp/in-memory path data is already in RAM, so memory use is equivalent to
L</selectall_arrayref>.

Accepts the same criteria, C<join>, C<sort_by>, C<limit>, and C<offset>
parameters as L</selectall_arrayref>.

Returns the number of rows passed to C<\&callback>.

Exceptions raised inside C<\&callback> abort iteration and propagate to
the caller; the DBI statement handle is left in a valid state (C<finish()>
is called on exception).

B<Note:> rows on the SQL path are not fixated (made read-only) because they
are discarded after each callback invocation.  Slurp-path rows are already
fixated from the initial load.

=cut

sub each_row
{
	my $self = shift;
	my $callback = shift;

	Carp::croak(ref($self), ': each_row: callback must be a code reference')
		unless ref($callback) eq 'CODE';

	$self->_open_table({});

	my $params;

	if($self->{'berkeley'}) {
		$params = Params::Get::get_params(undef, \@_) // {};
		my $bl = delete $params->{'limit'};
		my $bo = delete $params->{'offset'};
		my ($bsc, $bsd) = _parse_sort_by(delete($params->{'sort_by'}), 'each_row');
		if(defined($bl) && $bl !~ /\A\d+\z/) {
			Carp::carp('each_row: limit must be a non-negative integer, ignoring');
			undef $bl;
		}
		if(defined($bo) && $bo !~ /\A\d+\z/) {
			Carp::carp('each_row: offset must be a non-negative integer, ignoring');
			undef $bo;
		}
		$params = $self->_merge_base_criteria($params);
		my $rows = $self->_scan_berkeley($params);
		if(defined $bsc) {
			if($bsd eq 'DESC') {
				@{$rows} = sort { ($b->{$bsc} // '') cmp ($a->{$bsc} // '') } @{$rows};
			} else {
				@{$rows} = sort { ($a->{$bsc} // '') cmp ($b->{$bsc} // '') } @{$rows};
			}
		}
		if(defined($bl) || defined($bo)) {
			splice(@{$rows}, 0, int($bo)) if $bo;
			splice(@{$rows}, int($bl))    if defined $bl;
		}
		my $n = 0;
		for my $row (@{$rows}) {
			$callback->($row);
			$n++;
		}
		return $n;
	}

	if($self->{'no_entry'}) {
		$params = Params::Get::get_params(undef, \@_);
	} elsif(scalar(@_)) {
		$params = Params::Get::get_params('entry', @_);
	}

	my $table = $self->_open_table($params);

	$params //= {};

	my $join_clause = '';
	if(my $join_spec = delete $params->{'join'}) {
		$join_clause = $self->_build_joins($join_spec);
	}

	my $limit  = delete $params->{'limit'};
	my $offset = delete $params->{'offset'};
	if(defined $limit) {
		if($limit !~ /\A\d+\z/) {
			Carp::carp('each_row: limit must be a non-negative integer, ignoring');
			undef $limit;
		} else {
			$limit = int($limit);
		}
	}
	if(defined $offset) {
		if($offset !~ /\A\d+\z/) {
			Carp::carp('each_row: offset must be a non-negative integer, ignoring');
			undef $offset;
		} else {
			$offset = int($offset);
		}
	}

	my ($sort_col, $sort_dir) = _parse_sort_by(delete($params->{'sort_by'}), 'each_row');
	$params = $self->_merge_base_criteria($params);

	if(!$join_clause && $self->{'data'} && !$self->_has_complex_criteria($params)) {
		my @rc;
		if(scalar(keys %{$params}) == 0) {
			@rc = ref($self->{'data'}) eq 'HASH' ? values %{$self->{'data'}} : @{$self->{'data'}};
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			return 0 unless exists($self->{'data'}->{$params->{'entry'}});
			@rc = ($self->{'data'}->{$params->{'entry'}});
		} elsif(ref($self->{'data'}) eq 'HASH') {
			$self->_debug("$table: each_row in-memory scan with criteria");
			my @param_keys = keys %{$params};
			@rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} values %{$self->{'data'}};
		} elsif(ref($self->{'data'}) eq 'ARRAY' && !$self->{$table}) {
			$self->_debug("$table: each_row in-memory array scan with criteria");
			my @param_keys = keys %{$params};
			@rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} @{$self->{'data'}};
		}
		if(@rc) {
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
		}
		my $n = 0;
		for my $row (@rc) {
			$callback->($row);
			$n++;
		}
		return $n;
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $table";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
	if(defined $sort_col) {
		$query .= " ORDER BY $sort_col $sort_dir";
	} elsif(!$self->{'no_entry'}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}
	if(defined($limit)) {
		$query .= ' LIMIT ?';
		push @query_args, $limit;
	} elsif(defined($offset)) {
		my $dbh = $self->{$table};
		$query .= ' LIMIT -1'
			if ($dbh && (($dbh->{Driver}{Name} // '') eq 'SQLite'))
			|| (($self->{'_dialect'} // '') eq 'sqlite');
	}
	if(defined($offset)) {
		$query .= ' OFFSET ?';
		push @query_args, $offset;
	}

	if(defined($query_args[0])) {
		$self->_debug("each_row $query: ", join(', ', @query_args));
	} else {
		$self->_debug("each_row $query");
	}

	my $sth = $self->{$table}->prepare_cached($query)
		or Carp::croak(ref($self), ": each_row prepare failed: ", $self->{$table}->errstr());
	$sth->execute(@query_args) || croak("$query: @query_args");

	my $n = 0;
	eval {
		while(my $row = $sth->fetchrow_hashref()) {
			$callback->($row);
			$n++;
		}
	};
	if(my $err = $@) {
		$sth->finish();
		die $err;
	}
	return $n;
}

=head2 selectall_array

Similar to L</selectall_arrayref> but returns a list of hash references
rather than a reference to an array.

    my @rows = $db->selectall_array(status => 'active');

In B<scalar context> it applies C<LIMIT 1> and returns just the first
matching hash reference - making it more efficient than C<selectall_arrayref>
when you only need one row.  In B<list context> all matching rows are returned.

Accepts the same criteria, C<join>, C<limit>, C<offset>, and C<sort_by>
parameters as L</selectall_arrayref>.  When C<limit> is given in scalar context
it overrides the implicit C<LIMIT 1>.

=cut

sub selectall_array
{
	my $self = shift;

	$self->_open_table({});

	if($self->{'berkeley'}) {
		my $params = Params::Get::get_params(undef, \@_) // {};
		my $bl = delete $params->{'limit'};
		my $bo = delete $params->{'offset'};
		my ($bsc, $bsd) = _parse_sort_by(delete($params->{'sort_by'}), 'selectall_array');
		if(defined($bl) && $bl !~ /\A\d+\z/) {
			Carp::carp('selectall_array: limit must be a non-negative integer, ignoring');
			undef $bl;
		}
		if(defined($bo) && $bo !~ /\A\d+\z/) {
			Carp::carp('selectall_array: offset must be a non-negative integer, ignoring');
			undef $bo;
		}
		$params = $self->_merge_base_criteria($params);
		my $rows = $self->_scan_berkeley($params);
		if(defined $bsc) {
			if($bsd eq 'DESC') {
				@{$rows} = sort { ($b->{$bsc} // '') cmp ($a->{$bsc} // '') } @{$rows};
			} else {
				@{$rows} = sort { ($a->{$bsc} // '') cmp ($b->{$bsc} // '') } @{$rows};
			}
		}
		if(defined($bl) || defined($bo)) {
			splice(@{$rows}, 0, int($bo)) if $bo;
			splice(@{$rows}, int($bl))    if defined $bl;
		}
		return wantarray ? @{$rows} : $rows->[0];
	}

	my $params = Params::Get::get_params(undef, \@_);
	my $table = $self->_open_table($params);

	$params //= {};
	my $join_clause = '';
	if(my $join_spec = delete $params->{'join'}) {
		$join_clause = $self->_build_joins($join_spec);
	}

	my $limit  = delete $params->{'limit'};
	my $offset = delete $params->{'offset'};
	if(defined $limit) {
		if($limit !~ /\A\d+\z/) {
			Carp::carp('selectall_array: limit must be a non-negative integer, ignoring');
			undef $limit;
		} else {
			$limit = int($limit);
		}
	}
	if(defined $offset) {
		if($offset !~ /\A\d+\z/) {
			Carp::carp('selectall_array: offset must be a non-negative integer, ignoring');
			undef $offset;
		} else {
			$offset = int($offset);
		}
	}

	my ($sort_col, $sort_dir) = _parse_sort_by(delete($params->{'sort_by'}), 'selectall_array');
	$params = $self->_merge_base_criteria($params);

	if(!$join_clause && $self->{'data'} && !$self->_has_complex_criteria($params)) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: selectall_array fast track return");
			my @rc = ref($self->{'data'}) eq 'HASH'
				? values %{$self->{'data'}}
				: @{$self->{'data'}};
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return @rc;
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			# exists() guard: fixate() locks all keys; return empty list (not undef)
			# for a missing entry so callers in list context get 0 elements not 1
			return () unless exists($self->{'data'}->{$params->{'entry'}});
			if(defined($offset) || defined($limit)) {
				# limit/offset: build list, splice, then return context-appropriately
				my @rc = ($self->{'data'}->{$params->{'entry'}});
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
				return wantarray ? @rc : $rc[0];
			}
			# Preserve original scalar-context behaviour: return the hashref directly
			# (not the count of a 1-element list).
			return $self->{'data'}->{$params->{'entry'}};
		} elsif(ref($self->{'data'}) eq 'HASH') {
			# Same as selectall_arrayref scan but returns a list
			$self->_debug("$table: selectall_array in-memory scan with criteria");
			# Pre-compute param keys once — same optimisation as selectall_arrayref:
			# avoids N * K hash-key extractions inside the inner closure.
			my @param_keys = keys %{$params};
			my @rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} values %{$self->{'data'}};
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return @rc;
		} elsif(ref($self->{'data'}) eq 'ARRAY' && !$self->{$table}) {
			# In-memory scan for array-backed no_entry stores (JSON, XLSX, HTML URL)
			# where there is no DBI handle.  Mirrors the equivalent path in count().
			$self->_debug("$table: selectall_array in-memory array scan with criteria");
			my @param_keys = keys %{$params};
			my @rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} @{$self->{'data'}};
			if(defined $sort_col) {
				if($sort_dir eq 'DESC') {
					@rc = sort { ($b->{$sort_col} // '') cmp ($a->{$sort_col} // '') } @rc;
				} else {
					@rc = sort { ($a->{$sort_col} // '') cmp ($b->{$sort_col} // '') } @rc;
				}
			}
			if(defined($offset) || defined($limit)) {
				splice(@rc, 0, $offset) if $offset;
				splice(@rc, $limit)     if defined $limit;
			}
			return @rc;
		}
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $table";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
	if(defined $sort_col) {
		$query .= " ORDER BY $sort_col $sort_dir";
	} elsif(!$self->{'no_entry'}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}
	if(defined($limit)) {
		$query .= ' LIMIT ?';
		push @query_args, $limit;
		if(defined($offset)) {
			$query .= ' OFFSET ?';
			push @query_args, $offset;
		}
	} elsif(!wantarray) {
		if(defined($offset)) {
			$query .= ' LIMIT 1 OFFSET ?';
			push @query_args, $offset;
		} else {
			$query .= ' LIMIT 1';
		}
	} elsif(defined($offset)) {
		# List context, offset but no limit — SQLite requires LIMIT with OFFSET
		my $dbh = $self->{$table};
		$query .= ' LIMIT -1'
			if ($dbh && (($dbh->{Driver}{Name} // '') eq 'SQLite'))
			|| (($self->{'_dialect'} // '') eq 'sqlite');
		$query .= ' OFFSET ?';
		push @query_args, $offset;
	}

	if(defined($query_args[0])) {
		$self->_debug("selectall_array $query: ", join(', ', @query_args));
	} else {
		$self->_debug("selectall_array $query");
	}

	my $key;
	my $c;
	if($c = $self->{cache}) {
		$key = ref($self) . '::' . $query;
		if(wantarray) {
			$key .= ' array';
		}
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		$self->_debug("cache key = '$key'");
		if(my $rc = $c->get($key)) {
			$self->_debug('cache HIT');
			return wantarray ? @{$rc} : $rc;	# We stored a ref to the array

			# This use of a temporary variable is to avoid
			#	"Implicit scalar context for array in return"
			# my @rc = @{$rc};
			# return @rc;
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare_cached($query)) {
		$sth->execute(@query_args) || croak("$query: @query_args");

		my $rc;
		while(my $href = $sth->fetchrow_hashref()) {
			if(!wantarray) {
				# Scalar context: return just the first row; cache it too
				$sth->finish();
				$c->set($key, [$href], $self->{'cache_duration'}) if $c;
				return $href;
			}
			push @{$rc}, $href;
		}
		$c->set($key, $rc, $self->{'cache_duration'}) if $c;

		if($rc) {
			if(!$self->{'no_fixate'}) {
				$self->_fixate($rc);
			}
			return @{$rc};
		}
		return;
	}
	$self->_warn("selectall_array failure on $query: @query_args");
	croak("$query: @query_args");
}

=head2 selectall_hash

Deprecated alias for L</selectall_array>.  Use C<selectall_array> in new
code.

=cut

sub selectall_hash
{
	my $self = shift;
	return $self->selectall_array(@_);
}

=head2 count

Returns the number of rows matching the given criteria.

    my $total  = $db->count();
    my $active = $db->count(status => 'active');
    my $high   = $db->count(score  => { '>' => 90 });

Accepts the full criteria syntax described in L</QUERY CRITERIA>.

=cut

sub count
{
	my $self = shift;

	$self->_open_table({});

	if($self->{'berkeley'}) {
		my $params = Params::Get::get_params(undef, \@_) // {};
		$params = $self->_merge_base_criteria($params);
		return scalar @{$self->_scan_berkeley($params)};
	}

	my $params = Params::Get::get_params(undef, \@_);
	my $table = $self->_open_table($params);
	$params = $self->_merge_base_criteria($params // {});

	if($self->{'data'}) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: count fast track return");
			if(ref($self->{'data'}) eq 'HASH') {
				return scalar keys %{$self->{'data'}};
			}
			return scalar @{$self->{'data'}};
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			# exists() guard: fixate() locks all keys in the slurp hash
			return (exists($self->{'data'}->{$params->{'entry'}}) && $self->{'data'}->{$params->{'entry'}}) ? 1 : 0;
		} elsif(!$self->_has_complex_criteria($params) && !$self->{$table}) {
			# General in-memory scan for simple column criteria.
			# Only taken when there is no DBI handle ($self->{$table} is undef),
			# i.e. slurp-only backends like Deep.  CSV/XML/SQLite have a DBI handle
			# and must fall through to the SQL path so that column-name validation
			# fires in _build_where_conditions.
			$self->_debug("$table: count in-memory scan");
			my @param_keys = keys %{$params};
			# Pass the row list directly to grep — avoids materialising an
			# intermediate @rows array of N references on the stack.
			return scalar grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}, $_) } @param_keys
			} (ref($self->{'data'}) eq 'HASH' ? values %{$self->{'data'}} : @{$self->{'data'}});
		}
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query;
	if(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query = "SELECT COUNT(*) FROM $table WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} elsif($self->{'no_entry'}) {
		$query = "SELECT COUNT(*) FROM $table";
		$query .= " WHERE $where" if $where;
	} else {
		$query = "SELECT COUNT(" . $self->{'id'} . ") FROM $table";
		$query .= " WHERE $where" if $where;
	}

	if(defined($query_args[0])) {
		$self->_debug("count $query: ", join(', ', @query_args));
	} else {
		$self->_debug("count $query");
	}

	my $key;
	my $c;
	if($c = $self->{'cache'}) {
		# Opportunistic: if a selectall_arrayref for the same criteria is already
		# in cache, derive the count from that array rather than hitting the DB.
		# The key is built to match what selectall_arrayref would store.
		$key = ref($self) . '::' . $query;
		# [^)]+ is a negated character class: O(n) with zero backtracking.
		# The former lazy .+? could scan past the first ) in pathological SQL;
		# [^)]+ is also semantically correct (COUNT(expr) never contains ) ).
		$key =~ s/COUNT\(([^)]+)\)/$1/;
		$key .= ' array';
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		if(my $rc = $c->get($key)) {
			$self->_debug('count: cache HIT (selectall array)');
			return ref($rc) eq 'ARRAY' ? scalar @{$rc} : 0;
		}
		$self->_debug('count: cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare_cached($query)) {
		$sth->execute(@query_args) || croak("$query: @query_args");

		my $count = $sth->fetchrow_arrayref()->[0];
		$sth->finish();

		return $count;
	}
	$self->_warn("count failure on $query: @query_args");
	croak("$query: @query_args");
}

=head2 fetchrow_hashref

Returns a hash reference for the first row matching the given criteria,
or C<undef> when there is no match.  Always applies C<LIMIT 1>.

    my $row = $db->fetchrow_hashref(entry => 'key1');
    my $row = $db->fetchrow_hashref(score => { '>=' => 10 });

When C<no_entry> is B<not> set you may pass a single bare value and it is
used as the C<entry> key:

    my $row = $db->fetchrow_hashref('key1');    # same as entry => 'key1'

Accepts the full criteria syntax described in L</QUERY CRITERIA>, including
the C<join> parameter:

    my $row = $db->fetchrow_hashref(
        name => 'Alice',
        join => { table => 'dept', on => 'e.dept_id = dept.id' },
    );

Pass C<< table => $other_table >> to query a table other than the one
derived from the class name.

=cut

sub fetchrow_hashref {
	my $self = shift;

	$self->_trace('Entering fetchrow_hashref');

	my $params;

	if(!$self->{'no_entry'}) {
		$params = Params::Get::get_params('entry', @_);
	} else {
		$params = Params::Get::get_params(undef, @_);
	}

	my $table = $self->_open_table($params);

	if($self->{'data'} && (!$self->{'no_entry'}) && (scalar keys(%{$params}) == 1) && defined($params->{'entry'}) && !$self->_has_complex_criteria($params)) {
		$self->_debug('Fast return from slurped data');
		# Use exists(), fixate() locks the outer hash; accessing a missing key throws
		return undef unless exists($self->{'data'}->{$params->{'entry'}});
		my $row = $self->{'data'}->{$params->{'entry'}};
		if(my $bc = $self->{'base_criteria'}) {
			return undef unless all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $bc->{$_}, $_) } keys %{$bc};
		}
		return $row;
	}

	if($self->{'berkeley'}) {
		if((!$self->{'no_entry'}) && (scalar keys(%{$params}) == 1) && defined($params->{'entry'})) {
			return { entry => $self->{'berkeley'}->{$params->{'entry'}} };
		}
		my $id = $self->{'id'};
		if($self->{'no_entry'} && (scalar keys(%{$params}) == 1) && defined($id) && defined($params->{$id})) {
			if(my $rc = $self->{'berkeley'}->{$params->{$id}}) {
				return { $params->{$id} => $rc }	# Return key->value as a hash pair
			}
			return;
		}
		Carp::croak(ref($self), ': fetchrow_hashref is meaningless on a NoSQL database');
	}

	my $raw_target = delete $params->{'table'};
	if(defined $raw_target) {
		$raw_target =~ s/\A.*:://;
		Carp::croak(ref($self), ": unsafe table name '$raw_target'")
			unless $raw_target =~ $SAFE_QUALIFIED;
	}
	my $target = $raw_target // $table;
	my $join_spec = delete $params->{'join'};
	$params = $self->_merge_base_criteria($params);
	my $join_clause = $join_spec ? $self->_build_joins($join_spec) : '';
	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $target";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
	$query .= ' LIMIT 1';
	if(defined($query_args[0])) {
		my @call_details = caller(0);
		$self->_debug("fetchrow_hashref $query: ", join(', ', @query_args),
			' called from ', $call_details[2], ' of ', $call_details[1]);
	} else {
		$self->_debug("fetchrow_hashref $query");
	}
	# Premise: $key is only needed when a cache is configured.
	# Conclusion: assemble it lazily inside the cache block — no dead store on
	# the common (no-cache) path.
	my $c = $self->{'cache'};
	my $key;    # declared here so the second if($c) block (cache SET) can see it
	if($c) {
		$key = ref($self) . '::';
		if(defined($query_args[0])) {
			$key .= 'array ' if wantarray;
			$key .= "fetchrow $query " . join(', ', @query_args);
		} else {
			$key .= "fetchrow $query";
		}
		if(my $rc = $c->get($key)) {
			if(wantarray) {
				if(ref($rc) eq 'ARRAY') {
					return @{$rc};	# We stored a ref to the array
				}
			} else {
				return $rc;
			}
		}
	}

	my $sth = $self->{$table}->prepare_cached($query)
		or Carp::croak(ref($self), ": prepare failed: ", $self->{$table}->errstr());
	$sth->execute(@query_args) || croak("$query: @query_args");
	my $rc = $sth->fetchrow_hashref();
	$sth->finish();
	if($c) {
		if($rc) {
			$self->_debug("stash $key=>$rc in the cache for ", $self->{'cache_duration'});
			$self->_debug("returns ", do { require Data::Dumper; Data::Dumper->new([$rc])->Dump() });
		} else {
			$self->_debug("Stash $key=>undef in the cache for ", $self->{'cache_duration'});
		}
		$c->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

=head2 execute

Execute a raw SQL query on the underlying database.

    # Scalar context: returns the first row as a hashref
    my $row = $db->execute(query => 'SELECT * FROM foo WHERE id = 1');

    # List context: returns all rows as a list of hashrefs
    my @rows = $db->execute(query => 'SELECT * FROM foo WHERE score > ?',
                            args  => [80]);

The C<FROM E<lt>tableE<gt>> clause is appended automatically if omitted.

On CSV tables without C<no_entry> it may help to add
C<WHERE entry IS NOT NULL AND entry NOT LIKE '#%'> to filter comment rows.

If the data have been slurped into memory this method still hits the actual
database file directly.

C<args> is an arrayref of bind values (see L<DBI/execute>).

=cut

sub execute
{
	my $self = shift;

	if($self->{'berkeley'}) {
		Carp::croak(ref($self), ': execute is meaningless on a NoSQL database');
	}

	my $args = Params::Get::get_params('query', @_);

	# Ensure the 'query' parameter is provided
	Carp::croak(__PACKAGE__, ': Usage: execute(query => $query)')
		unless defined $args->{'query'};

	my $table = $self->_open_table($args);

	my $query = $args->{'query'};

	# Append "FROM <table>" if missing
	# \bFROM\b catches the keyword at any word boundary (space, tab, newline),
	# unlike the former \sFROM\s which missed forms like "col\tFROM" or leading FROM.
	$query .= " FROM $table" unless $query =~ /\bFROM\b/i;

	# Log the query if a logger is available
	$self->_debug("execute $query");

	# Prepare and execute the query
	my $sth = $self->{$table}->prepare_cached($query);
	# DBI->execute() takes a list; normalise args to an array whether it
	# was passed as an arrayref ([30]) or a bare scalar/list (30).
	if(exists($args->{'args'})) {
		my @bind = ref($args->{'args'}) eq 'ARRAY' ? @{$args->{'args'}} : ($args->{'args'});
		$sth->execute(@bind) or croak("$query: ", join(', ', @bind));
	} else {
		$sth->execute() or croak($query);
	}

	# Fetch the results
	my @results;
	while (my $row = $sth->fetchrow_hashref()) {
		unless(wantarray) {
			$sth->finish();
			return $row;
		}
		push @results, $row;
	}

	# Return all rows as an array in list context
	return @results;
}

=head2 updated

Returns the Unix timestamp of the last database update.

For file-based backends (CSV, XML, SQLite via C<directory>), this is the
mtime of the backing file, set at C<new()> time.

For SQLite DSN connections (C<dbi:SQLite:dbname=...>), the file path is
extracted from the DSN and C<stat()>-ed live on every call, so callers
get a current mtime suitable for cache-invalidation even when the database
was opened via a DSN rather than a C<directory>.

For all other DSN-based connections (PostgreSQL, MySQL, etc.) and for
URL-based backends, returns the Unix timestamp of the most recent
C<new()> call (connection time).

=cut

sub updated {
	my $self = shift;

	if(($self->{'_dialect'} // '') eq 'sqlite') {
		my $dsn = $self->{'dsn'};
		if(defined($dsn) && $dsn =~ /\Adbi:SQLite:(?:dbname=)?(.+)\z/i) {
			my $path = $1;
			my @st = stat($path);
			return $st[9] if @st;
		}
	}

	return $self->{'_updated'};
}

=head2 columns

Returns an array reference of column names for the current table.

    my $cols = $db->columns();    # e.g. ['entry', 'name', 'score', 'status']

Column names are always returned in alphabetical (lexicographic) order,
regardless of backend. This makes the result stable and portable when the
same logical table is backed by different engines (CSV => SQLite, etc.).

The source of column names varies by backend:

=over 4

=item * B<Slurp mode> - keys of the first row in memory.

=item * B<SQLite / other DBI> - a zero-row C<SELECT *> exposes the driver's
C<NAME> attribute.

=item * B<BerkeleyDB> - always returns C<['entry', 'value']>.

=back

The result is cached inside the object after the first call.

=cut

sub columns {
	my $self = shift;

	return $self->{'_columns'} if $self->{'_columns'};

	my $table = $self->_open_table({});

	my @cols;

	if($self->{'berkeley'}) {
		return $self->{'_columns'} = ['entry', 'value'];
	}

	if(my $data = $self->{'data'}) {
		if(ref($data) eq 'HASH') {
			my ($first) = values %{$data};
			@cols = sort keys %{$first} if $first;
		} elsif(ref($data) eq 'ARRAY' && @{$data}) {
			@cols = sort keys %{$data->[0]};
		}
	} else {
		my $sth = $self->{$table}->prepare_cached("SELECT * FROM $table WHERE 1=0");
		$sth->execute();
		@cols = sort @{$sth->{NAME}};
		$sth->finish();
	}

	return $self->{'_columns'} = \@cols;
}

=head2 schema

Returns a hash reference describing the schema of the current table.
Each key is a column name; each value is a hash reference with these keys:

=over 4

=item * C<type> - data type string (e.g. C<TEXT>, C<INTEGER>, C<REAL>)

=item * C<nullable> - C<1> if the column may be NULL, C<0> if NOT NULL

=item * C<default> - default value string, or C<undef>

=item * C<pk> - C<1> if this column is (part of) the primary key, C<0> otherwise

=back

    my $schema = $db->schema();

    for my $col (sort keys %{$schema}) {
        my $info = $schema->{$col};
        printf "%s  %s  %s\n",
            $col,
            $info->{type},
            $info->{nullable} ? 'NULL' : 'NOT NULL';
    }

The schema is determined by the backend:

=over 4

=item * B<SQLite> - C<PRAGMA table_info(table)>

=item * B<Other DBI drivers> - C<< $dbh->column_info(...) >>

=item * B<Slurp mode> - inferred from the first row; all columns typed as
C<TEXT> by default.  When C<< infer_types => 1 >> was passed to the
constructor, up to 100 rows are scanned per column and the type is
promoted: all-integer values => C<INTEGER>; all-float values =>
C<REAL>; all ISO-8601 timestamps (C<YYYY-MM-DDThh:mm>) => C<TIMESTAMP>;
all ISO-8601 dates (C<YYYY-MM-DD>) => C<DATE>; otherwise C<TEXT>.
C<undef> and empty-string values are treated as SQL C<NULL> and skipped
during the scan.

=item * B<BerkeleyDB> - always returns C<entry> (pk) and C<value>

=back

The result is cached inside the object after the first call.

=cut

sub schema {
	my $self = shift;

	return $self->{'_schema'} if $self->{'_schema'};

	my $table = $self->_open_table({});
	my %schema;

	if($self->{'berkeley'}) {
		return $self->{'_schema'} = {
			entry => { type => 'TEXT', nullable => 0, default => undef, pk => 1 },
			value => { type => 'TEXT', nullable => 1, default => undef, pk => 0 },
		};
	}

	if(my $data = $self->{'data'}) {
		my $first;
		my @sample;
		if(ref($data) eq 'HASH') {
			($first) = values %{$data};
			if($self->{'infer_types'} && $first) {
				my $n = 0;
				for my $row (values %{$data}) {
					push @sample, $row;
					last if ++$n >= INFER_TYPE_SAMPLE_SIZE;
				}
			}
		} elsif(ref($data) eq 'ARRAY' && @{$data}) {
			$first = $data->[0];
			if($self->{'infer_types'}) {
				my $last = $#{$data} < INFER_TYPE_SAMPLE_SIZE - 1 ? $#{$data} : INFER_TYPE_SAMPLE_SIZE - 1;
				@sample = @{$data}[0 .. $last];
			}
		}
		if($first) {
			my $id = $self->{'id'};
			for my $col (keys %{$first}) {
				my $type = @sample
					? _infer_type([map { exists($_->{$col}) ? $_->{$col} : undef } @sample])
					: 'TEXT';
				$schema{$col} = {
					type     => $type,
					nullable => ($col eq $id ? 0 : 1),
					default  => undef,
					pk       => ($col eq $id ? 1 : 0),
				};
			}
		}
	} else {
		my $driver = $self->{$table}->{'Driver'}{'Name'} // '';
		if($driver eq 'SQLite') {
			my $sth = $self->{$table}->prepare_cached("PRAGMA table_info($table)");
			$sth->execute();
			while(my $row = $sth->fetchrow_hashref()) {
				$schema{$row->{'name'}} = {
					type     => $row->{'type'},
					nullable => !$row->{'notnull'},
					default  => $row->{'dflt_value'},
					pk       => $row->{'pk'},
				};
			}
			$sth->finish();
		} else {
			my $sth = $self->{$table}->column_info(undef, undef, $table, '%');
			if($sth) {
				while(my $row = $sth->fetchrow_hashref()) {
					$schema{$row->{'COLUMN_NAME'}} = {
						type     => $row->{'TYPE_NAME'},
						nullable => $row->{'NULLABLE'},
						default  => $row->{'COLUMN_DEF'},
						pk       => 0,
					};
				}
				$sth->finish();
			}
		}
	}

	return $self->{'_schema'} = \%schema;
}

=head2 dbi_source

Returns a hashref C<{ dbh =E<gt> $dbh, table =E<gt> $name }> when the backend
is a live SQLite connection, or C<undef> for every other backend (slurp-mode
CSV, JSON, XLSX, HTML URL, DBM::Deep, BerkeleyDB, PostgreSQL, MySQL, ...).

The hashref is consumed by C<Database::Join> to perform a zero-copy
C<ATTACH DATABASE> so rows never pass through Perl.
Nested C<Database::Join> objects that are themselves SQLite-backed expose themselves
as attachable sources to parent joins through the same interface.

Subclasses may override this method to expose non-SQLite DBI connections
if their join layer supports them.

=head3 API SPECIFICATION

=head4 Arguments

None beyond the implicit invocant.

=head4 Returns

A hashref C<{ dbh =E<gt> DBI::db, table =E<gt> Str }> on a SQLite-backed
instance, or C<undef> on all other backends.

=cut

sub dbi_source
{
	my $self = shift;

	my $table = $self->_open_table({});
	my $dbh   = $self->{$table};

	return undef unless $dbh && ref($dbh) && (($dbh->{Driver}{Name} // '') eq 'SQLite');

	return { dbh => $dbh, table => $table };
}

=head2 query

Returns a new L<Database::Abstraction::Query> builder object bound to this
database instance, for fluent method-chaining queries.

    # All active rows with high scores, newest first, max 10
    my $rows = $db->query
        ->where(status => 'active')
        ->where(score  => { '>' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->all();

    # Single row
    my $row = $db->query->where(name => 'Alice')->first();

    # Just a count
    my $n = $db->query->where(status => 'active')->count();

See L<Database::Abstraction::Query> for the full API.

=cut

sub query
{
	my $self = shift;
	require Database::Abstraction::Query;
	return Database::Abstraction::Query->new(_db => $self);
}

=head2 AUTOLOAD - column shortcut

Calling an unknown method whose name matches a column name performs a column
lookup.  The method name is the column you want; the arguments are criteria.

    # Scalar context: return the first match
    my $name = $db->name(entry => 'key1');

    # List context: return all matching values
    my @names = $db->name();

    # Shortcut when the table has an 'entry' key column
    my $name = $db->name('key1');    # same as name(entry => 'key1')

    # Unique/distinct values
    my @statuses = $db->status(distinct => 1);

B<In list context> the full column is returned (all rows), ordered by the
column value.  B<In scalar context> only the first match is returned
(C<LIMIT 1>).

Results come from the slurp cache when available.

Throws an error if the column does not exist (slurp mode) or if AUTOLOAD
has been disabled with C<< auto_load => 0 >>.

=head3 PSEUDOCODE

    1. Extract column name from $AUTOLOAD; guard on DESTROY.
    2. Croak if auto_load => 0.
    3. Validate $column against /^[a-zA-Z_][a-zA-Z0-9_]*$/.
    4. If data is slurped:
       a. List context, no params -> map column over all rows (exists guard).
       b. entry-only param -> direct hash lookup (exists guard).
       c. No params, scalar -> first value in hash.
       d. no_entry set -> scan array for matching key/value pair.
       e. Other params -> scan keyed hash for matching column.
    5. If not slurped, build SQL:
       - List:   SELECT column FROM table [WHERE ...] ORDER BY column
       - Scalar: SELECT DISTINCT column FROM table [WHERE ...] LIMIT 1
    6. Check cache; return on HIT.
    7. prepare_cached + execute; fetch result.
    8. Store in cache; fixate; return.

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my ($column) = $AUTOLOAD =~ /::([A-Za-z_]\w*)\z/;

	return if($column eq 'DESTROY');
	return if($column =~ /\A_/);	# never treat private method names as column lookups

	my $self = shift or return;

	Carp::croak(__PACKAGE__, ": Unknown column $column") if(!ref($self));

	# Allow the AUTOLOAD feature to be disabled
	Carp::croak(__PACKAGE__, ": AUTOLOAD disabled (auto_load => 0)") if(exists($self->{'auto_load'}) && !$self->{'auto_load'});

	# Validate column name - only allow safe column name
	Carp::croak(__PACKAGE__, ": Invalid column name: $column") unless $column =~ $SAFE_IDENTIFIER;

	my $table = $self->_open_table();

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif((scalar(@_) % 2) == 0) {
		%params = @_;
	} elsif(scalar(@_) == 1) {
		# Don't error on key-value databases, since there's no idea of columns
		if($self->{'no_entry'} && !$self->{'berkeley'}) {
			Carp::croak(ref($self), "::($_[0]): ", $self->{'id'}, ' is not a column');
		}
		$params{'entry'} = shift;
	}

	if($self->{'berkeley'}) {
		if(my $id = $self->{'id'}) {
			return $self->{'berkeley'}->{$params{$id}};
		}
		return $self->{'berkeley'}->{$params{'entry'}};
	}

	croak('Where did the data come from?') if(!defined($self->{'type'}));
	my $query;
	my $done_where = 0;
	my $distinct = delete($params{'distinct'}) || delete($params{'unique'});

	if(wantarray && !$distinct) {
		if(((scalar keys %params) == 0) && (my $data = $self->{'data'})) {
			# Return all column values from the in-memory hash.
			# Use exists() because fixate() locks inner row hashes —
			# accessing a disallowed key would throw without the guard.
			# Handle both HASH (keyed data) and ARRAY (no_entry CSV slurp).
			my @_rows = ref($data) eq 'ARRAY' ? @{$data} : values %{$data};
			return map { exists($_->{$column}) ? $_->{$column} : undef } @_rows;
		}
		if($self->{'data'} && !$self->{$table} && !$self->_has_complex_criteria(\%params)) {
			# Non-DBI backends (JSON, XLSX, HTML URL): scan in-memory data with criteria.
			my @param_keys = keys %params;
			my @_rows = ref($self->{'data'}) eq 'ARRAY' ? @{$self->{'data'}} : values %{$self->{'data'}};
			return map { exists($_->{$column}) ? $_->{$column} : undef }
			       grep {
			           my $row = $_;
			           all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params{$_}, $_) } @param_keys
			       } @_rows;
		}
		my $id = $self->{'id'};
		if(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
			$query = "SELECT $column FROM $table WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT $column FROM $table";
		}
	} else {
		if(my $data = $self->{'data'}) {
			# The data has been read in using Text::xSV::Slurp,
			#	so no need to do any SQL
			$self->_debug('AUTOLOAD using slurped data');
			if($self->{'no_entry'}) {
				$self->_debug('no_entry is set');
				my ($key, $value) = %params;
				if(defined($key)) {
					$self->_debug("key = $key, value = $value, column = $column");
					foreach my $row(@{$data}) {
						# exists() guards: fixate() locks row hashes recursively
						next unless exists($row->{$key}) && defined($row->{$key}) && $row->{$key} eq $value;
						my $rc = exists($row->{$column}) ? $row->{$column} : undef;
						$self->_trace(__LINE__, ": AUTOLOAD $key: return ", defined($rc) ? "'$rc'" : 'undef', ' from slurped data');
						return $rc;
					}
					$self->_debug('not found in slurped data');
				}
			} elsif(((scalar keys %params) == 1) && defined(my $key = $params{'entry'})) {
				# Look up a single entry by its key.
				# Use exists() before accessing — fixate() locks the outer hash and
				# dereferencing a missing key on a locked hash throws an exception.
				my $rc;
				if(exists($data->{$key}) && defined(my $hash = $data->{$key})) {
					if(!exists($hash->{$column})) {
						Carp::croak(__PACKAGE__, ": There is no column $column in $table");
					}
					$rc = $hash->{$column};
				}
				if(defined($rc)) {
					$self->_trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
				} else {
					$self->_trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
				}
				return $rc
			} elsif((scalar keys %params) == 0) {
				if(wantarray) {
					if($distinct) {
						# Single pass instead of three (map→grep→map): avoids three
						# intermediate lists of size N on the stack.
						my %h;
						for my $r (values %{$data}) {
							my $v = exists($r->{$column}) ? $r->{$column} : undef;
							$h{$v} = 1 if defined $v;
						}
						return keys %h;
					}
					# DEAD CODE: unreachable because the outer `if(wantarray && !$distinct)`
					# handles the wantarray+!distinct case. In this else branch, wantarray
					# implies $distinct (which returns above), so this line is never executed.
					# return map { exists($_->{$column}) ? $_->{$column} : undef } values %{$data}
				}
				# Scalar: return the first value found without building a full list
				foreach my $v (values %{$data}) {
					return exists($v->{$column}) ? $v->{$column} : undef;
				}
			} else {
				# Keyed data but filtering on a non-key column
				my ($key, $value) = %params;
				foreach my $row (values %{$data}) {
					next unless exists($row->{$key}) && defined($row->{$key}) && $row->{$key} eq $value;
					next unless exists($row->{$column});
					if(my $rc = $row->{$column}) {
						$self->_trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
						return $rc
					}
				}
			}
			return
		}
		# Data has not been slurped in
		my $id = $self->{'id'};
		if(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
			$query = "SELECT DISTINCT $column FROM $table WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT DISTINCT $column FROM $table";
		}
	}
	my @args;
	# Avoid `each` — it carries hidden iterator state across calls
	for my $k (sort keys %params) {
		# Guard against SQL injection via column names — same rule as _build_where_conditions
		Carp::croak(__PACKAGE__, ": unsafe column name '$k'")
			unless $k =~ $SAFE_QUALIFIED;
		my $value = $params{$k};
		$self->_debug(__PACKAGE__, ": AUTOLOAD adding key/value pair $k=>", defined($value) ? $value : 'NULL');
		if(defined($value)) {
			$query .= $done_where ? " AND $k = ?" : " WHERE $k = ?";
			$done_where = 1;
			push @args, $value;
		} else {
			$query .= $done_where ? " AND $k IS NULL" : " WHERE $k IS NULL";
			$done_where = 1;
		}
	}
	if(wantarray) {
		$query .= " ORDER BY $column";
	} else {
		$query .= ' LIMIT 1';
	}
	if(scalar(@args) && $args[0]) {
		$self->_debug("AUTOLOAD $query: ", join(', ', @args));
	} else {
		$self->_debug("AUTOLOAD $query");
	}
	my $cache;
	my $key = ref($self) . '::';
	if($cache = $self->{cache}) {
		if(wantarray) {
			$key .= 'array ';
		}
		if(defined($args[0])) {
			$key .= "fetchrow $query " . join(', ', @args);
		} else {
			$key .= "fetchrow $query";
		}
		if(my $rc = $cache->get($key)) {
			$self->_debug('cache HIT');
			return wantarray ? @{$rc} : $rc;	# We stored a ref to the array
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}
	my $sth = $self->{$table}->prepare_cached($query) || croak($query);
	$sth->execute(@args) || croak($query);

	if(wantarray) {
		# fetchall_arrayref([0]) asks DBI to project column 0 server-side, so each
		# returned row is [$col0] instead of the full row — less memory, same result.
		my @rc = map { $_->[0] } @{$sth->fetchall_arrayref([0])};
		if($cache) {
			$cache->set($key, \@rc, $self->{'cache_duration'});	# Store a ref to the array
		}
		Database::Abstraction::_fixate($self, \@rc) if(scalar(@rc) && !$self->{'no_fixate'});
		return @rc;
	}
	my $rc = $sth->fetchrow_array();	# Return the first match only
	$sth->finish();
	if($cache) {
		# Store the value, then return it — cache->set() return value is unreliable
		$cache->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

sub DESTROY
{
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}

	my $self = shift;

	# Clean up temporary files — deleting File::Temp objects triggers auto-unlink/rmdir
	# If that doesn't happen for some reason, explicitly unlink
	if(defined $self->{'_temp_fh'}) {
		my $temp_fh = $self->{'_temp_fh'};
		my $temp_path = eval { $temp_fh->filename() };
		delete $self->{'_temp_fh'};
		undef $temp_fh;	# Release the local strong reference
		# Fallback explicit unlink if File::Temp didn't clean up
		unlink($temp_path) if defined($temp_path) && -f $temp_path;
	}
	delete $self->{'_remote_tmpdir'};

	# Clean up database handles
	my $table_name = $self->{'table'} || ref($self);
	$table_name =~ s/\A.*:://;

	if(my $dbh = delete $self->{$table_name}) {
		$dbh->disconnect() if $dbh->can('disconnect');
		$dbh->finish() if $dbh->can('finish');
	}

	# Clean up Berkeley DB
	if($self->{'berkeley'}) {
		eval {
			untie %{$self->{'berkeley'}};
		};
		delete $self->{'berkeley'};
	}

	# Clear all other attributes to break potential circular references
	foreach my $key (keys %$self) {
		delete $self->{$key};
	}
}

# Build the JOIN clause(s) from a single join hashref or arrayref of hashrefs.
# Each spec needs keys: table (required), on (required), type (default INNER).
sub _build_joins
{
	my ($self, $join_spec) = @_;

	my @specs = ref($join_spec) eq 'ARRAY' ? @{$join_spec} : ($join_spec);
	my @clauses;

	for my $j (@specs) {
		my $type  = uc($j->{'type'}  // 'INNER');
		my $jtable = $j->{'table'} or Carp::croak('join: missing "table"');
		Carp::croak("join: unsafe table name '$jtable'")
			unless $jtable =~ $SAFE_QUALIFIED;
		my $on     = $j->{'on'}    or Carp::croak('join: missing "on" condition');
		Carp::croak("Invalid JOIN type: $type") unless $VALID_JOIN_TYPES{$type};
		push @clauses, "$type JOIN $jtable ON ($on)";
	}

	return join(' ', @clauses);
}

# Infer a SQL type token from an arrayref of sample values for one column.
# Returns 'INTEGER', 'REAL', 'TIMESTAMP', 'DATE', or 'TEXT' (the default).
# undef and empty-string values are treated as NULL and skipped; a column
# whose entire sample is NULL is typed TEXT (most permissive safe default).
# Order of checks: INTEGER before REAL (integers also match REAL); TIMESTAMP
# before DATE (timestamps start like dates but have a time component).
sub _infer_type
{
	my ($vals) = @_;
	my @non_null = grep { defined($_) && $_ ne '' } @{$vals};
	return 'TEXT' unless @non_null;
	return 'INTEGER'   if all { $_ =~ $INFER_INT_RE  } @non_null;
	return 'REAL'      if all { $_ =~ $INFER_REAL_RE } @non_null;
	return 'TIMESTAMP' if all { $_ =~ $INFER_TS_RE   } @non_null;
	return 'DATE'      if all { $_ =~ $INFER_DATE_RE } @non_null;
	return 'TEXT';
}

# Merge $self->{'base_criteria'} into a caller-supplied $params hashref.
# Returns a new hashref with base_criteria keys added; caller keys WIN on collision
# so callers can always further restrict.  Returns $params unchanged when no
# base_criteria is set, avoiding an extra allocation on the common code path.
sub _merge_base_criteria :Private {
	my ($self, $params) = @_;
	my $bc = $self->{'base_criteria'};
	return $params unless $bc;
	return { %{$bc}, %{$params} };
}

# Parse a sort_by parameter value into ($col, $dir).
# Accepts: scalar column name (ASC), or [$col, $dir] arrayref.
# Validates column against $SAFE_QUALIFIED and direction as ASC/DESC.
# Carps and returns (undef, 'ASC') on invalid input so callers fall back
# to the default id-column sort.
sub _parse_sort_by
{
	my ($sb, $method) = @_;
	return (undef, 'ASC') unless defined $sb;
	my ($col, $dir) = ref($sb) eq 'ARRAY' ? @{$sb}[0, 1] : ($sb, undef);
	$dir = defined($dir) ? uc($dir) : 'ASC';
	unless(defined($col) && $col =~ $SAFE_QUALIFIED) {
		Carp::carp("$method: unsafe sort_by column, ignoring");
		return (undef, 'ASC');
	}
	unless($dir eq 'ASC' || $dir eq 'DESC') {
		Carp::carp("$method: invalid sort_by direction '$dir', ignoring");
		return (undef, 'ASC');
	}
	return ($col, $dir);
}

# Return true when $params contains operator hashrefs, -or, or -and groupings
# that the simple slurp fast-path cannot handle.
sub _has_complex_criteria
{
	my ($self, $params) = @_;
	return 0 unless defined $params;
	# -or / -and keys short-circuit immediately: no value scan needed.
	return 1 if exists $params->{'-or'} || exists $params->{'-and'};
	# LOGICAL INVARIANT: when this returns false, NO value in %$params is a
	# reference.  This is the Boolean gate that makes _match_criterion's
	# hashref branch provably unreachable from the public select API:
	#   Premise A — in-memory scan path requires: !_has_complex_criteria(params)
	#   Premise B — _has_complex_criteria returns true if any value is a ref
	#   Conclusion — inside the in-memory scan, every crit_val is a scalar/undef
	# any() short-circuits on the first truthy element; the for-loop equivalent
	# would iterate through all values before returning false in the common case.
	return (any { ref($_) } values %{$params}) ? 1 : 0;
}

# Build the WHERE clause body (everything after "WHERE") from a criteria hash.
# Handles -or / -and groupings then delegates per-column work to _build_where_conditions.
# Returns ($sql_fragment, \@bind_values).
# Wrapper around Data::Reuse::fixate() that suppresses the spurious
# "Use of uninitialized value in hash slice" warning.  Data::Alias's XS
# hash-aliasing code does not fully initialise key SVs on older Perl
# versions when the source hash contains undef values (NULL columns).
# Data::Reuse still fixates correctly; the warning is a false positive.
# $struct must be the hashref or arrayref to fixate.
sub _fixate :Private
{
	my (undef, $struct) = @_;
	return unless defined $struct;
	# Clear stale address→canonical mappings from prior fixate calls before
	# fixating $struct.  Without this, freed hashref addresses from a previous
	# object's slurp or DBI result can be reused by the allocator for new
	# hashrefs; fixate() would then find the stale entry and alias the new
	# hashref to the wrong canonical, silently substituting one row's data for
	# another.  This is the same stale-address hazard that affects DBI paths
	# (see selectall_arrayref / selectall_array) but also affects the slurp
	# fixate when earlier objects go out of scope before a new slurp runs.
	Data::Reuse::forget();
	local $SIG{__WARN__} = sub {
		# Two index() calls replace the former /.*\b/ — no backtracking at all.
		# The prefix check is constant-time; the suffix scan is O(n) but stops
		# at the first match rather than first matching greedily then retreating.
		warn @_ unless
			index($_[0], 'Use of uninitialized value') == 0
			&& index($_[0], 'in hash slice') >= 0;
	};
	&Data::Reuse::fixate($struct);
}

sub _build_where
{
	my ($self, $params) = @_;

	$params //= {};
	my @clauses;
	my @args;

	# Avoid an O(K) hash copy in the common case where neither -or nor -and is
	# present.  Only copy when we actually need to delete grouping keys, so the
	# plain-criteria path (the vast majority of queries) passes $params through
	# directly to _build_where_conditions without any allocation.
	my $or_list  = $params->{'-or'};
	my $and_list = $params->{'-and'};
	my $plain;
	if(defined($or_list) || defined($and_list)) {
		my %p = %{$params};
		delete @p{qw(-or -and)};
		$plain = \%p;
	} else {
		$plain = $params;
	}

	if($or_list) {
		my (@sub_clauses, @sub_args);
		for my $cond (@{$or_list}) {
			my ($s, $a) = $self->_build_where_conditions($cond);
			if($s) {
				push @sub_clauses, "($s)";
				push @sub_args, @{$a};
			}
		}
		if(@sub_clauses) {
			push @clauses, '(' . join(' OR ', @sub_clauses) . ')';
			push @args, @sub_args;
		}
	}
	if($and_list) {
		my (@sub_clauses, @sub_args);
		for my $cond (@{$and_list}) {
			my ($s, $a) = $self->_build_where_conditions($cond);
			if($s) {
				push @sub_clauses, "($s)";
				push @sub_args, @{$a};
			}
		}
		if(@sub_clauses) {
			push @clauses, '(' . join(' AND ', @sub_clauses) . ')';
			push @args, @sub_args;
		}
	}

	my ($more, $margs) = $self->_build_where_conditions($plain);
	if($more) {
		push @clauses, $more;
		push @args, @{$margs};
	}

	return (join(' AND ', @clauses), \@args);
}

# Build a WHERE-body fragment for a flat col => val hash.
# Values may be plain scalars (= / LIKE / IS NULL) or operator hashrefs
# ({ '>' => n }, { -in => [...] }, { -between => [lo,hi] }, etc.).
sub _build_where_conditions
{
	my ($self, $params) = @_;

	my @clauses;
	my @args;

	for my $col (sort keys %{$params}) {
		my $val = $params->{$col};

		# Guard against SQL injection via column names; allow table.column notation for JOINs
		Carp::croak("_build_where_conditions: unsafe column name '$col'")
			unless $col =~ $SAFE_QUALIFIED;

		if(ref($val) eq 'HASH') {
			for my $op (keys %{$val}) {    # no sort — operator hashes typically have 1-2 keys; sort adds O(K log K) overhead
				my $operand = $val->{$op};
				if($op eq '-in' || $op eq '-not_in') {
					my $sql_op = $op eq '-in' ? 'IN' : 'NOT IN';
					my $ph = join(', ', ('?') x scalar(@{$operand}));
					push @clauses, "$col $sql_op ($ph)";
					push @args, @{$operand};
				} elsif($op eq '-between') {
					push @clauses, "$col BETWEEN ? AND ?";
					push @args, $operand->[0], $operand->[1];
				} elsif($op eq '-like') {
					push @clauses, "$col LIKE ?";
					push @args, $operand;
				} elsif($op eq '-not_like') {
					push @clauses, "$col NOT LIKE ?";
					push @args, $operand;
				} elsif($op eq '!=') {
					if(!defined($operand)) {
						push @clauses, "$col IS NOT NULL";
					} else {
						push @clauses, "$col != ?";
						push @args, $operand;
					}
				# [<>]=? matches >, <, >=, <= as a single character class — no alternation
				# overhead, no backtracking, and self-documenting.
				} elsif($op =~ /\A[<>]=?\z/) {
					push @clauses, "$col $op ?";
					push @args, $operand;
				} else {
					Carp::croak("Unknown operator '$op' for column '$col'");
				}
			}
		} elsif(ref($val)) {
			Carp::croak("$col: expected scalar or operator hashref, got ", ref($val));
		} elsif(!defined($val)) {
			push @clauses, "$col IS NULL";
		} elsif($val =~ /[%_]/) {
			push @clauses, "$col LIKE ?";
			push @args, $val;
		} else {
			push @clauses, "$col = ?";
			push @args, $val;
		}
	}

	return (join(' AND ', @clauses), \@args);
}

# Test a single in-memory row value against a criteria value.
# $crit_val may be a plain scalar or an operator hashref.
# Returns true when the row value satisfies the criterion.
# Scan the entire BerkeleyDB tied hash, building rows as {entry=>$k, value=>$v},
# and filter by $params criteria using _match_criterion.
# Croaks when JOINs or -or/-and groupings are requested (unsupported for key-value stores).
sub _scan_berkeley
{
	my ($self, $params) = @_;
	$params //= {};

	# TODO: Data Flow Anomaly - Mutation side effect: delete mutates the caller's
	# $params hashref in-place.  All current callers (selectall_arrayref,
	# selectall_array, count) do not reuse $params after this call, so it is safe;
	# but a future caller that reuses $params would silently lose the 'join' key.
	# Fix: use exists($params->{'join'}) to check; copy params before deleting.
	if(delete $params->{'join'}) {
		Carp::croak(ref($self), ': BerkeleyDB does not support JOINs');
	}
	# any() short-circuits: once the first -or/-and key is found the croak fires
	# without scanning the remaining keys — O(1) best case vs O(K) for grep.
	if(any { $_ eq '-or' || $_ eq '-and' } keys %{$params}) {
		Carp::croak(ref($self), ': BerkeleyDB does not support -or/-and groupings');
	}

	my $bdb = $self->{'berkeley'};
	my @cols = keys %{$params};
	my @rows;

	if(@cols) {
		# Single-pass build+filter: avoids materialising the full N-row list
		# before filtering.  Peak memory is O(matching rows) instead of O(N).
		for my $k (keys %{$bdb}) {
			my $row = { entry => $k, value => $bdb->{$k} };
			my $match = 1;
			for my $col (@cols) {
				unless($self->_match_criterion($row->{$col}, $params->{$col}, $col)) {
					$match = 0;
					last;
				}
			}
			push @rows, $row if $match;
		}
	} else {
		@rows = map { { entry => $_, value => $bdb->{$_} } } keys %{$bdb};
	}

	return \@rows;
}

# SQL LIKE match — case-insensitive, ReDoS-safe, no catastrophic backtracking.
# % matches any sequence of chars; _ matches exactly one char.
#
# Fast paths cover the four most common LIKE shapes using O(1) string ops:
#   '%'        → always true
#   no wildcard → lc eq comparison
#   '%suffix'  → ends-with check via substr
#   'prefix%'  → starts-with check via index
#   '%mid%'    → contains check via index  (single inner literal, no _ wildcards)
#
# Full DP uses O(m) memory (two 1-D rolling arrays) instead of the O(m*n) 2-D
# table the naive approach allocates.  Character access uses substr() instead of
# split(//) so no per-character scalar objects are created.
sub _like_match
{
	my ($str, $pattern) = @_;

	# Fast path 1: bare '%' — matches any string regardless of content.
	return 1 if $pattern eq '%';

	my $lc_str = lc($str);
	my $lc_pat = lc($pattern);
	my $pat_len = length($lc_pat);
	my $str_len = length($lc_str);

	# Fast path 2: no wildcard characters — plain case-insensitive equality.
	return ($lc_str eq $lc_pat)
		if index($lc_pat, '%') == -1 && index($lc_pat, '_') == -1;

	# Fast paths 3-5 apply only when the pattern has no '_' wildcards.
	# (Patterns with '_' need per-character DP to enforce the single-char rule.)
	if(index($lc_pat, '_') == -1) {
		my $first_pct = index($lc_pat, '%');
		my $last_pct  = rindex($lc_pat, '%');

		# Fast path 3: '%suffix' — exactly one '%', at the start.
		if($first_pct == 0 && $last_pct == 0) {
			my $sfx = substr($lc_pat, 1);
			my $sfx_len = length($sfx);
			return $str_len >= $sfx_len
				&& substr($lc_str, $str_len - $sfx_len) eq $sfx;
		}

		# Fast path 4: 'prefix%' — exactly one '%', at the end.
		if($last_pct == $pat_len - 1 && $first_pct == $pat_len - 1) {
			my $pfx = substr($lc_pat, 0, $pat_len - 1);
			return index($lc_str, $pfx) == 0;
		}

		# Fast path 5: '%literal%' — '%' at both ends, no inner '%'.
		# pat_len >= 3 ensures there are two distinct '%' characters.
		# Only return here when the middle segment is free of further wildcards;
		# if it contains '%' (e.g. '%a%b%'), fall through to the full DP.
		if($first_pct == 0 && $last_pct == $pat_len - 1 && $pat_len >= 3) {
			my $needle = substr($lc_pat, 1, $pat_len - 2);
			if(index($needle, '%') == -1) {
				return index($lc_str, $needle) >= 0;
			}
		}
	}

	# Full DP — O(m*n) time, O(m) memory.
	# Two 1-D arrayrefs (@$prev, @$curr) replace the O(m*n) 2-D table.
	# substr() replaces split(//) — no per-char scalar allocation.
	# Ref-swap ($prev,$curr) = ($curr,$prev) at the end of each outer iteration
	# avoids the O(m) array copy that "@prev = @curr" would perform.
	my $m = $str_len;
	my $n = $pat_len;

	my ($prev, $curr) = ([1, (0) x $m], [(0) x ($m + 1)]);

	for my $i (1 .. $n) {
		@{$curr} = (0) x ($m + 1);    # zero in-place — reuses existing allocation
		my $pc = substr($lc_pat, $i - 1, 1);
		if($pc eq '%') {
			$curr->[0] = $prev->[0];
			for my $j (1 .. $m) {
				$curr->[$j] = ($prev->[$j] || $curr->[$j - 1]) ? 1 : 0;
			}
		} else {
			for my $j (1 .. $m) {
				$curr->[$j] = ($prev->[$j - 1]
					&& ($pc eq '_' || $pc eq substr($lc_str, $j - 1, 1))) ? 1 : 0;
			}
		}
		($prev, $curr) = ($curr, $prev);    # O(1) ref swap — no array copy
	}
	return $prev->[$m];
}

sub _match_criterion
{
	my ($self, $row_val, $crit_val, $col) = @_;

	# Use numeric equality/membership operators when the schema (if already
	# cached) reports the column as INTEGER or REAL.  The numeric ordering
	# operators (>, <, >=, <=, -between) already use Perl's numeric context
	# regardless; only equality-family operators need the type-aware path.
	my $numeric = ($col && $self->{'_schema'})
		? do { my $t = ($self->{'_schema'}{$col} // {})->{'type'} // 'TEXT';
		       $t eq 'INTEGER' || $t eq 'REAL' }
		: 0;

	if(ref($crit_val) eq 'HASH') {
		for my $op (keys %{$crit_val}) {
			my $operand = $crit_val->{$op};
			if($op eq '-in') {
				return 0 unless defined($row_val)
					&& ($numeric
						? grep { $row_val == $_ } @{$operand}
						: grep { $row_val eq $_ } @{$operand});
			} elsif($op eq '-not_in') {
				return 0 if defined($row_val)
					&& ($numeric
						? grep { $row_val == $_ } @{$operand}
						: grep { $row_val eq $_ } @{$operand});
			} elsif($op eq '-between') {
				return 0 unless defined($row_val) && $row_val >= $operand->[0] && $row_val <= $operand->[1];
			} elsif($op eq '-like') {
				return 0 unless defined($row_val);
				return 0 unless _like_match($row_val, $operand);
			} elsif($op eq '-not_like') {
				return 0 unless defined($row_val);
				return 0 if _like_match($row_val, $operand);
			} elsif($op eq '!=') {
				if(!defined($operand)) {
					return 0 unless defined($row_val);
				} elsif($numeric) {
					return 0 unless defined($row_val) && $row_val != $operand;
				} else {
					return 0 unless defined($row_val) && $row_val ne $operand;
				}
			} elsif($op eq '>') {
				return 0 unless defined($row_val) && $row_val > $operand;
			} elsif($op eq '<') {
				return 0 unless defined($row_val) && $row_val < $operand;
			} elsif($op eq '>=') {
				return 0 unless defined($row_val) && $row_val >= $operand;
			} elsif($op eq '<=') {
				return 0 unless defined($row_val) && $row_val <= $operand;
			}
		}
		return 1;
	}

	return !defined($row_val) && !defined($crit_val) ? 1
		: !defined($row_val) || !defined($crit_val) ? 0
		: $numeric ? $row_val == $crit_val
		: $row_val eq $crit_val;
}

# Determine the table and open the database
sub _open_table
{
	my($self, $params) = @_;

	# Derive the table name, caching the result in '_table_name' for the common
	# case of no caller-supplied 'table' override.  Avoids repeating ref()+regex
	# on every query when the same object makes many calls.
	my $table;
	if($params->{'table'}) {
		($table = $params->{'table'}) =~ s/\A.*:://;
		Carp::croak(ref($self), ": unsafe table name '$table'")
			unless $table =~ $SAFE_QUALIFIED;
	} else {
		$table = $self->{'_table_name'} //= do {
			my $t = $self->{'table'} || ref($self);
			$t =~ s/\A.*:://;
			$t;
		};
	}

	# Open a connection if it's not already open.
	# BerkeleyDB never sets $self->{$table} (no DBI handle) or $self->{'data'},
	# so we also guard on $self->{'berkeley'} to avoid re-tying on every call.
	$self->_open() if(!$self->{$table} && !$self->{'data'} && !$self->{'berkeley'});

	return $table;
}

# Quote a SQL identifier using the current connection's dialect rules.
# Falls back to ANSI double-quoting when no connection is available.
sub _quote_identifier
{
	my ($self, $name) = @_;

	my $table = $self->{'table'} || ref($self);
	$table =~ s/\A.*:://;
	if(my $dbh = $self->{$table}) {
		return $dbh->quote_identifier($name);
	}
	return qq{"$name"};
}

# Determine whether a given file is a valid Berkeley DB file.
# It combines a fast preliminary check with a more thorough validation step for accuracy.
# It looks for the magic number at both byte 0 and byte 12.
sub _is_berkeley_db {
	my ($self, $file) = @_;

	# Step 1: Check magic number
	# no autodie here: the file may not exist, and we want a silent false return
	my $fh;
	do { no autodie qw(open); open $fh, '<', $file } or return 0;
	binmode $fh;

	my $is_db = $self->_has_bdb_magic($fh);
	close $fh;

	if($is_db) {
		# Step 2: Attempt to open as Berkeley DB

		require DB_File;

		my %bdb;
		if(tie %bdb, 'DB_File', $file, O_RDONLY, 0644, $DB_File::DB_HASH) {
			# untie %db;
			$self->{'berkeley'} = \%bdb;
			return 1;	# Successfully identified as a Berkeley DB file
		}
	}
	return 0;
}

# Check for Berkeley DB magic bytes at offsets 0 and 12.
# Returns true if either location contains a recognised BDB magic number.
sub _has_bdb_magic {
	my ($self, $fh) = @_;

	# Offset 0: 32-bit magic number in both endian forms
	read($fh, my $buf, 4) == 4 or return 0;
	my %magic = map { $_ => 1 } (0x00061561, 0x00053162, 0x00042253, 0x00052444);
	return 1 if $magic{unpack('N', $buf)} || $magic{unpack('V', $buf)};

	# Offset 12: Btree magic prefix (fallback for some BDB file variants)
	seek $fh, 12, 0 or return 0;
	read($fh, $buf, 4) or return 0;
	my $hex12 = substr(unpack('H*', $buf), 0, 4);
	return($hex12 eq '6115' || $hex12 eq '1561');
}

# Return true if $host refers to the current machine (localhost, loopback, or
# the machine's own hostname).  Strips an optional user@ prefix first.
# Used by new() and _open() to decide whether to use local file access instead
# of File::Slurp::Remote, so the caller never loads that module unnecessarily.
sub _is_local_host {
	my ($self, $host) = @_;

	# Strip optional user@ prefix.  \A (not ^) so a newline cannot split the match.
	(my $bare = $host) =~ s/\A[^@]*@//;

	# \z anchors at true end-of-string; $ would match before a trailing newline.
	return 1 if $bare =~ /\A(?:localhost|127\.0\.0\.1|::1)\z/i;

	require Sys::Hostname;
	my $me = lc(Sys::Hostname::hostname());
	my $lc_bare = lc($bare);
	return 1 if $lc_bare eq $me;

	# Match on short hostname: 'mybox' matches 'mybox.example.com' and vice-versa
	(my $me_short   = $me)      =~ s/\..*//;
	(my $bare_short = $lc_bare) =~ s/\..*//;
	return($bare_short eq $me_short);
}

# Determine whether a given file is a DBM::Deep file by checking its magic bytes.
# The standard DBM::Deep magic is 'DPDB' (0x44 0x50 0x44 0x42); 'DPDP' (0x44 0x50 0x44 0x50)
# is also accepted for compatibility with files created by alternative tooling.
# Returns 1 if the first 4 bytes match a known DBM::Deep signature, 0 otherwise.
sub _is_deep_db {
	my ($self, $file) = @_;

	my $fh;
	do { no autodie qw(open); open $fh, '<', $file } or return 0;
	binmode $fh;
	my $n = read($fh, my $magic, 4);
	close $fh;
	return 0 unless defined($n) && $n == 4;

	return($magic eq 'DPDB' || $magic eq 'DPDP');
}

# Log and remember a message
sub _log
{
	my ($self, $level, @messages) = @_;

	# FIXME: add caller's function
	# if(($level eq 'warn') || ($level eq 'notice')) {
		push @{$self->{'messages'}}, { level => $level, message => join('', grep defined, @messages) };
	# }

	if(scalar(@messages) && (my $logger = $self->{'logger'})) {
		$self->{'logger'}->$level(join('', grep defined, @messages));
	}
}

sub _debug {
	my $self = shift;
	$self->_log('debug', @_);
}

sub _trace {
	my $self = shift;
	$self->_log('trace', @_);
}

# Emit a warning message somewhere
sub _warn {
	my $self = shift;
	my $params = Params::Get::get_params('warning', \@_);

	$self->_log('warn', $params->{'warning'});
	Carp::carp(join('', grep defined, $params->{'warning'}));
}

# Die
sub _fatal {
	my $self = shift;
	my $params = Params::Get::get_params('warning', \@_);

	$self->_log('error', $params->{'warning'});
	Carp::croak(join('', grep defined, $params->{'warning'}));
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-database-abstraction at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 MESSAGES

The table below lists every error that the module can croak or carp, what
triggers it, and how to resolve it.

=over 4

=item C<< I<Class>: abstract class >>

Direct instantiation of C<Database::Abstraction> was attempted.
Create a subclass and instantiate that instead.

=item C<< I<Class>: where are the files? >>

Neither C<directory> nor C<dsn> was supplied to C<new()>.

=item C<< I<Class>: I</path> is not a directory >>

The C<directory> argument exists on disk but is not a directory.

=item C<< I<Class>: cannot connect: I<$DBI::errstr> >>

DBI failed to connect to the given C<dsn>.  Check credentials and host.

=item C<< Can't find a file called 'I<name>' for the table I<T> in I<dir> >>

None of the probe extensions (C<.sql>, C<.sqlite>, C<.sqlite3>, C<.psv>, C<.tsv>, C<.csv>, C<.xlsx>, C<.db>, C<.xml>)
matched in C<directory>.

=item C<< I<Class>: prepare failed: I<$errstr> >>

C<prepare_cached()> returned false.  Usually a syntax error in an internally
built query; file a bug if you see this from a normal API call.

=item C<< _build_where_conditions: unsafe column name 'I<name>' >>

A criteria key contained characters outside C<[A-Za-z0-9_.]>.
This is a SQL-injection guard.  Use only valid SQL identifier characters.

=item C<< join: missing "table" >> / C<< join: missing "on" condition >>

A join spec hashref is incomplete.  Both C<table> and C<on> are required.

=item C<< Invalid JOIN type: I<TYPE> >>

C<type> in a join spec was not one of C<INNER LEFT RIGHT FULL CROSS>.

=item C<< I<Class>: Unknown column I<col> >> / C<< I<Class>: AUTOLOAD disabled >>

An AUTOLOAD call was made for a column that does not exist, or AUTOLOAD
was disabled with C<< auto_load => 0 >>.

=item C<< Usage: set_logger(logger => $logger) >>

C<set_logger()> was called without a C<logger> argument.

=item C<< Usage: execute(query => $query) >>

C<execute()> was called without a C<query> argument.

=item C<< XML slurp: I<...> is not yet supported >>

The XML file structure is too complex for slurp mode.
Use C<< max_slurp_size => 0 >> to force the DBI/XMLSimple SQL path.

=item C<< I<Class>: I<method> is meaningless on a NoSQL database >>

A relational method (C<selectall_arrayref>, C<count>, C<execute>, etc.)
was called on a BerkeleyDB backend, which only supports key-value lookup
via C<fetchrow_hashref>.

=back

=head1 KNOWN LIMITATIONS

=over 4

=item *

B<Read-only.>  No INSERT, UPDATE, or DELETE is provided.  C<execute()>
runs raw read-only SQL.

=item *

B<Default CSV separator is C<!>>, not C<,>, for historical reasons.
Pass C<< sep_char => ',' >> for standard RFC 4180 files.

=item *

B<Primary-key column is named C<entry>>, not C<key>, because C<key>
is a SQL reserved word.  Override with the C<id> parameter.

=item *

B<XML slurp is limited.>  Only simple flat XML structures are supported
in slurp mode.  Multi-key or deeply nested documents will croak.
Force SQL mode with C<< max_slurp_size => 0 >> if slurp fails.

=item *

B<Unique key assumption in slurp mode.>  Duplicate values in the key
column silently overwrite earlier rows.  Disable slurp with
C<< max_slurp_size => 0 >> if duplicates are expected.

=item *

B<BerkeleyDB does not support joins or the chained query builder.>

=item *

B<Column names must be valid SQL identifiers> (letters, digits,
underscores, and a single dot for C<table.column> join notation).
Other characters will cause a croak.

=item *

B<count() cache is opportunistic.>  Count results are served from cache
only when a prior C<selectall_arrayref()> or C<count()> call with the
same criteria has already populated it.

=back

=head1 SEE ALSO

=over 4

=item * L<Database::Abstraction::Query> - chained query builder

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<JSON::MaybeXS> - JSON backend (optional; install for C<.json> support)

=item * L<Test Dashboard|https://nigelhorne.github.io/Database-Abstraction/coverage/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
