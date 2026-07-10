package Database::Abstraction::Query;

# Chained query builder for Database::Abstraction objects.
# Returned by $db->query() and used as:
#   $db->query->where(col => val)->order_by('col')->limit(10)->all()

use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);

=head1 NAME

Database::Abstraction::Query - Fluent, chainable query builder for Database::Abstraction

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';

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
C<offset>) all return C<$self>, so calls can be chained in any order.

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
	$self->{'_limit'} = $n;
	return $self;
}

=head2 offset

    $q->offset(40);

Skip the first N rows (for pagination with L</limit>).  Returns C<$self>.

=cut

sub offset
{
	my ($self, $n) = @_;
	$self->{'_offset'} = $n;
	return $self;
}

# Apply Perl-side sort, offset, and limit to an arrayref of rows in place.
# Used by the BerkeleyDB execution paths in all() and first().
# order_by must be a single "column [ASC|DESC]" string (multi-column not supported).
sub _apply_perl_sort_limit
{
	my ($rows, $order_by, $offset, $limit) = @_;

	if(defined $order_by) {
		my ($col, $dir) = ($order_by =~ /^(\S+)(?:\s+(ASC|DESC))?$/i);
		$dir //= 'ASC';
		@{$rows} = sort {
			$dir =~ /DESC/i
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

	my $db    = $self->{'_db'};
	my $table = $db->{'table'} || ref($db);
	$table =~ s/.*:://;

	# Ensure the underlying table connection is open
	$db->_open_table({});

	my $select = $count_only ? 'COUNT(*)' : $self->{'_select'};
	my $query  = "SELECT $select FROM $table";

	if(@{$self->{'_joins'}}) {
		$query .= ' ' . $db->_build_joins($self->{'_joins'});
	}

	my ($where, $wargs) = $db->_build_where($self->{'_where'});
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

=cut

sub all
{
	my $self = shift;
	my $db   = $self->{'_db'};

	# Ensure _open() fires before checking the backend type.
	$db->_open_table({});

	if($db->{'berkeley'}) {
		croak(ref($db), ': query->all() with JOINs is not supported on BerkeleyDB')
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

=cut

sub first
{
	my $self = shift;
	my $db   = $self->{'_db'};

	$db->_open_table({});

	if($db->{'berkeley'}) {
		croak(ref($db), ': query->first() with JOINs is not supported on BerkeleyDB')
			if @{$self->{'_joins'}};
		my $rows = $db->selectall_arrayref({%{$self->{'_where'}}});
		_apply_perl_sort_limit($rows, $self->{'_order_by'}, $self->{'_offset'}, undef);
		return $rows->[0];
	}

	my $saved = $self->{'_limit'};
	$self->{'_limit'} = 1;
	my ($query, $args, $table) = $self->_build_sql(0);
	$self->{'_limit'} = $saved;

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

=cut

sub count
{
	my $self = shift;
	my $db   = $self->{'_db'};

	$db->_open_table({});

	if($db->{'berkeley'}) {
		croak(ref($db), ': query->count() with JOINs is not supported on BerkeleyDB')
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

=head1 SEE ALSO

L<Database::Abstraction> - the parent module and its L<Database::Abstraction/QUERY CRITERIA> section.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SUPPORT

Please report bugs at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction>.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut

1;
