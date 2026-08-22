package Database::Join;

# ABSTRACT: Combined view across two or more Database::Abstraction objects

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use List::Util qw(max);
use Readonly;
use Scalar::Util qw(blessed);
use Object::Configure;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Sub::Protected;

# Named-pair keys accepted by add_database; kept here so the guard and the
# validate_strict schema cannot silently diverge.
Readonly::Array my @_ADD_DB_KEYS => qw(database join_column filter remove_columns);

our $VERSION = '0.001.0';

# ---------------------------------------------------------------------------
# All user-facing strings route through this dictionary.  Supply an i18n
# object with a translate($key, @sprintf_args) method to localise them.
# ---------------------------------------------------------------------------
Readonly::Hash my %MESSAGES => (
	error_no_databases	=> 'At least one Database::Abstraction object is required',
	error_invalid_db	=> 'databases[%d] is not a Database::Abstraction object',
	error_join_col_missing	=> 'join_column "%s" is absent from databases[%d] (%s)',
	error_col_conflict	=> 'Column "%s" exists in multiple databases; use the owning database directly or rename the column',
	error_remove_join_col	=> 'Cannot remove join_column "%s"; it is required for the join',
	warn_unknown_column	=> 'Column "%s" is not present in any configured database; criterion ignored',
	error_query_unsupported	=> 'query() chained builder is not supported on Database::Join; call selectall_arrayref / fetchrow_hashref directly',
	error_execute_unsupported => 'execute() raw SQL is not supported on Database::Join',
	error_unknown_message	=> 'Unknown message key "%s"',
);

=head1 NAME

Database::Join - Read-only combined view across two or more Database::Abstraction objects

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

B<Basic two-database join>

    use Database::Join;

    # Step 1: create each component database the normal way
    my $customers = Database::Customers->new(directory => '/data');
    my $loyalty   = Database::Loyalty->new(directory  => '/data');

    # Step 2: combine them on the shared key column 'entry'
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
    );

    # Step 3: query exactly as you would a single Database::Abstraction object
    my $all_rows  = $join->selectall_arrayref();
    my $vip_rows  = $join->selectall_arrayref(tier => 'gold');
    my $one_row   = $join->fetchrow_hashref(entry => 'C001');
    my $total     = $join->count();
    my $col_names = $join->columns();

B<Hiding internal columns>

    my $join = Database::Join->new(
        databases      => [ $customers, $loyalty ],
        join_column    => 'entry',
        remove_columns => [ 'internal_id', 'audit_ts' ],
    );
    # 'internal_id' and 'audit_ts' never appear in results or columns()

B<join_map: when the key column has different names in each database>

    # $cities  (index 0) has a column called 'statecode' -- matches join_column
    # $stnames (index 1) has a column called 'entry'     -- different name

    my $join = Database::Join->new(
        databases   => [ $cities,  $stnames ],
        #                index 0   index 1
        join_column => 'statecode',
        join_map    => { 1 => 'entry' },  # index 1 calls its join key 'entry'
    );

    # All returned rows use 'statecode'; 'entry' is never exposed
    my $rows = $join->selectall_arrayref();

B<filters: permanently restrict a database's visible rows>

    # Only show orders placed more than 60 days ago, without repeating
    # the criterion on every query call.
    my $join = Database::Join->new(
        databases   => [ $customers, $orders ],
        join_column => 'entry',
        filters     => { 1 => { age_days => { '>' => 60 } } },
    );

    my $rows = $join->selectall_arrayref();                 # all old orders
    my $vip  = $join->selectall_arrayref(tier => 'gold');   # old + gold tier

B<Inner and outer join types>

    my $inner = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
        join_type   => 'inner',   # only keys present in BOTH databases
    );

    my $outer = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
        join_type   => 'outer',   # all keys from EITHER database
    );

B<Building the view incrementally with add_database>

    my $join = Database::Join->new(
        databases   => [ $customers ],
        join_column => 'entry',
    );

    $join->add_database($loyalty)
         ->add_database($scores, remove_columns => ['raw_score']);

B<AUTOLOAD column shortcut>

    # Returns the 'name' value for entry 'C001' (scalar context)
    my $name = $join->name(entry => 'C001');

    # Returns all 'tier' values (list context)
    my @tiers = $join->tier();

=head1 DESCRIPTION

C<Database::Join> merges two or more L<Database::Abstraction> objects into a
single logical, read-only view.  Each component database is queried
independently through its own C<Database::Abstraction> interface.  The results
are combined in Perl memory using a shared key column (C<join_column>).

The module exposes the same read-only API as C<Database::Abstraction>:
C<selectall_arrayref>, C<selectall_array>, C<fetchrow_hashref>, C<count>,
C<columns>, C<schema>, C<updated>, C<set_logger>, and the AUTOLOAD column
shortcut.  Callers do not need to know how many underlying databases are
involved.

Think of it as a virtual database table that is assembled on demand from
several real tables, one per component database.

=head2 Join semantics

The C<join_type> parameter controls what happens when a particular key value
exists in some component databases but not all:

=over 4

=item C<left> (the default)

All rows from the I<primary> (first) database are returned.  Columns from
subsequent databases are included where a matching row is found, and simply
absent from the hashref where there is no match.  If you are familiar with
SQL, this is a LEFT OUTER JOIN on the first table.

=item C<inner>

Only rows whose join-column value is present in I<every> component database
are returned.  This is equivalent to a SQL INNER JOIN.

=item C<outer>

Every join-column value found in I<any> component database is returned.
Columns from databases that do not have that key value are absent from the
merged row.  This is a FULL OUTER JOIN.

=back

B<Important override rule:> whenever you pass a query criterion for a column
that belongs to a secondary database, that database automatically acts as an
inner-join partner for that query only -- regardless of C<join_type>.  This
gives WHERE-clause semantics.  For example, if you have a LEFT join but query
C<< tier => 'gold' >> on a secondary database, only rows whose secondary entry
has tier = 'gold' are returned (rows with no secondary entry are excluded, just
as a WHERE clause would exclude them).

=head2 Column ownership and routing

At construction time, C<Database::Join> calls C<columns()> on each component
database and builds an internal index that maps every column name to the
database that owns it.

When you pass criteria to a query method, each key-value pair is automatically
routed to the right database.  You never need to say which database a column
belongs to.

The C<join_column> is special: criteria on it are broadcast to I<all>
databases so that each database fetches only the relevant rows before the
in-memory merge.

When the same non-join column name exists in more than one database, the
I<last> database in the C<databases> array wins: its value overwrites earlier
ones in merged rows.

=head1 LIMITATIONS

=over 4

=item In-memory join only

All matching rows from every component database are fetched into memory before
the merge.  This is not suitable for very large result sets.

=item No chained builder or raw SQL

C<query()> and C<execute()> are not implemented.  Use C<selectall_arrayref>
or C<fetchrow_hashref> instead.

=item Single-column equi-join only

Joining on more than one column simultaneously, or on expressions, is not
supported.  When the join key has different names in different databases,
use C<join_map> to declare each database's local column name.

=item Sort order

Results are sorted by the C<join_column> value only.  Caller-specified
C<ORDER BY> is not propagated to the component databases.

=item count() fetches all rows

C<count()> executes the full join and counts the resulting rows in Perl.  It
does not push a C<COUNT(*)> query down to the databases.

=back

=head1 COMMON PITFALLS

=over 4

=item The join_column must exist in every component database

If even one database is missing the join key column, C<new()> (or
C<add_database()>) will C<croak> immediately.  Use C<join_map> when the
column has a different local name in some databases.

=item Criteria on a removed column are silently dropped

If you call C<remove_column('tier')> and later query
C<< selectall_arrayref(tier => 'gold') >>, the criterion is ignored (with a
C<carp> warning) and all rows are returned.  Always pass criteria before
removing columns, or restructure your code to avoid this.

=item You cannot remove the join column

C<< $join->remove_column($join->join_column) >> will C<croak>.  The join key
is required for the merge to work.

=item Left join does not guarantee all columns are populated

Under a LEFT join, rows from the primary database that have no matching row
in a secondary database will be returned with I<no keys> from that secondary
database.  Accessing C<< $row->{score} >> on such a row returns C<undef> --
not zero, not an empty string.  Always test C<defined $row->{score}> rather
than just C<$row->{score}> when the secondary match is optional.

=item Filters act as inner-join partners

Any database that has a C<filters> entry is promoted to an inner-join partner,
regardless of C<join_type>.  A row whose join-key value does not appear in
the filtered database's result is removed from the merged output entirely, not
merely missing its secondary columns.  This is intentional but can be
surprising if you expected LEFT join semantics.

=item Criteria-merging replaces scalar filters

