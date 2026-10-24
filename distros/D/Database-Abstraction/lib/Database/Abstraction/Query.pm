package Database::Abstraction::Query;

# Chained query builder for Database::Abstraction objects.
# Returned by $db->query() and used as:
#   $db->query->where(col => val)->order_by('col')->limit(10)->all()

use strict;
use warnings;
use autodie qw(:all);

use Carp;
use Scalar::Util qw(blessed);

=encoding utf8

=head1 NAME

Database::Abstraction::Query - Fluent, chainable query builder for Database::Abstraction

=head1 VERSION

Version 0.51

=cut

our $VERSION = '0.52';

=head1 SYNOPSIS

    my $db = Database::Foo->new(directory => '/path/to/data');

    # --- Basic usage -----------------------------------------------

    # All rows
    my $all = $db->query->all();

    # Filter, sort, page
    my $rows = $db->query
        ->where(status => 'active')
        ->where(score  => { '>=' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->offset(20)
        ->all();

    # Single row
    my $row = $db->query->where(name => 'Alice')->first();

    # Count
    my $n = $db->query->where(status => 'active')->count();

    # --- Specific columns ------------------------------------------

    my $names = $db->query->select('name, score')->where(status => 'active')->all();

    # --- Joins -----------------------------------------------------

    my $joined = $db->query
        ->join({ table => 'dept', on => 'e.dept_id = dept.id', type => 'LEFT' })
        ->where(dept_name => 'Engineering')
        ->all();

    # --- OR criteria -----------------------------------------------

    my $either = $db->query
        ->where(-or => [
            { status => 'active'           },
            { score  => { '>=' => 95 }     },
        ])
        ->all();

=head1 DESCRIPTION

C<Database::Abstraction::Query> is a fluent query builder returned by
C<< $db->query() >>.  You assemble a query by chaining builder methods,
then execute it with a terminal method.

=over 4

=item *

B<Builder methods> (C<select>, C<where>, C<join>, C<order_by>, C<limit>,
C<offset>, C<group_by>, C<measure>, C<having>) all return C<$self>, so
calls can be chained in any order.

=item *

B<Terminal methods> (C<all>, C<first>, C<count>) assemble the SQL, execute
it, and return the result.  Each terminal method can be called on the same
builder object independently - calling C<first()> does not modify the stored
state (it temporarily sets LIMIT 1 internally).

=item *

C<where()> calls are B<merged with AND semantics>: each call adds more
required conditions.  To express OR conditions pass C<< -or => [...] >> as a
key inside a single C<where()> call.

=item *

The C<join> parameter accepts the same spec as the C<join> parameter in
L<Database::Abstraction/QUERY CRITERIA>.

=item *

BerkeleyDB backends support C<all()>, C<first()>, and C<count()> with
C<where()> criteria and C<order_by()>/C<limit()>/C<offset()> applied in Perl.
The C<join()> builder method and the C<select()> column projection are not
supported on BerkeleyDB and will raise an error.

=back

=head1 METHODS

=cut

=head2 new

    my $q = Database::Abstraction::Query->new(_db => $db_object);

Construct a new, empty query builder bound to C<$db_object>.  In practice
you almost always call this via C<< $db->query() >> instead.

=cut

sub new
{
	my ($class, %args) = @_;

	my $db = $args{'_db'}
		or croak('Database::Abstraction::Query: _db is required');

	croak('Database::Abstraction::Query: _db must be a Database::Abstraction object')
		unless blessed($db) && $db->isa('Database::Abstraction');

	return bless {
		_db       => $db,
		_select   => '*',
		_where    => {},
		_joins    => [],
		_order_by => undef,
		_limit    => undef,
		_offset   => undef,
		_group_by => [],
		_measures => [],
		_having   => {},
	}, $class;
}

=head2 select

    $q->select('name, score');
    $q->select('COUNT(*) AS n, status');

Set the column expression for the C<SELECT> clause.  Default is C<*> (all
columns).  Returns C<$self>.

=cut

sub select
{
	my ($self, $cols) = @_;
	$self->{'_select'} = defined($cols) ? $cols : '*';
	return $self;
}

=head2 where

    $q->where(status => 'active');
    $q->where(score  => { '>'  => 8     });
    $q->where(name   => { -in  => [...] });
    $q->where(-or    => [ {...}, {...}     ]);

Add one or more criteria to the query.  Multiple calls are merged with
AND semantics.  Accepts a flat list of key/value pairs or a single hashref.

Supports the full criteria syntax of L<Database::Abstraction/QUERY CRITERIA>:
plain scalars, wildcard strings, C<undef> (IS NULL), comparison operator
hashrefs (C<< { '>' => n } >>), C<-in>, C<-not_in>, C<-between>,
C<-like>, C<-not_like>, C<-or>, and C<-and>.

Returns C<$self>.

=cut

sub where
{
	my $self = shift;
	my %criteria = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
	for my $k (keys %criteria) {
		$self->{'_where'}{$k} = $criteria{$k};
	}
	return $self;
}

=head2 join

    $q->join({ table => 'dept', on => 'e.dept_id = dept.id', type => 'LEFT' });

    # Multiple joins at once
    $q->join([
        { table => 'dept',    on => 'e.dept_id    = dept.id'    },
        { table => 'country', on => 'e.country_id = country.id' },
    ]);

Append one or more JOIN specs.  Each spec is a hashref with:

=over 4

=item * C<table> - the table to join (required)

=item * C<on> - the join condition, verbatim SQL (required)

=item * C<type> - join type: C<INNER> (default), C<LEFT>, C<RIGHT>, C<FULL>, C<CROSS>

=back

Multiple calls accumulate joins.  Returns C<$self>.

=cut

sub join	## no critic(ProhibitBuiltinHomonyms)
{
	my ($self, $spec) = @_;
	my @specs = ref($spec) eq 'ARRAY' ? @{$spec} : ($spec);
	push @{$self->{'_joins'}}, @specs;
	return $self;
}

=head2 order_by

    $q->order_by('name DESC');
    $q->order_by('score DESC, name ASC');

Set the C<ORDER BY> expression.  Replaces any previously set ordering.
Returns C<$self>.

=cut

sub order_by
{
	my ($self, $col) = @_;
	# Guard the three primary SQL injection vectors before the value is
	# interpolated verbatim into ORDER BY $col (see _build_sql).  The check
	# is deliberately permissive so it does not break legitimate multi-column
	# expressions ("score DESC, name ASC") or SQL functions ("ABS(score) DESC").
	if(defined $col) {
		# Block the three primary SQL injection vectors that can appear inside
		# an ORDER BY expression.  Use m{} to avoid escaping '/' and '\*'.
		croak("order_by: unsafe ORDER BY expression '$col'")
			if $col =~ m{; | -- | /\*}x;
	}
	$self->{'_order_by'} = $col;
	return $self;
}

=head2 limit

    $q->limit(20);

Set the maximum number of rows to return.  Returns C<$self>.

=cut

sub limit
{
	my ($self, $n) = @_;
	# Validate at the setter: LIMIT must be a non-negative integer.
	# Direct interpolation into SQL (line: LIMIT $n) makes any non-integer a
	# potential injection vector (e.g. "10; DROP TABLE users").
	croak("limit: value must be a non-negative integer")
		if !defined($n) || $n !~ /\A\d+\z/;
	$self->{'_limit'} = int($n);
	return $self;
}

=head2 offset

    $q->offset(40);

Skip the first N rows (for pagination with L</limit>).  Returns C<$self>.

=cut

sub offset
{
	my ($self, $n) = @_;
	# Same guard as limit(): OFFSET is interpolated directly into SQL.
	croak("offset: value must be a non-negative integer")
		if !defined($n) || $n !~ /\A\d+\z/;
	$self->{'_offset'} = int($n);
	return $self;
}

=head2 group_by

    $q->group_by('region', 'month');
    $q->group_by(\@cols);
    $q->group_by([]);    # clear (grand total)

Set the C<GROUP BY> columns for an aggregate query.  Replaces any previously
set list.  Has no effect unless at least one C<measure()> call follows.
Returns C<$self>.

=head3 API SPECIFICATION

=head4 Arguments

    @cols   # one or more column name strings (replaces any previous group_by)

=head4 Returns

    $self   (the same Query object, for chaining)

=cut

sub group_by
{
	my $self = shift;
	my @cols = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? @{$_[0]} : @_;
	$self->{'_group_by'} = \@cols;
	return $self;
}

=head2 measure

    $q->measure('amount', 'sum', 'revenue');
    $q->measure(undef, 'count', 'orders');       # COUNT(*)
    $q->measure({ col => 'c', fn => 'avg', as => 'mean' });

Append a measure to the aggregate query.  May be called multiple times;
measures accumulate.  Accepts either three positional arguments
(C<col>, C<fn>, C<as>) or a single hashref with those keys.

C<fn> must be one of C<sum>, C<avg>, C<min>, C<max>, C<count>,
C<count_distinct>.  C<col> is optional only for C<count> (COUNT(*)).

Returns C<$self>.

=head3 API SPECIFICATION

=head4 Arguments

    $col  # Str | undef -- column to aggregate; omit/undef for COUNT(*)
    $fn   # Str         -- one of: sum avg min max count count_distinct
    $as   # Str         -- result key alias (required; valid SQL identifier)

=head4 Returns

    $self   (the same Query object, for chaining)

Calls to C<measure()> accumulate: each call appends one measure to
the list.  To start over, create a new query builder with
C<< $db->query() >>.

=cut

sub measure
{
	my ($self, $col_or_spec, $fn, $as) = @_;
	my $spec = ref($col_or_spec) eq 'HASH'
		? $col_or_spec
		: { col => $col_or_spec, fn => $fn, as => $as };
	push @{$self->{'_measures'}}, $spec;
	return $self;
}

=head2 having

    $q->having(revenue => { '>' => 1000 });
    $q->having(\%criteria);

Add post-aggregation filter criteria.  Multiple calls are merged with AND
semantics, exactly like C<where()>.  Keys must be C<by> column names or
measure aliases (validated by C<aggregate()>).

Returns C<$self>.

=head3 API SPECIFICATION

=head4 Arguments

    %criteria   # key-value pairs where each key is a by-column name or
                # a measure alias, and each value is a scalar or an
                # operator hashref (same syntax as selectall_arrayref)

=head4 Returns

    $self   (the same Query object, for chaining)

Multiple calls to C<having()> are merged with AND semantics, exactly
like multiple calls to C<where()>.

=cut

sub having
{
	my $self = shift;
	my %criteria = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
	for my $k (keys %criteria) {
		$self->{'_having'}{$k} = $criteria{$k};
	}
	return $self;
}

# Apply Perl-side sort, offset, and limit to an arrayref of rows in place.
# Used by the BerkeleyDB execution paths in all() and first().
# order_by must be a single "column [ASC|DESC]" string (multi-column not supported).
sub _apply_perl_sort_limit
{
	my ($rows, $order_by, $offset, $limit) = @_;

	if(defined $order_by) {
		# Use \z (true end-of-string) not $ (matches before a trailing newline).
		# (ASC|DESC) is already a non-regex check after capture; $dir is either
		# 'ASC', 'DESC', or undef — hoist the direction decision out of the sort
		# comparator so it is not evaluated O(N log N) times for an N-row result.
		my ($col, $dir) = ($order_by =~ /
			\A
			(\S+)           # column expression (non-whitespace)
			(?:
				\s+         # whitespace separator
				(ASC|DESC)  # sort direction keyword
			)?
			\z
		/xi);
		$dir //= 'ASC';
		my $desc = ($dir eq 'DESC');	# evaluated once, not on every comparison
		@{$rows} = sort {
			$desc
				? (($b->{$col} // '') cmp ($a->{$col} // ''))
				: (($a->{$col} // '') cmp ($b->{$col} // ''))
		} @{$rows};
	}
	splice(@{$rows}, 0, $offset) if $offset;
	splice(@{$rows}, $limit)     if defined $limit;
}

# Internal: assemble SQL + bind args.  $count_only replaces SELECT cols with COUNT(*).
sub _build_sql
{
	my ($self, $count_only) = @_;

	my $db = $self->{'_db'};

	# _open_table populates $db->{'_table_name'} as a side-effect, so call it
	# first and then read the cache directly — avoids a second ref()+regex.
	$db->_open_table({});
	my $table = $db->{'_table_name'};

	my $select = $count_only ? 'COUNT(*)' : $self->{'_select'};
	my $query  = "SELECT $select FROM $table";

	if(@{$self->{'_joins'}}) {
		$query .= ' ' . $db->_build_joins($self->{'_joins'});
	}

	my $qwhere = $db->{'base_criteria'}
		? { %{$db->{'base_criteria'}}, %{$self->{'_where'}} }
		: $self->{'_where'};
	my ($where, $wargs) = $db->_build_where($qwhere);
	my @args = @{$wargs};

	if(@{$self->{'_joins'}}) {
		$query .= " WHERE $where" if $where;
	} elsif(($db->{'type'} eq 'CSV') && !$db->{'no_entry'}) {
		my $id = $db->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}

	unless($count_only) {
		$query .= " ORDER BY $self->{'_order_by'}" if defined $self->{'_order_by'};
		$query .= " LIMIT $self->{'_limit'}"       if defined $self->{'_limit'};
		$query .= " OFFSET $self->{'_offset'}"     if defined $self->{'_offset'};
	}

	return ($query, \@args, $table);
}

=head2 all

    my $rows = $q->all();

B<Terminal method.>  Executes the assembled query and returns an array
reference of hash references, one per matching row.  Returns an empty
array reference when there are no matches (never C<undef>).

=head3 API SPECIFICATION

=head4 Arguments

None.  All query parameters are set via the builder methods before
calling C<all()>.

=head4 Returns

    ArrayRef[HashRef]

An arrayref of row hashrefs.  Returns C<[]> (empty arrayref) when
no rows match -- never C<undef>.  Each hashref is read-only unless
the database was constructed with C<< no_fixate => 1 >>.

When C<measure()> has been called, delegates to C<< $db->aggregate() >>
and returns grouped rows (see L<Database::Abstraction/aggregate>).

=cut

sub all
{
	my $self = shift;
	my $db   = $self->{'_db'};

	# Ensure _open() fires before checking the backend type.
	$db->_open_table({});

	# Aggregate path: delegate to $db->aggregate when measures have been set.
	if(@{$self->{'_measures'}}) {
		my %ap = (%{$self->{'_where'}}, measures => $self->{'_measures'});
		$ap{'by'}     = $self->{'_group_by'} if @{$self->{'_group_by'}};
		$ap{'having'} = $self->{'_having'}   if %{$self->{'_having'}};
		if(@{$self->{'_joins'}}) {
			$ap{'join'} = $self->{'_joins'};
		}
		if(defined $self->{'_order_by'}) {
			# Parse "col [ASC|DESC]" from order_by into sort_by format.
			# Multi-column order_by expressions are not supported for aggregates;
			# only the first token is used.
			my ($col, $dir) = ($self->{'_order_by'} =~ /\A(\S+)(?:\s+(ASC|DESC))?\z/i);
			$ap{'sort_by'} = defined($col)
				? (defined($dir) ? [$col, uc($dir)] : $col)
				: undef;
			delete $ap{'sort_by'} unless defined $ap{'sort_by'};
		}
		$ap{'limit'}  = $self->{'_limit'}  if defined $self->{'_limit'};
		$ap{'offset'} = $self->{'_offset'} if defined $self->{'_offset'};
		return $db->aggregate(%ap);
	}

	if($db->{'berkeley'} || ($db->{'type'} // '') =~ /\A(?:Deep|XLSX)\z/) {
		my $backend = $db->{'berkeley'} ? 'BerkeleyDB' : ($db->{'type'} // '');
		croak(ref($db), ": query->all() with JOINs is not supported on $backend")
			if @{$self->{'_joins'}};
		my $rows = $db->selectall_arrayref({%{$self->{'_where'}}});
		_apply_perl_sort_limit($rows, $self->{'_order_by'}, $self->{'_offset'}, $self->{'_limit'});
		return $rows;
	}

	my ($query, $args, $table) = $self->_build_sql(0);
	$db->_debug("Query->all: $query");

	my $sth = $db->{$table}->prepare_cached($query);
	$sth->execute(@{$args}) or croak("$query: @{$args}");

	my @rows;
	while(my $row = $sth->fetchrow_hashref()) {
		push @rows, $row;
	}
	return \@rows;
}

=head2 first

    my $row = $q->first();    # \%hashref or undef

B<Terminal method.>  Executes the query with C<LIMIT 1> and returns the
first matching row as a hash reference, or C<undef> when there is no match.
Any C<limit()> or C<offset()> you have set is temporarily overridden for
efficiency (only the LIMIT is overridden; offset is still applied).

=head3 API SPECIFICATION

=head4 Arguments

None.

=head4 Returns

    HashRef | undef

The first matching row hashref, or C<undef> when no row matches.
Internally applies C<LIMIT 1> for SQL backends; for in-memory
backends it returns the first element of the sorted result.

When C<measure()> has been called, returns the first aggregate group
row (the same as C<< ->all()->[0] >>).

=cut

sub first
{
	my $self = shift;
	my $db = $self->{'_db'};

	$db->_open_table({});

	if(@{$self->{'_measures'}}) {
		local $self->{'_limit'} = 1;
		my $rows = $self->all();
		return ref($rows) eq 'ARRAY' ? $rows->[0] : undef;
	}

	if($db->{'berkeley'} || ($db->{'type'} // '') =~ /\A(?:Deep|XLSX)\z/) {
		my $backend = $db->{'berkeley'} ? 'BerkeleyDB' : ($db->{'type'} // '');
		croak(ref($db), ": query->first() with JOINs is not supported on $backend")
			if @{$self->{'_joins'}};
		my $rows = $db->selectall_arrayref({%{$self->{'_where'}}});
		_apply_perl_sort_limit($rows, $self->{'_order_by'}, $self->{'_offset'}, undef);
		return $rows->[0];
	}

	# local on a hash element (supported since Perl 5.8.1) is exception-safe:
	# even if _build_sql() croaks, _limit is automatically restored on unwind.
	# The previous save/restore pair left _limit permanently at 1 on exception.
	local $self->{'_limit'} = 1;
	my ($query, $args, $table) = $self->_build_sql(0);

	$db->_debug("Query->first: $query");

	my $sth = $db->{$table}->prepare_cached($query);
	$sth->execute(@{$args}) or croak("$query: @{$args}");

	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}

=head2 count

    my $n = $q->count();

B<Terminal method.>  Executes C<SELECT COUNT(*)> with the current C<WHERE>
and C<JOIN> clauses and returns the integer count.  C<ORDER BY>, C<LIMIT>,
and C<OFFSET> are ignored for the count query.

=head3 API SPECIFICATION

=head4 Arguments

None.

=head4 Returns

    Int (>= 0)

The number of matching rows.  Returns C<0> when nothing matches --
never C<undef>.

B<Restriction:> croaks with
C<"count() is not available once measure() has been called">
if any C<measure()> call has been made on this query builder.  Use
C<all()> and examine C<scalar @{$rows}> instead.

=cut

sub count
{
	my $self = shift;
	my $db   = $self->{'_db'};

	$db->_open_table({});

	croak('Database::Abstraction::Query: count() is not available once measure() has been called')
		if @{$self->{'_measures'}};

	if($db->{'berkeley'} || ($db->{'type'} // '') =~ /\A(?:Deep|XLSX)\z/) {
		my $backend = $db->{'berkeley'} ? 'BerkeleyDB' : ($db->{'type'} // '');
		croak(ref($db), ": query->count() with JOINs is not supported on $backend")
			if @{$self->{'_joins'}};
		return $db->count({%{$self->{'_where'}}});
	}

	my ($query, $args, $table) = $self->_build_sql(1);
	$db->_debug("Query->count: $query");

	my $sth = $db->{$table}->prepare_cached($query);
	$sth->execute(@{$args}) or croak("$query: @{$args}");

	my $row = $sth->fetchrow_arrayref();
	$sth->finish();
	return $row ? $row->[0] : 0;
}

=head2 each

    $q->each(\&callback);
    $q->each(sub { my $row = shift; print $row->{'name'}, "\n" });

B<Terminal method.>  Iterates over matching rows one at a time, calling
C<\&callback> once per row with the row hashref as the sole argument.
Uses constant memory on the SQL path (see L<Database::Abstraction/each_row>).

Applies any C<where()>, C<join()>, C<order_by()>, C<limit()>, and C<offset()>
set on the builder.

Returns the number of rows passed to C<\&callback>.

=head3 API SPECIFICATION

=head4 Arguments

    CodeRef   # required: callback invoked with one row hashref per call

=head4 Returns

    Int (>= 0)

The number of rows visited.  Any exception thrown inside the callback
is re-thrown after the DBI statement handle is properly closed.

When C<measure()> has been called, each group row is passed to the
callback in the same order as C<all()> would return them.

=cut

sub each
{
	my ($self, $callback) = @_;
	my $db = $self->{'_db'};

	croak('Database::Abstraction::Query::each: callback must be a code reference')
		unless ref($callback) eq 'CODE';

	$db->_open_table({});

	# Aggregate path: collect all rows then iterate.  Not constant-memory.
	if(@{$self->{'_measures'}}) {
		my $rows = $self->all();
		my $n = 0;
		for my $row (@{$rows}) {
			local $_;
			$callback->($row);
			$n++;
		}
		return $n;
	}

	if($db->{'berkeley'} || ($db->{'type'} // '') =~ /\A(?:Deep|XLSX)\z/) {
		my $backend = $db->{'berkeley'} ? 'BerkeleyDB' : ($db->{'type'} // '');
		croak(ref($db), ": query->each() with JOINs is not supported on $backend")
			if @{$self->{'_joins'}};
		my $rows = $db->selectall_arrayref({%{$self->{'_where'}}});
		_apply_perl_sort_limit($rows, $self->{'_order_by'}, $self->{'_offset'}, $self->{'_limit'});
		my $n = 0;
		for my $row (@{$rows}) {
			local $_;
			$callback->($row);
			$n++;
		}
		return $n;
	}

	my ($query, $args, $table) = $self->_build_sql(0);
	$db->_debug("Query->each: $query");

	my $sth = $db->{$table}->prepare_cached($query);
	$sth->execute(@{$args}) or croak("$query: @{$args}");

	my $n = 0;
	eval {
		while(my $row = $sth->fetchrow_hashref()) {
			local $_;
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

=head1 SEE ALSO

L<Database::Abstraction> - the parent module and its L<Database::Abstraction/QUERY CRITERIA> section.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SUPPORT

Please report bugs at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction>.

=head1 COMMON PITFALLS

=over 4

=item B<C<where()> is AND, not OR>

Each call to C<where()> ANDs with all previous C<where()> calls.
Use C<< -or => [...] >> inside a single C<where()> call for OR logic.

=item B<C<measure()> calls accumulate>

Every C<measure()> call appends a new measure to the query.  To
build a fresh aggregate query call C<< $db->query() >> again rather
than re-using the same builder object.

=item B<C<group_by()> replaces, not appends>

Calling C<group_by()> a second time replaces the previous group-by
columns entirely.  It does not accumulate like C<measure()> or
C<where()>.

=item B<C<count()> is unavailable after C<measure()>>

Once you have called C<measure()> on a query builder, calling
C<count()> will croak.  Use C<all()> and check C<scalar @{$rows}>.

=item B<Sort column for aggregate queries must use C<order_by()>>

To sort aggregate results, call C<< ->order_by('col') >> on the
builder before C<< ->all() >>.  Passing C<sort_by> directly to
C<all()> has no effect because the terminal method ignores extra
arguments.

=back

=head1 FORMAL SPECIFICATION

=head2 Query builder state

    QueryState == [
        _db       : Database::Abstraction,
        _select   : Str,
        _where    : CRITERIA,
        _joins    : seq JOIN_SPEC,
        _order_by : Str | undef,
        _limit    : Int | undef,
        _offset   : Int | undef,
        _group_by : seq COLNAME,
        _measures : seq MEASURE_SPEC,
        _having   : CRITERIA
    ]

    Initial state Q0 == [
        _select?   = '*',
        _where?    = {},
        _joins?    = [],
        _order_by? = undef,
        _limit?    = undef,
        _offset?   = undef,
        _group_by? = [],
        _measures? = [],
        _having?   = {}
    ]

=head2 Builder method invariants

    where(C) ____________________________________________
    DeltaQueryState
    C? : CRITERIA
    ────────────────────────────────────────────────────
    post: _where' = _where UNION C   (AND semantics)

    measure(col, fn, as) ________________________________
    DeltaQueryState
    ────────────────────────────────────────────────────
    post: _measures' = _measures CONCAT [{col,fn,as}]

    group_by(cols) ______________________________________
    DeltaQueryState
    ────────────────────────────────────────────────────
    post: _group_by' = cols  (replaces previous value)

=head2 all() dispatch

    all _________________________________________________
    XiQueryState  (read-only)
    ────────────────────────────────────────────────────
    result == (_measures != empty
               IMPLIES _db.aggregate(_group_by, _measures, _where,
                                     _having, _order_by, _limit, _offset)
               ELSE    _db.selectall_arrayref(_where, _joins,
                                              _order_by, _limit, _offset))
    post: result : seq ROW

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