When both a base filter and a query criterion target the same column, and both
are operator hashrefs (e.g. C<< { '>' => 60 } >>), the operators are combined
(AND semantics).  But if the query criterion is a plain scalar (e.g.
C<< score => 75 >>), it I<replaces> the base filter for that column entirely --
the base filter is ignored for that query.

=item AUTOLOAD sees the full merged join when filters or join_map are active

When either C<filters> or C<join_map> is in effect, the AUTOLOAD shortcut
(C<< $join->columnname(...) >>) runs the full join query rather than
delegating directly to the owning database.  This is necessary for correctness
but means the result respects all active filters and join-key translations,
which may differ from what the owning database would return on its own.

=item Duplicate column names: last database wins

When two component databases each have a column called C<notes>, the second
database's value silently overwrites the first in every merged row.  Use
C<remove_columns> (or C<remove_column>) to drop the unwanted duplicate.

=back

=head1 METHODS

=head2 new

=head3 SYNOPSIS

    my $join = Database::Join->new(
        databases      => [ $db1, $db2 ],
        join_column    => 'entry',
        join_type      => 'left',
        join_map       => { 1 => 'local_col' },
        filters        => { 1 => { score => { '>' => 60 } } },
        remove_columns => [ 'email', 'internal_id' ],
        logger         => $log,
        i18n           => $locale,
    );

=head3 DESCRIPTION

Constructs and returns a new C<Database::Join> object.

Each element of C<databases> must be an already-instantiated subclass of
C<Database::Abstraction>.  The constructor calls C<columns()> on every
database to build an internal column-routing table and verifies that
C<join_column> (or its local alias from C<join_map>) is present in each one.

Columns listed in C<remove_columns> are hidden immediately: they do not appear
in C<columns()>, C<schema()>, or any returned row hashref.  This is equivalent
to calling C<remove_column> once per name after construction.

=head3 API SPECIFICATION

=head4 Input

    databases      => { type => 'arrayref', required => 1 }
                      # One or more Database::Abstraction subclass objects.
                      #
                      # DOMAIN -- EP valid:   non-empty arrayref of blessed DA subclasses.
                      # DOMAIN -- EP invalid: scalar, hashref, or absent => croak.
                      # DOMAIN -- BVA size:   minimum 1 element; no documented upper bound.
                      # DOMAIN -- BVA elem:   each element must pass isa('Database::Abstraction').

    join_column    => { type => 'string',   optional => 1, default => 'entry' }
                      # The column name shared by all databases (the join key).
                      #
                      # DOMAIN -- EP valid:   any non-empty string present in every component DA.
                      # DOMAIN -- EP invalid: column absent from any DA => croak join_col_missing.
                      # DOMAIN -- BVA:        empty string '' is treated as a column name and
                      #                       will croak if (as expected) it is absent from every DA.
                      # DOMAIN -- NOTE:       matching is case-sensitive and exact.

    join_type      => { type => 'string',   optional => 1, default => 'left',
                        enum => ['inner', 'left', 'outer'] }
                      # Controls which keys appear in the result when not all
                      # databases share the same key values.
                      #
                      # DOMAIN -- EP valid:   exactly 'inner', 'left', or 'outer'.
                      # DOMAIN -- EP invalid: any other string including 'INNER', 'LEFT',
                      #                       'OUTER' (enum check is case-sensitive), 'cross',
                      #                       or '' => croak from validate_strict.

    join_map       => { type => 'hashref',  optional => 1 }
                      # Zero-based database index => local column name.
                      # See the join_map section for full details.
                      #
                      # DOMAIN -- EP valid:   hashref values must be plain strings.
                      # DOMAIN -- EP invalid: reference value (hashref, arrayref, coderef, etc.)
                      #                       => croak; the guard prevents heap-address leakage.
                      # DOMAIN -- BVA:        out-of-range keys (beyond the databases array) are
                      #                       silently ignored.

    filters        => { type => 'hashref',  optional => 1 }
                      # Zero-based database index => criteria hashref.
                      # Permanent row restrictions on individual databases.
                      # See the filters section for full details.

    remove_columns => { type => 'arrayref', optional => 1 }
                      # Column names to hide from the merged view.
                      #
                      # DOMAIN -- EP valid:   arrayref of any strings; non-existent columns
                      #                       are silently ignored (idempotent).
                      # DOMAIN -- EP invalid: join_column itself => croak remove_join_col.
                      # DOMAIN -- BVA:        [] empty arrayref is a safe no-op.

    logger         => { type => 'object',   optional => 1 }
                      # Logger object propagated to all component databases.

    i18n           => { type => 'object',   optional => 1 }
                      # Localisation object with a translate($key, @args) method.

=head4 Output

    A blessed Database::Join object.

=head3 EXAMPLE

    # Customers database: entry | name | email
    # Loyalty   database: entry | tier | points

    my $join = Database::Join->new(
        databases      => [ $customers, $loyalty ],
        join_column    => 'entry',
        join_type      => 'inner',            # only customers who also have loyalty records
        remove_columns => [ 'email' ],        # hide PII from query results
        filters        => { 1 => { points => { '>' => 0 } } }, # ignore zero-point records
    );

    my $rows = $join->selectall_arrayref();
    # Each row: { entry => ..., name => ..., tier => ..., points => ... }
    # 'email' is absent. Zero-point loyalty records are excluded.

=head3 PSEUDOCODE

    validate all parameters with validate_strict
    croak if databases is empty
    croak if any element of databases is not a Database::Abstraction subclass
    bless the object with all fields initialised
    call _build_col_index to map every column to its owning database
        and verify join_column presence in each database
    for each column in remove_columns: call remove_column
    return the new object

=head3 MESSAGES

    error_no_databases     -- databases arrayref was empty
    error_invalid_db       -- an element of databases is not a D::A subclass
    error_join_col_missing -- join_column (or its join_map alias) not found in a database

=cut

sub new {
	my ($class, @args) = @_;

	my $p = validate_strict(
		schema => {
			databases	=> { type => 'arrayref' },
			join_column	=> { type => 'string',   optional => 1, default => 'entry' },
			join_type	=> { type => 'string',   optional => 1, default => 'left',
			                  enum => ['inner', 'left', 'outer'] },
			join_map	=> { type => 'hashref',  optional => 1 },
			filters		=> { type => 'hashref',  optional => 1 },
			remove_columns	=> { type => 'arrayref', optional => 1 },
			logger		=> { type => 'object',   optional => 1 },
			i18n		=> { type => 'object',   optional => 1 },
		},
		input => get_params(undef, \@args) // {},
	);

	croak _msg($p->{i18n}, 'error_no_databases')
		unless @{ $p->{databases} };

	# Capture caller-supplied logger and i18n object BEFORE Object::Configure::configure
	# overwrites them with class-level defaults.  configure() reads default values
	# from Database::Abstraction's class config and silently replaces any caller-
	# supplied value if a class default exists for that key.
	my $caller_logger = $p->{logger};
	my $caller_i18n   = $p->{i18n};

	$p = Object::Configure::configure($class, $p);

	for my $i (0 .. $#{ $p->{databases} }) {
		croak _msg($p->{i18n}, 'error_invalid_db', $i)
			unless blessed($p->{databases}[$i])
			    && $p->{databases}[$i]->isa('Database::Abstraction');
	}

	# Cache the primary database's internal primary-key column name once at
	# construction.  AUTOLOAD uses this to map a bare positional argument to the
	# correct column when join_map is active and the primary DB's primary key
	# differs from join_column (e.g. join_col='statecode' but primary key='entry').
	# Accessing {id} here — at construction time, before the object is shared —
	# is the single permitted point of coupling to DA's internal field; caching
	# avoids repeating the hash intrusion on every AUTOLOAD call.
	my $primary_pk = $p->{databases}[0]{id} // $p->{join_column};

	my $self = bless {
		_dbs          => $p->{databases},
		_join_col     => $p->{join_column},
		_join_type    => $p->{join_type},
		_join_map     => $p->{join_map} // {},	# db_index => local join col name
		# TODO: Data Flow Anomaly (filter reference aliasing) - _filters stores
		# the caller's hashref directly.  External mutation of the caller's hash
		# after construction will silently change query behaviour.  A deep copy
		# (e.g. Storable::dclone) would bound the lifetime but adds a dependency.
		_filters      => $p->{filters}  // {},	# db_index => criteria hashref
		_logger       => $caller_logger,
		_i18n         => $caller_i18n,
		_col_db       => {},	# column_name => db_index
		_db_cols      => [],	# per-db column-presence hashref
		_removed_cols => {},	# column_name => 1 (hidden from the view)
		_col_cache    => undef,	# memoised columns() result
		_schema_cache => undef,	# memoised schema() result
		_autoload_pk  => $primary_pk,	# primary DB's key col; positional arg for AUTOLOAD
	}, $class;

	$self->_build_col_index();

	# Propagate the logger to every component database if one was supplied.
	# set_logger() is used here (rather than a direct hash write) to honour each
	# DA's own logging setup hook and remain decoupled from DA internals.
	if (my $log = $self->{_logger}) {
		$_->set_logger($log) for @{ $self->{_dbs} };
	}

	# Apply column removals requested in the constructor
	if (my $rc = $p->{remove_columns}) {
		$self->remove_column($_) for @{$rc};
	}

	return $self;
}

# ---------------------------------------------------------------------------
# Public API (mirrors Database::Abstraction)
# ---------------------------------------------------------------------------

=head2 join_map - joining on differently-named columns

By default every component database must have a column whose name matches
C<join_column>.  If a database uses a different local name for the join key,
declare the mapping with C<join_map>.

C<join_map> is a hashref.  Each B<key> is the B<zero-based position> of a
database in the C<databases> array (0 = first, 1 = second, and so on).  Each
B<value> is the name that B<that particular database> uses for the join key.

Databases not listed in C<join_map> are assumed to already have a column
named C<join_column> and need no entry.

Throughout the merged view the join key is I<always> referred to by the name
given in C<join_column>.  The local alias is never exposed in returned rows,
in C<columns()>, or in C<schema()>.

B<When do you need join_map?>

You need C<join_map> when you have two tables like:

    cities table  : entry (the city name) | statecode
    stnames table : entry (the state code) | state

Here you want to join cities.statecode to stnames.entry.  You choose
C<< join_column => 'statecode' >> as the canonical name, but stnames calls
that same concept C<entry>, so you declare:

    join_map => { 1 => 'entry' }  # stnames (index 1) calls it 'entry'

B<Example>

    #                        index 0     index 1
    my @databases = (       $cities,    $stnames  );
    #  join key column:    'statecode'  'entry'
    #  join_column:        'statecode' (chosen canonical name)
    #  stnames differs, so declare the alias:

    my $join = Database::Join->new(
        databases   => \@databases,
        join_column => 'statecode',
        join_map    => { 1 => 'entry' },
    );

    my $rows = $join->selectall_arrayref();
    # Each $row has keys: entry (city), statecode, state
    # 'entry' from stnames is never exposed directly.

    my $row = $join->fetchrow_hashref(statecode => 'CA');

B<Using add_database instead>

If you build the join incrementally with C<add_database>, pass
C<join_column> directly to that call instead of using C<join_map>:

    my $join = Database::Join->new(
        databases   => [ $cities ],
        join_column => 'statecode',
    );
    $join->add_database($stnames, join_column => 'entry');

This is exactly equivalent to the C<join_map> form above.

=head2 filters - permanent per-database row filters

C<filters> lets you restrict a component database to a subset of its rows
permanently, without repeating the criterion on every query call.

Think of it as telling the join: "whenever you query this database, always
add these extra conditions".  Callers never need to specify the restriction
themselves and can never accidentally omit it.

C<filters> is a hashref.  Each B<key> is the B<zero-based position> of a
database in the C<databases> array (same numbering as C<join_map>).  Each
B<value> is a criteria hashref in the same format as C<selectall_arrayref>
accepts.

B<Key-set semantics>

A filtered database always acts as an inner-join partner, regardless of the
C<join_type> setting.  Any join-key value that does not pass the filter is
excluded from the merged output entirely -- not just missing its secondary
columns.  This ensures the filter genuinely restricts the view rather than
simply hiding a few fields.

B<Criteria merging>

When a query call also passes a criterion for a column that already has a base
filter, the two constraints are combined:

=over 4

=item *

When both the base filter value and the query criterion are operator hashrefs
(e.g. C<< { '>' => 60 } >> and C<< { '<' => 365 } >>), their operators are
merged: I<both> constraints apply simultaneously (AND semantics).

=item *

When either value is a plain scalar, or the operators conflict, the
query-time criterion wins and the base filter for that column is ignored for
that one call.

=back

B<Example -- only show orders placed more than 60 days ago>

    my $join = Database::Join->new(
        databases   => [ $customers, $orders ],
        join_column => 'entry',
        filters     => { 1 => { age_days => { '>' => 60 } } },
    );

    # Every query automatically sees only old orders
    my $rows = $join->selectall_arrayref();

    # Additional criteria layer on top -- gold tier AND old order
    my $vip  = $join->selectall_arrayref(tier => 'gold');

    # Range intersection: age_days > 60 AND age_days < 365
    my $mid  = $join->selectall_arrayref(age_days => { '<' => 365 });

When using C<add_database>, pass C<filter> (singular) to set the base
criteria for the new database:

    $join->add_database($orders, filter => { age_days => { '>' => 60 } });

=head2 selectall_arrayref

=head3 SYNOPSIS

    my $rows = $join->selectall_arrayref();
    my $rows = $join->selectall_arrayref(tier  => 'gold');
    my $rows = $join->selectall_arrayref(score => { '>' => 80 });
    my $rows = $join->selectall_arrayref('C001');  # positional: entry => 'C001'

=head3 DESCRIPTION

Returns an arrayref of hashrefs representing the merged view of all component
databases, optionally filtered by the given criteria.

Criteria for columns that live in different databases are routed
automatically: each database is queried with only the criteria that apply to
its own columns.  The results are combined in memory using C<join_column>.

Accepts the same criteria syntax as C<Database::Abstraction::selectall_arrayref>.
A single plain scalar argument is interpreted as the C<join_column> value
(equivalent to C<< entry => 'C001' >> when C<join_column> is C<'entry'>).

=head3 API SPECIFICATION

=head4 Input

    Calling conventions (in order of precedence):
      1. No arguments             -- returns all rows
      2. One plain scalar         -- shorthand for join_column => $scalar
      3. Key-value pairs or
         a criteria hashref       -- routed per-database

    Values may be:
      Plain scalar                -- exact match
      Hashref of operators        -- e.g. { '>' => 80 }

=head4 Output

    Arrayref of hashrefs; one hashref per qualifying merged row,
    sorted ascending by join_column value.
    Returns a reference to an empty array when no rows match.

=head3 EXAMPLE

    # All rows from both databases
    my $all = $join->selectall_arrayref();

    # Only rows where the 'tier' column (from the loyalty database)
    # equals 'gold' -- the criterion is routed to the right database
    my $vip = $join->selectall_arrayref(tier => 'gold');

    # Operator hashref: score > 80
    my $high = $join->selectall_arrayref(score => { '>' => 80 });

    # Access each merged row
    for my $row (@{$vip}) {
        printf "%-10s tier=%-8s score=%d\n",
            $row->{entry}, $row->{tier}, $row->{score} // 0;
    }

=cut

sub selectall_arrayref {
	my ($self, @args) = @_;
	return $self->_joined_query($self->_parse_query_args(undef, @args));
}

=head2 selectall_array

=head3 SYNOPSIS

    my @rows = $join->selectall_array(tier => 'gold');

    # Scalar context: only the first matching row
    my $first = $join->selectall_array(entry => 'C001');

=head3 DESCRIPTION

In list context returns a list of merged hashrefs -- the same rows that
C<selectall_arrayref> would return, just as a flat list rather than an
arrayref.

In scalar context returns only the first matching hashref (or C<undef> if
nothing matches).

=head3 API SPECIFICATION

=head4 Input

    Same as selectall_arrayref.

=head4 Output

    List context:   list of hashrefs (may be empty).
    Scalar context: single hashref or undef.

=head3 EXAMPLE

    my @all = $join->selectall_array();
    print scalar @all, " rows\n";

    # First gold-tier customer only
    my $first_vip = $join->selectall_array(tier => 'gold');
    print $first_vip->{name}, "\n" if defined $first_vip;

=cut

sub selectall_array {
	my ($self, @args) = @_;
	my $rows = $self->_joined_query($self->_parse_query_args(undef, @args));
	return wantarray ? @{$rows} : $rows->[0];
}

=head2 fetchrow_hashref

=head3 SYNOPSIS

    my $row = $join->fetchrow_hashref(entry => 'C001');
    my $row = $join->fetchrow_hashref('C001');   # positional shorthand

=head3 DESCRIPTION

Returns a single merged hashref for the first row matching the given
criteria, or C<undef> when nothing matches.

Equivalent to calling C<selectall_arrayref> and taking only the first element.
All the same criteria conventions apply.

=head3 API SPECIFICATION

=head4 Input

    Same as selectall_arrayref.

=head4 Output

    Hashref, or undef when no row matches.

=head3 EXAMPLE

    my $row = $join->fetchrow_hashref(entry => 'C001');
    if (defined $row) {
        print "Name: $row->{name}, Tier: $row->{tier}\n";
    } else {
        print "No record for C001\n";
    }

    # Positional: works when join_column is 'entry'
    my $row2 = $join->fetchrow_hashref('C001');

=cut

sub fetchrow_hashref {
	my ($self, @args) = @_;
	my $rows = $self->_joined_query($self->_parse_query_args(undef, @args));
	return $rows->[0];
}

=head2 count

=head3 SYNOPSIS

    my $total  = $join->count();
    my $active = $join->count(tier => 'gold');

=head3 DESCRIPTION

Returns the number of merged rows that satisfy the given criteria.

The full join is performed and the resulting rows are counted in Perl; no
C<COUNT(*)> is pushed down to the component databases.

=head3 API SPECIFICATION

=head4 Input

    Same criteria syntax as selectall_arrayref.

=head4 Output

    Non-negative integer.

=head3 EXAMPLE

    my $total   = $join->count();
    my $gold    = $join->count(tier => 'gold');
    my $high    = $join->count(score => { '>' => 90 });

    printf "%d total, %d gold-tier, %d high-scorers\n",
        $total, $gold, $high;

=cut

sub count {
	my ($self, @args) = @_;
	my $rows = $self->_joined_query($self->_parse_query_args(undef, @args));
	return scalar @{$rows};
}

=head2 columns

=head3 SYNOPSIS

    my $cols = $join->columns();

=head3 DESCRIPTION

Returns an arrayref of all column names visible in the merged view,
deduplicated and sorted alphabetically.

The C<join_column> appears exactly once, even if it exists under different
local names in some databases (see C<join_map>).  Columns that have been
hidden with C<remove_column> or C<remove_columns> do not appear.

The result is memoised: repeated calls are cheap.

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    Arrayref of column name strings, sorted alphabetically.

=head3 EXAMPLE

    my $cols = $join->columns();
    print join(', ', @{$cols}), "\n";
    # e.g. "entry, name, score, tier"

=cut

sub columns {
	my ($self) = @_;

	return $self->{_col_cache} if $self->{_col_cache};

	my %seen;
	my @cols;
	my $join_col = $self->{_join_col};

	for my $i (0 .. $#{ $self->{_dbs} }) {
		my $local_jc = $self->{_join_map}{$i};
		for my $col (@{ $self->{_dbs}[$i]->columns() }) {
			next if $seen{$col}++;
			next if $self->{_removed_cols}{$col};
			# The local join-key alias is not a data column; the canonical name
			# is already contributed by the database that owns it under that name.
			next if $local_jc && $col eq $local_jc && $col ne $join_col;
			push @cols, $col;
		}
	}

	$self->{_col_cache} = [ sort @cols ];
	return $self->{_col_cache};
}

=head2 schema

=head3 SYNOPSIS

    my $schema = $join->schema();

=head3 DESCRIPTION

Returns a merged schema hashref for all visible columns across all component
databases.  Each key is a column name; each value is the schema metadata
hashref returned by C<Database::Abstraction::schema()> for that column
(typically C<{ type, nullable, default, pk }>).

When the same column name appears in more than one database the I<last>
database's metadata is used.  Columns hidden with C<remove_column> are not
included.

The result is memoised.

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    Hashref: column_name => { type => ..., nullable => ..., default => ..., pk => ... }.

=head3 EXAMPLE

    my $schema = $join->schema();
    for my $col (sort keys %{$schema}) {
        my $info = $schema->{$col};
        printf "%-15s type=%-10s nullable=%s\n",
            $col, $info->{type}, $info->{nullable} ? 'yes' : 'no';
    }

=cut

sub schema {
	my ($self) = @_;

	return $self->{_schema_cache} if $self->{_schema_cache};

	# Hash slice assignment (@merged{keys} = values) is O(M) per database;
	# the previous (%merged = (%merged, %s)) pattern was O(N×M) per iteration,
	# totalling O(N²×M) over all databases for the same result.
	my %merged;
	for my $i (0 .. $#{ $self->{_dbs} }) {
		my $s        = $self->{_dbs}[$i]->schema() // {};
		my $local_jc = $self->{_join_map}{$i};
		if ($local_jc && $local_jc ne $self->{_join_col}) {
			for my $col (keys %{$s}) {
				$merged{$col} = $s->{$col} unless $col eq $local_jc;
			}
		} else {
			@merged{keys %{$s}} = values %{$s};
		}
	}

	delete @merged{keys %{ $self->{_removed_cols} }}
		if %{ $self->{_removed_cols} };

	$self->{_schema_cache} = \%merged;
	return $self->{_schema_cache};
}

=head2 updated

=head3 SYNOPSIS

    my $ts = $join->updated();

=head3 DESCRIPTION

Returns the Unix timestamp of the most recent modification across all
component databases.  This is the maximum of all individual C<updated()>
return values.

Use this to implement simple cache-invalidation logic: if C<updated()>
has advanced since your last snapshot, re-query.

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    Unix timestamp (positive integer).

=head3 EXAMPLE

    my $last_modified = $join->updated();
    if ($last_modified > $my_cache_timestamp) {
        $my_cache = $join->selectall_arrayref();
        $my_cache_timestamp = $last_modified;
    }

=cut

sub updated {
	my ($self) = @_;
	return max(map { $_->updated() } @{ $self->{_dbs} });
}

=head2 set_logger

=head3 SYNOPSIS

    $join->set_logger($log);

=head3 DESCRIPTION

Attaches a new logger object to the join and propagates it to every component
database.  The logger is used for diagnostic output by all component databases.

=head3 API SPECIFICATION

=head4 Input

    $log    Positional: a logger object (required).
            Must support whatever interface Database::Abstraction expects.

=head4 Output

    Returns C<$self> for method chaining.

=head3 EXAMPLE

    # Log::Any is used here as an example; any object that implements
    # debug() and info() (or whichever methods your component databases
    # call internally) works equally well.
    use Log::Any qw($log);

    my $join = Database::Join->new(databases => [$db1, $db2], join_column => 'entry');
    $join->set_logger($log);
    # $log is now used by $join and by $db1 and $db2

=cut

sub set_logger {
	my ($self, $logger) = @_;

	croak 'Usage: set_logger($logger)' unless defined $logger;

	$self->{_logger} = $logger;
	$_->set_logger($logger) for @{ $self->{_dbs} };

	return $self;
}

=head2 add_database

=head3 SYNOPSIS

    # Positional: database object as first argument
    $join->add_database($db);

    # Named: equivalent to the above
    $join->add_database(database => $db);

    # With options (mixed positional + named)
    $join->add_database($db, remove_columns => ['internal_id']);
    $join->add_database($db, join_column    => 'local_key_name');
    $join->add_database($db, filter         => { score => { '>' => 60 } });

    # Chainable
    $join->add_database($db1)->add_database($db2, remove_columns => ['notes']);

=head3 DESCRIPTION

Adds one more C<Database::Abstraction> subclass object to the logical view
and immediately updates the column-ownership index.

After the call, all query methods return rows that include columns from the
newly added database, and criteria on those new columns are routed to it
automatically.

When a column name in the new database already exists in an earlier database,
the new database becomes the authoritative source for that column
(last-database-wins, the same rule that applies at construction time).

The join-column must be present in the new database (or declared via
C<join_column>).  The logger is propagated to the new database if one is set.

C<add_database> is the runtime equivalent of listing the database in the
C<databases> array to C<new>.  The optional C<join_column> parameter is
equivalent to a C<join_map> entry; the optional C<filter> parameter is
equivalent to a C<filters> entry.

=head3 API SPECIFICATION

=head4 Input

    database       => { type => 'object',   required => 1 }
                      # A Database::Abstraction subclass instance.
                      #
                      # DOMAIN -- EP valid:   blessed object that passes
                      #                       isa('Database::Abstraction').
                      # DOMAIN -- EP invalid: non-reference, unblessed ref, wrong class,
                      #                       or non-reference non-key scalar (the guard at
                      #                       the top of add_database rejects it with
                      #                       error_invalid_db before validate_strict runs).

    join_column    => { type => 'string',   optional => 1 }
                      # The name of the join key in THIS new database,
                      # when it differs from the canonical join_column.
                      #
                      # DOMAIN -- EP valid:   any string that exists as a column in the
                      #                       new database.
                      # DOMAIN -- EP invalid: string absent from the new database's columns()
                      #                       => croak error_join_col_missing.

    filter         => { type => 'hashref',  optional => 1 }
                      # Permanent criteria for this database only.
                      # Same format as selectall_arrayref.

    remove_columns => { type => 'arrayref', optional => 1 }
                      # Column names from this database to hide.

=head4 Output

    Returns C<$self> to support method chaining.

=head3 EXAMPLE

    my $join = Database::Join->new(
        databases   => [ $customers ],
        join_column => 'entry',
    );

    # Add loyalty data; hide internal columns from it
    $join->add_database($loyalty, remove_columns => ['audit_ts']);

    # Add score data; only include rows with score > 60
    $join->add_database($scores, filter => { score => { '>' => 60 } });

    # Add a database whose join key has a different local name
    $join->add_database($stnames, join_column => 'state_code');

    # All three options combined, and chained
    $join->add_database($db4,
        join_column    => 'ref_id',
        filter         => { active => 1 },
        remove_columns => ['legacy_col'],
    );

=head3 PSEUDOCODE

    determine the new database's index (length of current _dbs array)
    extract the database object from positional or named argument
    croak if it is not a Database::Abstraction subclass
    register join_column alias in _join_map if different from canonical
    register filter in _filters if provided
    fetch column list from the new database
    croak if the join key is missing from the new database
    append the new database to _dbs and _db_cols
    update _col_db: for each new column, point it at the new index
        (last-database-wins; skip removed columns and the local join alias)
    invalidate _col_cache and _schema_cache
    propagate logger if set
    apply remove_columns if provided
    return $self

=head3 MESSAGES

    error_invalid_db       -- argument is not a Database::Abstraction subclass
    error_join_col_missing -- join_column not found in the new database

=cut

sub add_database {
	my ($self, @args) = @_;

	my $idx = scalar @{ $self->{_dbs} };
	my $db;

	# Fail-fast guard: a non-reference first arg must be a recognised named-pair key.
	# Modus Ponens: !ref(x) ∧ x ∉ @_ADD_DB_KEYS → cannot be a database object → croak.
	# De Morgan reduction: the elsif below is logically equivalent to (@args && ref(args[0]))
	# because the !ref branch was already handled; exhaustion makes the ref() check redundant.
	if (@args && !ref($args[0])) {
		croak $self->_err('error_invalid_db', $idx)
			unless grep { $args[0] eq $_ } @_ADD_DB_KEYS;
	} elsif (@args) {
		# Positional form: first arg is a reference — extract it before get_params
		# to avoid the mixed positional+named-pairs confusion.
		$db = shift @args;
	}

	my $p = validate_strict(
		schema => {
			database       => { type => 'object',   optional => 1 },
			join_column    => { type => 'string',   optional => 1 },
			filter         => { type => 'hashref',  optional => 1 },
			remove_columns => { type => 'arrayref', optional => 1 },
		},
		input => (@args ? get_params(undef, @args) : {}) // {},
	);

	$db //= $p->{database};

	croak $self->_err('error_invalid_db', $idx)
		unless blessed($db) && $db->isa('Database::Abstraction');

	# Determine and register the local join column name for this database
	my $local_jc = $p->{join_column} // $self->{_join_col};
	$self->{_join_map}{$idx} = $local_jc if $p->{join_column};
	$self->{_filters}{$idx}  = $p->{filter} if $p->{filter};

	my $cols         = $db->columns();
	my %col_presence = map { $_ => 1 } @{$cols};

	croak $self->_err('error_join_col_missing', $local_jc, $idx, ref($db))
		unless $col_presence{$local_jc};

	# Register the new database
	push @{ $self->{_dbs} },     $db;
	push @{ $self->{_db_cols} }, \%col_presence;

	# Update column routing: last-database-wins for duplicate column names;
	# skip the local join-key alias (it is not a data column).
	for my $col (@{$cols}) {
		next if $self->{_removed_cols}{$col};
		next if $local_jc ne $self->{_join_col} && $col eq $local_jc;
		$self->{_col_db}{$col} = $idx;
	}

	# Invalidate memoisation caches
	$self->{_col_cache}    = undef;
	$self->{_schema_cache} = undef;

	# Propagate logger if one is configured
	if (my $log = $self->{_logger}) {
		$db->set_logger($log);
	}

	# Apply any column removals requested for this database
	if (my $rc = $p->{remove_columns}) {
		$self->remove_column($_) for @{$rc};
	}

	return $self;
}

=head2 remove_column

=head3 SYNOPSIS

    $join->remove_column('email');

    # Chainable
    $join->remove_column('internal_id')->remove_column('audit_ts');

=head3 DESCRIPTION

Permanently hides a column from the merged view.  After this call:

=over 4

=item *

The column does not appear in C<columns()> or C<schema()>.

=item *

Returned row hashrefs do not contain the column key.

=item *

Any query criterion that references the removed column is silently dropped
(with a C<carp> warning).

=back

The C<join_column> cannot be removed; attempting to do so will C<croak>.
Removing a column that does not exist in any database is silently ignored
(the call is idempotent and safe).  The C<columns()> and C<schema()>
memoisation caches are cleared automatically.

=head3 API SPECIFICATION

=head4 Input

    $col    Positional string: the column name to remove.

            DOMAIN -- EP valid:   any string; non-existent columns are silently
                                  ignored (idempotent call, returns $self).
            DOMAIN -- EP invalid: join_column value => croak error_remove_join_col.
            DOMAIN -- BVA:        undef and '' are explicit no-ops (returns $self).
                                  These are below the minimum meaningful string
                                  length and are handled without any warning.

=head4 Output

    Returns C<$self> to support method chaining.

=head3 EXAMPLE

    # Hide private fields immediately after construction
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
    )->remove_column('email')
     ->remove_column('internal_notes');

    # Verify they are gone
    my $cols = $join->columns();
    # 'email' and 'internal_notes' are absent

=head3 MESSAGES

    error_remove_join_col -- attempt to remove the join_column itself

=cut

sub remove_column {
	my ($self, $col) = @_;

	croak $self->_err('error_remove_join_col', $col)
		if defined $col && $col eq $self->{_join_col};

	if (defined $col && length $col) {
		$self->{_removed_cols}{$col} = 1;
		delete $self->{_col_db}{$col};
		$self->{_col_cache}    = undef;
		$self->{_schema_cache} = undef;
	}

	return $self;
}

=head2 query

Not supported.  C<Database::Join> does not implement the chained query
builder.  Calling this method will always C<croak> with an explanatory message.

Use C<selectall_arrayref>, C<selectall_array>, C<fetchrow_hashref>, or
C<count> instead.

=cut

sub query {
	my ($self) = @_;
	croak $self->_err('error_query_unsupported');
}

=head2 execute

Not supported.  Raw SQL cannot span heterogeneous backends that may use
different database engines.  Calling this method will always C<croak>.

Use C<selectall_arrayref> or C<fetchrow_hashref> to query the joined view.

=cut

sub execute {
	my ($self) = @_;
	croak $self->_err('error_execute_unsupported');
}

=head2 AUTOLOAD - column shortcut

Calling an unknown method whose name matches a visible column name performs
a column lookup across the merged view.

=head3 SYNOPSIS

    # Scalar context: value from the first matching row
    my $name  = $join->name(entry => 'C001');

    # List context: values from every matching row
    my @tiers = $join->tier();

    # With a positional join-key argument (when join_column is 'entry')
    my $score = $join->score('C001');

=head3 DESCRIPTION

AUTOLOAD routes the call to the appropriate component database by looking up
the column name in the internal column-ownership index.

When either C<join_map> or C<filters> is active, AUTOLOAD performs a full
join query instead of delegating directly to the owning database.  This is
necessary because:

=over 4

=item *

With C<join_map>, the owning database's primary key may differ from the
canonical join key used in the call arguments.

=item *

With C<filters>, bypassing the join would return rows that the filter is
meant to exclude.

=back

In list context, every matching merged row contributes one value to the
returned list.  In scalar context, only the first row's value is returned.

Calling a method whose name begins with C<_> (a private method) via AUTOLOAD
will C<croak> with a clear error message rather than being silently ignored.

=head3 EXAMPLE

    # Lookup a single customer's name (scalar context)
    my $name = $join->name('C001');   # 'C001' maps to entry => 'C001'
    print "Name: $name\n";

    # Get every tier value in the view (list context)
    my @all_tiers = $join->tier();
    my %freq;
    $freq{$_}++ for @all_tiers;

    # join_map active: AUTOLOAD runs a full join so the criteria are
    # translated correctly between the canonical and local key names.
    my @leesburg_states = sort $join->state('Leesburg');
    # ['Florida', 'Virginia'] if Leesburg appears in two states

=head3 PSEUDOCODE

    extract column name from $AUTOLOAD
    return if DESTROY
    croak if column name starts with '_' (private method guard)
    croak if column name is not in _col_db (unknown column)
    if join_map or filters are active:
        parse calling arguments using _parse_query_args
        call _joined_query to get all merged rows
        return map { $_->{col} } @rows  in list context
        return $rows[0]{col}            in scalar context
    else:
        delegate directly to the owning database

=cut

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;

	my ($col) = $AUTOLOAD =~ /::(\w+)$/;
	# TODO: Unreachable code detected during path analysis. Investigate for removal.
	# `sub DESTROY {}` is defined explicitly in this package; Perl's method-resolution
	# order finds it before AUTOLOAD is ever invoked, so $col can never equal 'DESTROY'.
	return if $col eq 'DESTROY';

	# Private methods must not be reached via AUTOLOAD — croak immediately so
	# typos like $join->_join_col are not silently swallowed.
	croak ref($self), ": cannot call private method '$col' via AUTOLOAD"
		if $col =~ /^_/;

	my $db_idx = $self->{_col_db}{$col};
	croak ref($self), ": unknown column '$col'" unless defined $db_idx;

	# Use a full join query when join_map OR filters are active.  Direct
	# delegation to the owning database would bypass the join key translation
	# (join_map) and skip any permanent per-database row filters (filters).
	if (%{ $self->{_join_map} } || %{ $self->{_filters} }) {
		# _autoload_pk was captured once at construction from the primary DA's
		# {id} field; using the cached value avoids re-introspecting the blessed
		# hash on every call and isolates the coupling to a single known site.
		my $params = $self->_parse_query_args($self->{_autoload_pk}, @_);
		my $rows   = $self->_joined_query($params);
		return map { $_->{$col} } @{$rows} if wantarray;
		return @{$rows} ? $rows->[0]{$col} : undef;
	}

	# $db is resolved here (not earlier) to avoid a dead store on the join path above.
	my $db = $self->{_dbs}[$db_idx];
	return $db->$col(@_);
}

sub DESTROY {}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# _parse_query_args( $self, $positional_key, @caller_args ) -> \%params
# Purpose: Normalise the three calling conventions used by every public query
#          method and AUTOLOAD into a single criteria hashref.
# Entry:   $positional_key -- the column name mapped to a bare scalar argument;
#          pass undef to use the join_column (the default for public methods).
# Exit:    Always returns a hashref; never undef.
sub _parse_query_args :Protected {
	my ($self, $key, @args) = @_;
	$key //= $self->{_join_col};
	return {}                           unless @args;
	return { $key => $args[0] }        if @args == 1 && !ref($args[0]);
	return get_params(undef, @args) // {};
}

# _err( $self, $msg_key, @sprintf_args ) -> $string
# Convenience wrapper around _msg for use after construction, so callers do
# not have to extract $self->{_i18n} at every error site.
sub _err :Protected {
	my ($self, $key, @args) = @_;
	return _msg($self->{_i18n}, $key, @args);
}

# _build_col_index()
# Purpose: Populate _col_db (column_name => db_index) and _db_cols
#          (per-db column-presence hashrefs) by calling columns() on each
#          component database at construction time.
# Entry:   _dbs, _join_col, _join_map must already be set.
# Exit:    _col_db and _db_cols are set; join_column verified in every db.
# Effects: Croaks if any database is missing its join key column.
sub _build_col_index :Protected {
	my ($self) = @_;

	my $join_col = $self->{_join_col};
	my %col_db;
	my @db_cols;

	for my $i (0 .. $#{ $self->{_dbs} }) {
		my $db        = $self->{_dbs}[$i];
		my $local_jc  = $self->{_join_map}{$i} // $join_col;
		my $cols      = $db->columns();
		$db_cols[$i]  = { map { $_ => 1 } @{$cols} };

		# Guard: a join_map value that is a reference (e.g. a hashref) would
		# stringify to "HASH(0x...)" when interpolated into an error message,
		# leaking a heap address to callers.  Reject early with a clear message.
		croak $self->_err('error_join_col_missing', "(join_map[$i] must be a string)", $i, ref($db))
			if ref $local_jc;

		croak $self->_err('error_join_col_missing', $local_jc, $i, ref($db))
			unless $db_cols[$i]{$local_jc};

		for my $col (@{$cols}) {
			# Skip the local alias for the join key — it is not a data column
			next if $local_jc ne $join_col && $col eq $local_jc;
			# Last database wins for duplicate non-join columns
			$col_db{$col} = $i;
		}
	}

	$self->{_col_db}  = \%col_db;
	$self->{_db_cols} = \@db_cols;

	return;
}

# _partition_criteria( \%params ) -> \@per_db
# Purpose: Split a flat criteria hashref into one slice per component database.
# Entry:   $params is a criteria hashref; all keys must be column names or
#          join_column.
# Exit:    Returns an arrayref of per-database criteria hashrefs.  The
#          join_column criterion is broadcast to every database using each
#          database's local join-key name.  Unknown columns trigger a carp.
# Effects: Carps for each unrecognised column name.
sub _partition_criteria :Protected {
	my ($self, $params) = @_;

	my $join_col = $self->{_join_col};
	my $n        = scalar @{ $self->{_dbs} };
	my @per_db   = map { {} } 1 .. $n;

	for my $col (keys %{$params}) {
		if ($col eq $join_col) {
			# Broadcast to every database using each one's local key column name.
			# Shallow-copy operator hashrefs so a malicious component DA that
			# mutates its criteria hashref contents cannot corrupt siblings.
			my $val = $params->{$col};
			for my $i (0 .. $n - 1) {
				my $local = $self->{_join_map}{$i} // $join_col;
				$per_db[$i]{$local} = ref($val) eq 'HASH' ? { %{$val} } : $val;
			}
		} elsif (defined(my $idx = $self->{_col_db}{$col})) {
			$per_db[$idx]{$col} = $params->{$col};
		} else {
			carp $self->_err('warn_unknown_column', $col);
		}
	}

	return \@per_db;
}

# _fetch_indexed( $db_idx, \%criteria ) -> \%join_val_to_\@rows
# Purpose: Query one component database and index its rows by join-key value.
# Entry:   $db_idx is the zero-based database index; $criteria is the
#          pre-partitioned criteria hashref for this database.
# Exit:    Returns a hashref: join-key value => arrayref of row hashrefs.
#          Multiple rows sharing the same join-key value are all preserved
#          (important for the primary database when one key maps to many rows).
# Effects: Calls selectall_arrayref on the component database.
sub _fetch_indexed :Protected {
	my ($self, $db_idx, $criteria) = @_;

	my $db        = $self->{_dbs}[$db_idx];
	my $local_jc  = $self->{_join_map}{$db_idx} // $self->{_join_col};

	my $rows = $db->selectall_arrayref($criteria);
	$rows //= [];

	my %indexed;
	for my $row (@{$rows}) {
		my $key = $row->{$local_jc};
		next unless defined $key;
		push @{ $indexed{$key} }, $row;
	}

	return \%indexed;
}

# _joined_query( \%params ) -> \@merged_rows
#
# Purpose: Core join algorithm.  Partitions criteria, fetches per-database
#          results, resolves the key set, and merges rows.
#
# Key-set resolution (applied for each secondary database after the primary):
#
#   If the database had criteria in this query call (after base filter overlay),
#   it acts as an INNER-JOIN partner: only keys present in its filtered result
#   survive.  This gives WHERE-clause semantics even under a LEFT join.
#
#   If the database had NO effective criteria:
#     inner  -> intersect  (standard inner join)
#     left   -> no change  (primary defines the key set)
#     outer  -> union      (all keys from any database)
#
# Row merge: for each qualifying primary row, secondary rows are overlaid in
# index order.  For duplicate columns, later databases win.  Local join-key
# aliases are renamed to the canonical join_column before merging.
# Removed columns are deleted from every merged row.
sub _joined_query :Protected {
	my ($self, $params) = @_;

	my $join_col  = $self->{_join_col};
	my $join_type = $self->{_join_type};
	my $n         = scalar @{ $self->{_dbs} };

	my $per_db = $self->_partition_criteria($params);

	# Overlay any per-database base filters onto the partitioned criteria.
	# A filtered database always has effective criteria, so $had_criteria will
	# be true for it — giving inner-join key-set semantics regardless of join_type.
	for my $i (0 .. $n - 1) {
		my $base = $self->{_filters}{$i} // {};
		next unless %{$base};
		$per_db->[$i] = _merge_criteria($base, $per_db->[$i]);
	}

	# Fetch and index each database with its own criteria slice.
	# !!%hash collapses to 1 (non-empty) or '' (empty) without allocating a count.
	my @indexed;
	my @had_criteria;
	for my $i (0 .. $n - 1) {
		$indexed[$i]      = $self->_fetch_indexed($i, $per_db->[$i]);
		# TODO: Data Flow Anomaly (D~) - $had_criteria[0] written here but never read;
		# the key-set resolution loop below starts at i=1.  When n==1 this is always
		# a dead store.  Harmless but could be removed if n>1 is enforced, or the
		# loop could start at i=0 if primary-criteria semantics are ever needed.
		$had_criteria[$i] = !!%{ $per_db->[$i] };
	}

	# Seed the key set from the primary database.
	my %key_set = map { $_ => 1 } keys %{ $indexed[0] };

	# Merge in each secondary database.
	# Premise 1: indexed[$i] is a valid hashref (returned by _fetch_indexed).
	# Premise 2: join_type ∈ {left, inner, outer} (enforced by validate_strict).
	# Conclusion: the three branches below are exhaustive and mutually exclusive.
	for my $i (1 .. $n - 1) {
		if ($had_criteria[$i] || $join_type eq 'inner') {
			# Intersect: single-pass delete for keys absent from this secondary.
			# A single loop avoids the intermediate list that grep would allocate
			# before the delete loop could iterate it (saves O(K) allocations).
			for my $k (keys %key_set) {
				delete $key_set{$k} unless exists $indexed[$i]{$k};
			}
		} elsif ($join_type eq 'outer') {
			# Union: hash slice assignment is a single Perl op, not a per-key loop.
			@key_set{ keys %{ $indexed[$i] } } = ();
		}
		# left + no criteria: key_set unchanged (primary defines the set).
	}

	# Build one merged result row for every primary-database row that qualifies.
	# Secondary databases act as lookup tables: when a key maps to multiple
	# secondary rows, the last one wins (consistent with construction-time
	# last-database-wins column routing).
	my @result;
	my @removed = keys %{ $self->{_removed_cols} };
	for my $key (sort keys %key_set) {
		# All qualifying rows from the primary database for this key.
		# Use [{}] so that outer-join keys absent from the primary still
		# produce one merged row filled from secondary databases.
		my @base_rows = @{ $indexed[0]{$key} // [{}] };

		for my $prow (@base_rows) {
			my %merged = %{$prow};

			for my $i (1 .. $n - 1) {
				my $sec_arr = $indexed[$i]{$key};
				next unless $sec_arr && @{$sec_arr};

				# Write secondary columns directly into %merged without copying
				# the source row into a temporary hash first.
				# Before: %row_copy = %{$src}   then %merged = (%merged,%row_copy)
				#   → 2 full hash copies per secondary per row: O(C) + O(|merged|+C)
				# After: per-key loop writes straight into %merged
				#   → O(C) key assignments only; no intermediate allocation
				my $src      = $sec_arr->[-1];
				my $local_jc = $self->{_join_map}{$i};
				my $rename   = $local_jc && $local_jc ne $join_col;
				for my $k (keys %{$src}) {
					if ($rename && $k eq $local_jc) {
						$merged{$join_col} = $src->{$k};
					} else {
						$merged{$k} = $src->{$k};
					}
				}
			}

			delete @merged{@removed} if @removed;
			push @result, \%merged;
		}
	}

	return \@result;
}

# _merge_criteria( \%base, \%extra ) -> \%merged
# Purpose: Merge two criteria hashrefs for the same database column set.
# Entry:   %base is the permanent filter; %extra is the query-time criteria.
# Exit:    Returns a new hashref with both applied.
# Merging rule: when both values for the same column are operator hashrefs
#   (e.g. { '>' => 60 } and { '<' => 365 }), the operators are combined
#   so both constraints apply simultaneously (AND semantics).
#   Otherwise the extra (query-time) value overwrites the base value.
sub _merge_criteria :Protected {
	my ($base, $extra) = @_;
	my %merged = %{$base};
	for my $col (keys %{$extra}) {
		if (exists $merged{$col}
		        && ref($merged{$col}) eq 'HASH'
		        && ref($extra->{$col}) eq 'HASH') {
			$merged{$col} = { %{ $merged{$col} }, %{ $extra->{$col} } };
		} else {
			$merged{$col} = $extra->{$col};
		}
	}
	return \%merged;
}

# _msg( $i18n, $key, @sprintf_args ) -> $string
# Purpose: Format a user-facing message, routing through the i18n object when
#          one is provided.  Falls back to the built-in %MESSAGES dictionary.
# Entry:   $i18n may be undef.  $key must be a key in %MESSAGES.
# Exit:    Returns the formatted string.
sub _msg :Protected {
	my ($i18n, $key, @args) = @_;

	if ($i18n && $i18n->can('translate')) {
		return $i18n->translate($key, @args);
	}

	my $fmt = $MESSAGES{$key}
		// sprintf($MESSAGES{error_unknown_message}, $key);

	return @args ? sprintf($fmt, @args) : $fmt;
}

1;

__END__

=head1 MESSAGES

The following messages can be produced by C<Database::Join>.  All messages
can be localised by supplying an C<i18n> object to C<new>.

=over 4

=item C<error_no_databases>

B<When:> The C<databases> arrayref passed to C<new> is empty.

B<Fix:> Pass at least one C<Database::Abstraction> subclass object.

=item C<error_invalid_db>

B<When:> An element of the C<databases> array (or the argument to
C<add_database>) is not an object, or is not a C<Database::Abstraction>
subclass.

B<Fix:> Instantiate the component database with its own C<new> method before
passing it to C<Database::Join>.

=item C<error_join_col_missing>

B<When:> The join key column (or its C<join_map> alias) does not exist in one
of the component databases.

B<Fix:> Either add the column to the database, change C<join_column> to a
column that is present everywhere, or use C<join_map> to declare the local
alias for databases that call it something different.

=item C<error_remove_join_col>

B<When:> C<remove_column> is called with the name of the join key column.

B<Fix:> The join key is required for the merge to work and cannot be hidden.
Remove a different column.

=item C<warn_unknown_column> (carp)

B<When:> A criterion is passed for a column that does not exist in any
component database (or has been removed with C<remove_column>).

B<Fix:> Check the column name spelling.  The criterion is ignored.

=item C<error_query_unsupported>

B<When:> C<query()> is called on a C<Database::Join> object.

B<Fix:> Use C<selectall_arrayref>, C<selectall_array>, C<fetchrow_hashref>,
or C<count> instead.

=item C<error_execute_unsupported>

B<When:> C<execute()> is called on a C<Database::Join> object.

B<Fix:> Use the Perl-level query methods instead.  Raw SQL cannot span
heterogeneous database backends.

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Database-Join>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Database-Join/coverage/>

=item * L<Database::Abstraction>

=back

=head1 SECURITY CONSIDERATIONS

C<Database::Join> is a pure in-memory routing and merge layer.  It never
generates SQL strings, never opens files, and never calls C<system()>,
C<exec()>, or C<eval()>.  The security properties described below are
architectural guarantees, not run-time checks.

=head2 What Database::Join guarantees

=over 4

=item Criteria partition isolation

Every criterion you pass to a query method is routed to I<exactly one>
component database (the one that owns that column), or to I<all> databases
when the criterion is on the join key column.  A hostile value in a criterion
for column C<name> (owned by database A) will never reach database B.

=item Unknown columns are rejected before reaching any database

If a criterion column name is not present in any component database (or has
been hidden with C<remove_column>), C<Database::Join> logs a C<carp> warning
and silently drops the criterion.  No database receives the hostile key.

=item AUTOLOAD only accepts word-character column names

Perl's method dispatch extracts the column name via C<\w+>, which matches only
C<[A-Za-z0-9_]>.  Hostile method names with shell metacharacters, quotes, or
spaces cannot reach the AUTOLOAD dispatch path.  Private names (starting with
C<_>) are additionally blocked with an explicit C<croak>.

=item No value sanitisation (by design)

C<Database::Join> does I<not> sanitise, HTML-encode, or validate the
I<values> in criteria hashrefs.  Preventing SQL injection is the
responsibility of the underlying C<Database::Abstraction> objects (which use
parameterised queries).  Preventing XSS or header injection is the
responsibility of the CGI or web layer that renders the output.

=item Taint-mode compatible

C<Database::Join> contains no C<system()>, C<exec()>, backtick, C<open(PIPE)>,
or C<eval STRING> calls.  It neither opens files nor constructs shell commands.
The AUTOLOAD regex C</::(\w+)$/>  produces an I<untainted> capture, so the
column name used for dispatch is clean under C<-T>.  Criteria values are
passed verbatim to component C<Database::Abstraction> objects; those objects
are responsible for handling tainted values at the SQL parameterisation layer.

=item Operator hashref aliasing

When the same join-key criterion (an operator hashref such as
C<< { '>' => 'A' } >>) is broadcast to multiple component databases, all of
them receive a reference to the I<same> hashref.  A malicious component
database that mutates the hashref's contents could affect what subsequent
databases receive.  Component databases are assumed to be trusted.

=back

=head2 What the caller is responsible for

=over 4

=item Sanitise values before building criteria

DJ passes criterion values verbatim to component databases.  If your
application accepts user-supplied filter values (e.g. from a CGI query
string), those values I<must> be validated or sanitised by your application
before being passed to DJ.

=item Restrict which columns the caller can filter on

Any column in C<columns()> can be used as a filter criterion.  If a column
should not be filterable by end users (e.g. an internal status flag), hide it
with C<remove_column> so that queries on it are silently dropped.

=item Do not expose the joined view directly to user-supplied criteria

DJ is not a firewall.  It faithfully routes user input to component databases.
Wrap DJ calls in a thin service layer that whitelists the permitted criterion
columns and validates their values.

=back

=head3 API SPECIFICATION (security surface)

    Input accepted by all query methods and passed through DJ to component databases:

    Criterion values:
        type: scalar string | operator hashref { OP => scalar }
        validation: NONE (DJ trusts the caller; component DA is responsible)
        max size: unconstrained (OOM risk on very large values)

    Column name keys in criteria:
        type: string
        validation: must be present in _col_db (else carp + drop)
        character set: any Perl string (including control chars); DJ does
                       not impose a character-set restriction on criteria KEYS

    AUTOLOAD method-name-as-column:
        type: \w+ (enforced by Perl regex /::(\w+)$/)
        validation: must not start with '_'; must be in _col_db

=encoding UTF-8

=head1 FORMAL SPECIFICATION

Z calculus schemas for the key invariants and operations.
Unicode is used throughout this section as required by Z notation.

    ─── Database_Join ─────────────────────────────────────────────────
    dbs        : seq DATABASE_ABSTRACTION
    join_col   : NAME
    join_type  : {left, inner, outer}
    join_map   : ℕ ⇸ NAME
    filters    : ℕ ⇸ CRITERIA
    col_db     : NAME ⇸ ℕ
    removed    : ℙ NAME
    ───────────────────────────────────────────────────────────────────
    #dbs ≥ 1
    dom join_map ⊆ 0 ‥ (#dbs - 1)
    dom filters  ⊆ 0 ‥ (#dbs - 1)
    dom col_db   = (⋃ { i : 0 ‥ #dbs-1 • ran((dbs i).columns) }) \ removed
    join_col ∉ removed
    ∀ i : 0 ‥ #dbs-1 •
        local_jc(i) = if i ∈ dom join_map then join_map(i) else join_col
    ∀ i : 0 ‥ #dbs-1 •
        local_jc(i) ∈ ran((dbs i).columns)

    ─── Init ──────────────────────────────────────────────────────────
    ΔDatabase_Join
    dbs?       : seq DATABASE_ABSTRACTION
    join_col?  : NAME
    join_type? : {left, inner, outer}
    join_map?  : ℕ ⇸ NAME
    filters?   : ℕ ⇸ CRITERIA
    removed?   : ℙ NAME
    ───────────────────────────────────────────────────────────────────
    #dbs? ≥ 1
    dbs'      = dbs?
    join_col' = join_col?
    join_type'= join_type?
    join_map' = join_map?
    filters'  = filters?
    col_db'   = buildColIndex(dbs?, join_col?, join_map?)
    removed'  = removed?

    ─── SelectAllArrayref ─────────────────────────────────────────────
    ΞDatabase_Join        -- state unchanged
    criteria? : CRITERIA
    result!   : seq MERGED_ROW
    ───────────────────────────────────────────────────────────────────
    ∀ c : dom criteria? • c ∈ dom col_db ∪ {join_col}
    result! = joinedQuery(criteria?)
    result! is sorted ascending by join_col value

    ─── AddDatabase ───────────────────────────────────────────────────
    ΔDatabase_Join
    db?         : DATABASE_ABSTRACTION
    local_jc?   : NAME   -- optional; defaults to join_col
    filter?     : CRITERIA   -- optional
    remove?     : ℙ NAME     -- optional
    ───────────────────────────────────────────────────────────────────
    db?.isa('Database::Abstraction')
    local_jc? ∈ ran(db?.columns)
    dbs'      = dbs ^ ⟨db?⟩
    col_db'   = col_db ⊕ { c ↦ #dbs | c ∈ ran(db?.columns) \ {local_jc?} \ removed }
    filters'  = if filter? ≠ ∅ then filters ⊕ {#dbs ↦ filter?} else filters
    join_map' = if local_jc? ≠ join_col
                then join_map ⊕ {#dbs ↦ local_jc?}
                else join_map
    removed'  = removed ∪ remove?

    ─── RemoveColumn ──────────────────────────────────────────────────
    ΔDatabase_Join
    col? : NAME
    ───────────────────────────────────────────────────────────────────
    col? ≠ join_col
    removed'  = removed ∪ {col?}
    col_db'   = col_db \ {col?}
    join_map' = join_map
    filters'  = filters
    dbs'      = dbs

=head2 join_map

    ─── JoinMap ───────────────────────────────────────────────────────
    join_map : ℕ ⇸ NAME
    dbs      : seq DATABASE_ABSTRACTION
    join_col : NAME
    ───────────────────────────────────────────────────────────────────
    dom join_map ⊆ 0 ‥ (#dbs - 1)
    ∀ i : dom join_map • (join_map i) ∈ ran(dbs i).columns
    ∀ i : 0 ‥ (#dbs - 1) \ dom join_map •
        join_col ∈ ran(dbs i).columns

    -- Resolution of the local join-key name for database i:
    local_jc(i) == if i ∈ dom join_map then join_map(i) else join_col

    -- The canonical name is always join_col; local_jc is never exposed.

=head2 SECURITY INVARIANTS

    ─── PartitionIsolation ─────────────────────────────────────────────
    -- For every query call with criteria C and column col ≠ join_col:
    ∀ i : 0 ‥ #dbs-1 •
        i ≠ _col_db(col)  ⟹  col ∉ dom(per_db(i))

    -- Unknown column is dropped before any database sees it:
    col ∉ dom(_col_db) ∧ col ≠ join_col  ⟹
        (∀ i : 0 ‥ #dbs-1 • col ∉ dom(per_db(i)))

    ─── NoCodeExecution ────────────────────────────────────────────────
    -- DJ contains no call to system(), exec(), open(PIPE), or eval().
    -- Hostile criterion values therefore cannot achieve code execution
    -- within the Database::Join layer.
    ∀ v : VALUE • _joined_query({col ↦ v}) ≠ ⊥ due to code injection

=head2 filters

    ─── Filters ─────────────────────────────────────────────────────
    filters  : ℕ ⇸ CRITERIA
    dbs      : seq DATABASE_ABSTRACTION
    ─────────────────────────────────────────────────────────────────
    dom filters ⊆ 0 ‥ (#dbs - 1)

    -- A filtered database i always contributes to key-set intersection.
    -- For each query with criteria C:
    effective_criteria(i, C) ==
        if i ∈ dom filters
        then merge_criteria(filters(i), partition(C, i))
        else partition(C, i)

    -- Criteria merging (AND semantics for operator hashrefs):
    merge_criteria(base, extra) ==
        { col : dom base ∪ dom extra •
            if col ∈ dom base ∩ dom extra
               ∧ base(col) ∈ HASHREF ∧ extra(col) ∈ HASHREF
            then col ↦ base(col) ∪ extra(col)   -- operator union
            else col ↦ (if col ∈ dom extra then extra(col) else base(col)) }

=head2 selectall_arrayref

    selectall_arrayref : CRITERIA → seq MERGED_ROW
    pre:  ∀ col : dom criteria • col ∈ dom self._col_db ∪ {self._join_col}
    post: result = _joined_query(criteria)
          result is sorted ascending by join_col value

=head2 selectall_array

    selectall_array : CRITERIA → seq MERGED_ROW | MERGED_ROW?
    pre:  same as selectall_arrayref
    post: wantarray  => result = @{ selectall_arrayref(criteria) }
          !wantarray => result = selectall_arrayref(criteria)[0]  (or undef)

=head2 fetchrow_hashref

    fetchrow_hashref : CRITERIA → MERGED_ROW?
    post: result = selectall_arrayref(criteria)[0]  (or undef if empty)

=head2 count

    count : CRITERIA → ℕ
    post: result = #selectall_arrayref(criteria)

=head2 columns

    columns : → seq NAME
    post: result = sort(
              (⋃ { i : 0 ‥ #dbs-1 • ran(dbs(i).columns) }
               \ dom removed_cols
               \ { local_jc(i) | i ∈ dom join_map ∧ local_jc(i) ≠ join_col })
          )

=head2 schema

    schema : → NAME ⇸ SCHEMA_INFO
    post: dom(result) = ran(columns())
          ∀ col : dom(result) •
              result(col) = (last database containing col).schema()(col)

=head2 updated

    updated : → ℕ
    post: result = max { i : 0 ‥ #dbs-1 • dbs(i).updated() }

=head2 remove_column

    remove_column : NAME → Database_Join
    pre:  col ≠ self._join_col
    post: self'._removed_cols = self._removed_cols ∪ {col}
          self'._col_db       = self._col_db \ {col}
          self'._col_cache    = undef
          self'._schema_cache = undef

=head2 AUTOLOAD

    AUTOLOAD : NAME × CRITERIA → VALUE | seq VALUE
    pre:  col ∈ dom self._col_db
          col does not begin with '_'
    post: let rows = _joined_query(criteria)
          wantarray  => result = { r : rows • r(col) }
          !wantarray => result = rows(0)(col)  (or undef if rows is empty)

=head1 AUTHOR

Nigel Horne, C<< <njh@nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut
