package Alzabo::Runtime::Schema;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions ( abbr => [ qw( logic_exception params_exception ) ] );
use Alzabo::Runtime;
use Alzabo::Utils;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { params_exception join '', @_ } );

use base qw(Alzabo::Schema);

$VERSION = 2.0;

1;

sub load_from_file
{
    my $class = shift;

    my $self = $class->_load_from_file(@_);

    $self->prefetch_all_but_blobs;

    return $self;
}

sub _schema_file_type
{
    return 'runtime';
}

sub user
{
    my $self = shift;

    return $self->{user};
}

sub password
{
    my $self = shift;

    return $self->{password};
}

sub host
{
    my $self = shift;

    return $self->{host};
}

sub port
{
    my $self = shift;

    return $self->{port};
}

sub referential_integrity
{
    my $self = shift;

    return defined $self->{maintain_integrity} ? $self->{maintain_integrity} : 0;
}

sub set_db_schema_name
{
    my $self = shift;

    $self->{db_schema_name} = shift;
}

sub set_user
{
    my $self = shift;

    $self->{user} = shift;
}

sub set_password
{
    my $self = shift;

    $self->{password} = shift;
}

sub set_host
{
    my $self = shift;

    $self->{host} = shift;
}

sub set_port
{
    my $self = shift;

    $self->{port} = shift;
}

sub set_referential_integrity
{
    my $self = shift;
    my $val = shift;

    $self->{maintain_integrity} = $val if defined $val;
}

sub set_quote_identifiers
{
    my $self = shift;
    my $val = shift;

    $self->{quote_identifiers} = $val if defined $val;
}

sub connect
{
    my $self = shift;

    my %p;
    $p{user} = $self->user if defined $self->user;
    $p{password} = $self->password if defined $self->password;
    $p{host} = $self->host if defined $self->host;
    $p{port} = $self->port if defined $self->port;
    $self->driver->connect( %p, @_ );

#    $self->set_referential_integrity( ! $self->driver->supports_referential_integrity );
}

sub disconnect
{
    my $self = shift;

    $self->driver->disconnect;
}

sub one_row
{
    # could be replaced with something potentially more efficient
    return shift->join(@_)->next;
}

use constant JOIN_SPEC => { join => { type => ARRAYREF | OBJECT,
                                      optional => 1 },
                            tables => { type => ARRAYREF | OBJECT,
                                        optional => 1 },
                            select => { type => ARRAYREF | OBJECT,
                                        optional => 1 },
                            where => { type => ARRAYREF,
                                       optional => 1 },
                            order_by => { type => ARRAYREF | HASHREF | OBJECT,
                                          optional => 1 },
                            limit => { type => SCALAR | ARRAYREF,
                                       optional => 1 },
                            distinct => { type => ARRAYREF | OBJECT,
                                          optional => 1 },
                            quote_identifiers => { type => BOOLEAN,
                                                   optional => 1 },
                          };

sub join
{
    my $self = shift;
    my %p = validate( @_, JOIN_SPEC );

    $p{join} ||= delete $p{tables};
    $p{join} = [ $p{join} ] unless Alzabo::Utils::is_arrayref( $p{join} );

    my @tables;

    if ( Alzabo::Utils::is_arrayref( $p{join}->[0] ) )
    {
        # flattens the nested structure and produces a unique set of
        # tables
        @tables = values %{ { map { $_ => $_ }
                              grep { Alzabo::Utils::safe_isa( $_, 'Alzabo::Table' ) }
                             map { @$_ } @{ $p{join} } } };
    }
    else
    {
        @tables = grep { Alzabo::Utils::safe_isa($_, 'Alzabo::Table') } @{ $p{join} };
    }

    if ( $p{distinct} )
    {
        $p{distinct} =
            Alzabo::Utils::is_arrayref( $p{distinct} ) ? $p{distinct} : [ $p{distinct} ];
    }

    if ( $p{order_by} )
    {
        $p{order_by} =
            Alzabo::Utils::is_arrayref( $p{order_by} )
            ? $p{order_by}
            : $p{order_by}
            ? [ $p{order_by} ]
            : undef;
    }

    # We go in this order:  $p{select}, $p{distinct}, @tables
    my @select_tables = ( $p{select} ?
                          ( Alzabo::Utils::is_arrayref( $p{select} ) ?
                            @{ $p{select} } : $p{select} ) :
                          $p{distinct} ?
                          @{ $p{distinct} } :
                          @tables );

    my $sql = Alzabo::Runtime::sqlmaker( $self, \%p );

    my @select_cols;
    if ( $p{distinct} )
    {
        my %distinct = map { $_ => 1 } @{ $p{distinct} };

        # hack so distinct is not treated as a function, just a
        # bareword in the SQL
        @select_cols = ( 'DISTINCT',
                         map { ( $_->primary_key,
                                 $_->prefetch ?
                                 $_->columns( $_->prefetch ) :
                                 () ) }
                         @{ $p{distinct} }
                       );

        foreach my $t (@select_tables)
        {
            next if $distinct{$t};
            push @select_cols, $t->primary_key;

            push @select_cols, $t->columns( $t->prefetch ) if $t->prefetch;
        }

        if ( $p{order_by} && $sql->distinct_requires_order_by_in_select )
        {
            my %select_cols = map { $_ => 1 } @select_cols;
            push @select_cols, grep { ref } @{ $p{order_by} };
        }

        @select_tables = ( @{ $p{distinct} }, grep { ! $distinct{$_} } @select_tables );
    }
    else
    {
        @select_cols =
            ( map { ( $_->primary_key,
                      $_->prefetch ?
                      $_->columns( $_->prefetch ) :
                      () ) }
              @select_tables );
    }

    $sql->select(@select_cols);

    $self->_join_all_tables( sql => $sql,
                             join => $p{join} );

    Alzabo::Runtime::process_where_clause( $sql, $p{where} ) if exists $p{where};

    Alzabo::Runtime::process_order_by_clause( $sql, $p{order_by} )
        if $p{order_by};

    $sql->limit( ref $p{limit} ? @{ $p{limit} } : $p{limit} ) if $p{limit};

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    my $statement = $self->driver->statement( sql => $sql->sql,
                                              bind => $sql->bind );

    if (@select_tables == 1)
    {
        return Alzabo::Runtime::RowCursor->new
                   ( statement => $statement,
                     table => $select_tables[0]->real_table,
                   );
    }
    else
    {
        return Alzabo::Runtime::JoinCursor->new
                   ( statement => $statement,
                     tables => [ map { $_->real_table } @select_tables ],
                   );
    }
}

sub row_count
{
    my $self = shift;
    my %p = @_;

    return $self->function( select => Alzabo::Runtime::sqlmaker( $self, \%p )->COUNT('*'),
                            %p,
                          );
}

sub function
{
    my $self = shift;
    my %p = @_;

    my $sql = $self->_select_sql(%p);

    my $method =
        Alzabo::Utils::is_arrayref( $p{select} ) && @{ $p{select} } > 1 ? 'rows' : 'column';

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    return $self->driver->$method( sql => $sql->sql,
                                   bind => $sql->bind );
}

sub select
{
    my $self = shift;

    my $sql = $self->_select_sql(@_);

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    return $self->driver->statement( sql => $sql->sql,
                                     bind => $sql->bind );
}

use constant _SELECT_SQL_SPEC => { join => { type => ARRAYREF | OBJECT,
                                             optional => 1 },
                                   tables => { type => ARRAYREF | OBJECT,
                                               optional => 1 },
                                   select => { type => SCALAR | ARRAYREF | OBJECT,
                                               optional => 1 },
                                   where => { type => ARRAYREF,
                                              optional => 1 },
                                   group_by => { type => ARRAYREF | HASHREF | OBJECT,
                                                 optional => 1 },
                                   order_by => { type => ARRAYREF | HASHREF | OBJECT,
                                                 optional => 1 },
                                   having => { type => ARRAYREF,
                                               optional => 1 },
                                   limit => { type => SCALAR | ARRAYREF,
                                              optional => 1 },
                                   quote_identifiers => { type => BOOLEAN,
                                                          optional => 1 },
                                 };

sub _select_sql
{
    my $self = shift;
    my %p = validate( @_, _SELECT_SQL_SPEC );

    $p{join} ||= delete $p{tables};
    $p{join} = [ $p{join} ] unless Alzabo::Utils::is_arrayref( $p{join} );

    my @tables;

    if ( Alzabo::Utils::is_arrayref( $p{join}->[0] ) )
    {
        # flattens the nested structure and produces a unique set of
        # tables
        @tables = values %{ { map { $_ => $_ }
                              grep { Alzabo::Utils::safe_isa( 'Alzabo::Table', $_ ) }
                              map { @$_ } @{ $p{join} } } };
    }
    else
    {
        @tables = grep { Alzabo::Utils::safe_isa( 'Alzabo::Table', $_ ) } @{ $p{join} };
    }

    my @funcs = Alzabo::Utils::is_arrayref( $p{select} ) ? @{ $p{select} } : $p{select};

    my $sql = ( Alzabo::Runtime::sqlmaker( $self, \%p )->
                select(@funcs) );

    $self->_join_all_tables( sql => $sql,
                             join => $p{join} );

    Alzabo::Runtime::process_where_clause( $sql, $p{where} )
        if exists $p{where};

    Alzabo::Runtime::process_group_by_clause( $sql, $p{group_by} )
        if exists $p{group_by};

    Alzabo::Runtime::process_having_clause( $sql, $p{having} )
        if exists $p{having};

    Alzabo::Runtime::process_order_by_clause( $sql, $p{order_by} )
        if exists $p{order_by};

    $sql->limit( ref $p{limit} ? @{ $p{limit} } : $p{limit} ) if $p{limit};

    return $sql;
}

use constant _JOIN_ALL_TABLES_SPEC => { join => { type => ARRAYREF },
                                        sql  => { isa => 'Alzabo::SQLMaker' } };

sub _join_all_tables
{
    my $self = shift;
    my %p = validate( @_, _JOIN_ALL_TABLES_SPEC );

    my @from;
    my @joins;

    # outer join given as only join
    $p{join} = [ $p{join} ] unless ref $p{join}->[0];

    # A structure like:
    #
    # [ [ $t_1 => $t_2 ],
    #   [ $t_1 => $t_3, $fk ],
    #   [ left_outer_join => $t_3 => $t_4 ],
    #   [ left_outer_join => $t_3 => $t_5, undef, [ $where_clause ] ]
    #
    if ( Alzabo::Utils::is_arrayref( $p{join}->[0] ) )
    {
        my %map;
        my %tables;

        foreach my $set ( @{ $p{join} } )
        {
            # we take some care not to change the contents of $set,
            # because the caller may reuse the variable being
            # referenced, and changes here could break that.

            # XXX - improve
            params_exception
                'The table map must contain only two tables per array reference'
                    if @$set > 5;

            my @tables;
            if ( ! ref $set->[0] )
            {
                $set->[0] =~ /^(right|left|full)_outer_join$/i
                    or params_exception "Invalid join type: $set->[0]";

                @tables = @$set[1,2];

                push @from, [ $1, @tables, @$set[3, 4] ];
            }
            else
            {
                @tables = @$set[0,1];

                push @from, grep { ! exists $tables{ $_->alias_name } } @tables;
                push @joins, [ @tables, $set->[2] ];
            }

            # Track the tables we've seen
            @tables{ $tables[0]->alias_name, $tables[1]->alias_name } = (1, 1);

            # Track their relationships
            push @{ $map{ $tables[0]->alias_name } }, $tables[1]->alias_name;
            push @{ $map{ $tables[1]->alias_name } }, $tables[0]->alias_name;
        }

        # just get one key to start with
        my ($key) = (each %tables)[0];
        delete $tables{$key};
        my @t = @{ delete $map{$key} };
        while (my $t = shift @t)
        {
            delete $tables{$t};
            push @t, @{ delete $map{$t} } if $map{$t};
        }

        logic_exception
            "The specified table parameter does not connect all the tables involved in the join"
                if keys %tables;
    }
    # A structure like:
    #
    # [ $t_1 => $t_2 => $t_3 => $t_4 ]
    #
    else
    {
        for (my $x = 0; $x < @{ $p{join} } - 1; $x++)
        {
            push @joins, [ $p{join}->[$x], $p{join}->[$x + 1] ];
        }

        @from = @{ $p{join} };
    }

    $p{sql}->from(@from);

    return unless @joins;

    foreach my $join (@joins)
    {
        $self->_join_two_tables( $p{sql}, @$join );
    }

    $p{sql}->subgroup_end;
}

sub _join_two_tables
{
    my $self = shift;
    my ($sql, $table_1, $table_2, $fk) = @_;

    my $op = $sql->last_op eq 'and' || $sql->last_op eq 'condition' ? 'and' : 'where';

    if ($fk)
    {
        unless ( $fk->table_from eq $table_1 && $fk->table_to eq $table_2 )
        {
            if ( $fk->table_from eq $table_2 && $fk->table_to eq $table_1 )
            {
                $fk = $fk->reverse;
            }
            else
            {
                params_exception
                    ( "The foreign key given to join together " .
                      $table_1->alias_name .
                      " and " . $table_2->alias_name .
                      " does not represent a relationship between those two tables" );
            }
        }
    }
    else
    {
        my @fk = $table_1->foreign_keys_by_table($table_2);

        logic_exception
            ( "The " . $table_1->name .
              " table has no foreign keys to the " .
              $table_2->name . " table" )
                unless @fk;

        logic_exception
            ( "The " . $table_1->name .
              " table has more than 1 foreign key to the " .
              $table_2->name . " table" )
                if @fk > 1;

        $fk = $fk[0];
    }

    foreach my $cp ( $fk->column_pair_names )
    {
        if ( $op eq 'where' )
        {
            # first time through loop only
            $sql->where;
            $sql->subgroup_start;
            $sql->condition( $table_1->column( $cp->[0] ), '=', $table_2->column( $cp->[1] ) );
        }
        else
        {
            $sql->$op( $table_1->column( $cp->[0] ), '=', $table_2->column( $cp->[1] ) );
        }
        $op = 'and';
    }
}

sub prefetch_all
{
    my $self = shift;

    $_->set_prefetch( $_->columns ) for $self->tables;
}

sub prefetch_all_but_blobs
{
    my $self = shift;

    $_->set_prefetch( grep { ! $_->is_blob } $_->columns ) for $self->tables;
}

sub prefetch_none
{
    my $self = shift;

    $_->set_prefetch() for $self->tables;
}

__END__

=head1 NAME

Alzabo::Runtime::Schema - Schema objects

=head1 SYNOPSIS

  use Alzabo::Runtime::Schema qw(some_schema);

  my $schema = Alzabo::Runtime::Schema->load_from_file( name => 'foo' );
  $schema->set_user( $username );
  $schema->set_password( $password );

  $schema->connect;

=head1 DESCRIPTION

Objects in this class represent schemas, and can be used to retrieve
data from that schema.

This object can only be loaded from a file.  The file is created
whenever a corresponding
L<C<Alzabo::Create::Schema>|Alzabo::Create::Schema> object is saved.

=head1 INHERITS FROM

C<Alzabo::Schema>

=for pod_merge merged

=head1 METHODS

=head2 load_from_file ( name => $schema_name )

Loads a schema from a file.  This is the only constructor for this
class.  It returns an C<Alzabo::Runtime::Schema> object.  Loaded
objects are cached in memory, so future calls to this method may
return the same object.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::System>|Alzabo::Exceptions>

=head2 set_user ($user)

Sets the username to use when connecting to the database.

=head2 user

Return the username used by the schema when connecting to the database.

=head2 set_password ($password)

Set the password to use when connecting to the database.

=head2 password

Returns the password used by the schema when connecting to the
database.

=head2 set_host ($host)

Set the host to use when connecting to the database.

=head2 host

Returns the host used by the schema when connecting to the database.

=head2 set_port ($port)

Set the port to use when connecting to the database.

=head2 port

Returns the port used by the schema when connecting to the database.

=head2 set_referential_integrity ($boolean)

Turns referential integrity checking on or off.  If it is on, then
when L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> objects are
deleted, updated, or inserted, they will report this activity to any
relevant L<C<Alzabo::Runtime::ForeignKey>|Alzabo::Runtime::ForeignKey>
objects for the row, so that the foreign key objects can take
appropriate action.

This defaults to false.  If your RDBMS supports foreign key
constraints, these should be used instead of Alzabo's built-in
referential integrity checking, as they will be much faster.

=head2 referential_integrity

Returns a boolean value indicating whether this schema will attempt to
maintain referential integrity.

=head2 set_quote_identifiers ($boolean)

If this is true, then all SQL constructed for this schema will have
quoted identifiers (like `Table`.`column` in MySQL).

This defaults to false.  Turning this on adds some overhead to all SQL
generation.

=head2 connect (%params)

Calls the L<C<Alzabo::Driver-E<gt>connect>|Alzabo::Driver/connect>
method for the driver owned by the schema.  The username, password,
host, and port set for the schema will be passed to the driver, as
will any additional parameters given to this method.  See the L<C<<
Alzabo::Driver->connect() method >>|Alzabo::Driver/connect> for more
details.

=head2 disconnect

Calls the L<C<< Alzabo::Driver->disconnect()
>>|Alzabo::Driver/disconnect> method for the driver owned by the
schema.

=head2 join

Joins are done by taking the tables provided in order, and finding a
relation between them.  If any given table pair has more than one
relation, then this method will fail.  The relations, along with the
values given in the optional where clause will then be used to
generate the necessary SQL.  See
L<C<Alzabo::Runtime::JoinCursor>|Alzabo::Runtime::JoinCursor> for more
information.

This method takes the following parameters:

=over 4

=item * join => <see below>

This parameter can either be a simple array reference of tables or an
array reference of array references.  In the latter case, each array
reference should contain two tables.  These array references can also
include an optional modifier specifying a type of join for the two
tables, like 'left_outer_join', an optional foreign key object which
will be used to join the two tables, and an optional where clause used
to restrict the join.

If a simple array reference is given, then the order of these tables
is significant when there are more than 2 tables.  Alzabo expects to
find relationships between tables 1 & 2, 2 & 3, 3 & 4, etc.

For example, given:

  join => [ $table_A, $table_B, $table_C ]

Alzabo would expect that table A has a relationship to table B, which
in turn has a relationship to table C.  If you simply provide a simple
array reference, you cannot include any outer joins, and every element
of the array reference must be a table object.

If you need to specify a more complicated set of relationships, this
can be done with a slightly more complicated data structure, which
looks like this:

  join => [ [ $table_A, $table_B ],
            [ $table_A, $table_C ],
            [ $table_C, $table_D ],
            [ $table_C, $table_E ] ]

This is fairly self explanatory.  Alzabo will expect to find a
relationship between each pair of tables.  This allows for the
construction of arbitrarily complex join clauses.

For even more complex needs, there are more options:

  join => [ [ left_outer_join => $table_A, $table_B ],
            [ $table_A, $table_C, $foreign_key ],
            [ right_outer_join => $table_C, $table_D, $foreign_key ] ]

In this example, we are specifying two types of outer joins, and in
two of the three cases, specifying which foreign key should be used to
join the two tables.

It should be noted that if you want to join two tables that have more
than one foreign key between them, you B<must> provide a foreign key
object when using them as part of your query.

The way an outer join is interpreted is that this:

  [ left_outer_join => $table_A, $table_B ]

is interepreted to mean

  SELECT ... FROM table_A LEFT OUTER JOIN table_B ON ...

Table order is relevant for right and left outer joins, obviously.

However, for regular (inner) joins, table order is not important.

It is also possible to apply restrictions to an outer join, for
example:

  join => [ [ left_outer_join => $table_A, $table_B,
              # outer join restriction
              [ [ $table_B->column('size') > 2 ],
                'and',
                [ $table_B->column('name'), '!=', 'Foo' ] ],
            ] ]

This corresponds to this SQL;

  SELECT ... FROM table_A
  LEFT OUTER JOIN table_B ON ...
              AND (table_B.size > 2 AND table_B.name != 'Foo')

These restrictions are only allowed when performing an outer join,
since there is no point in using them for regular inner joins.  An
inner join restriction has the same effect when included in the
"WHERE" clause.

If the more multiple array reference of specifying tables is used and
no "select" parameter is provided, then the order of the rows returned
from calling L<C<< Alzabo::Runtime::JoinCursor->next()
>>|Alzabo::Runtime::JoinCursor/next> is not guaranteed.  In other
words, the array that the cursor returns will contain a row from each
table involved in the join, but the which row belongs to which table
cannot be determined except by examining the objects.  The order will
be the same every time L<C<< Alzabo::Runtime::JoinCursor->next()
>>|Alzabo::Runtime::JoinCursor/next> is called, however.  It may be
easier to use the L<C<< Alzabo::Runtime::JoinCursor->next_as_hash()
>>|Alzabo::Runtime::JoinCursor/next_as_hash> method in this case.

=item * select => C<Alzabo::Runtime::Table> object or objects (optional)

This parameter specifies from which tables you would like rows
returned.  If this parameter is not given, then the "distinct" or
"join" parameter will be used instead, with the "distinct" parameter
taking precedence.

This can be either a single table or an array reference of table
objects.

=item * distinct => C<Alzabo::Runtime::Table> object or objects (optional)

If this parameter is given, it indicates that results from the join
should never contain repeated rows.

This can be used in place of the "select" parameter to indicate from
which tables you want rows returned.  The "select" parameter, if
given, supercedes this parameter.

For some databases (notably Postgres), if you want to do a "SELECT
DISTINCT" query then all of the columns mentioned in your "ORDER BY"
clause must also be in your SELECT clause. Alzabo will make sure this
is the case, but it may cause more rows to be returned than you
expected, though this depends on the query.

B<NOTE:> The adding of columns to the SELECT clause from the ORDER BY
clause is considered experimental, because it can change the expected
results in some cases.

=item * where (optional)

See the L<documentation on where clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=item * order_by (optional)

See the L<documentation on order by clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=item * limit (optional)

See the L<documentation on limit clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=back

If the "select" parameter specified that more than one table is
desired, then this method will return n
L<JoinCursor|Alzabo::Runtime::JoinCursor> object
representing the results of the join.  Otherwise, the method returns
a L<RowCursor|Alzabo::Runtime::RowCursor> object.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 one_row

This method takes the exact same parameters as the
L<C<join()>|Alzabo::Runtime::table/join> method but instead of
returning a cursor, it returns a single array of row objects.  These
will be the rows representing the first row (a set of one or more
table's primary keys) that is returned by the database.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 function and select

These two methods differ only in their return values.

They both take the following parameters:

=over 4

=item * select => $function or [ scalars, SQL functions and/or C<Alzabo::Column> objects ]

If you pass an array reference for this parameter, it may contain
scalars, SQL functions, or column objects.  For example:

  $schema->function( select =>
                     [ 1,
                       $foo->column('name'),
                       LENGTH( $foo->column('name') ) ],
                     join => [ $foo, $bar_table ],
                   );

This is equivalent to the following SQL:

  SELECT 1, foo.name, LENGTH( foo.name )
    FROM foo, bar
   WHERE ...

=item * join

See the L<documentation on the join parameter for the join
method|Alzabo::Runtime::Schema/join E<lt>see belowE<gt>>.

=item * where

See the L<documentation on where clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=item * order_by

See the L<documentation on order by clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=item * group_by

See the L<documentation on group by clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=item * having

This parameter is specified in the same way as the "where" parameter,
but is used to generate a "HAVING" clause.  It only allowed when you
also specify a "group_by" parameter.

=item * limit

See the L<documentation on limit clauses for the
Alzabo::Runtime::Table class|Alzabo::Runtime::Table/Common
Parameters>.

=back

These methods are used to call arbitrary SQL functions such as 'AVG'
or 'MAX', and to select data from individual columns.  The function
(or functions) should be the return values from the functions exported
by the SQLMaker subclass that you are using.  Please see L<Using SQL
functions|Alzabo::Intro/"Using SQL functions"> for more details.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head3 function() return values

The return value of this method is highly context sensitive.

If you only requested a single element in your "select" parameter,
such as "DISTINCT(foo)", then it returns the first value in scalar
context and all the values as an array in list context.

If you requested multiple functions such as "AVG(foo), MAX(foo)", then
it returns a single array reference, the first row of values, in
scalar context and a list of array references in list context.

=head3 select() return values

This method always returns a new
L<C<Alzabo::DriverStatement>|Alzabo::Driver/Alzabo::DriverStatement>
object containing the results of the query.  This object has an
interface very similar to the Alzabo cursor interface, and has methods
such as C<next()>, C<next_as_hash()>, etc.

=head2 row_count

This method is simply a shortcut to get the result of COUNT('*') for a
join.  It equivalent to calling C<function()> with a "select"
parameter of C<COUNT('*')>.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 prefetch_all

This method will set all the tables in the schema to prefetch all
their columns.  See the L<lazy column
loading|Alzabo::Runtime::Table/LAZY COLUMN LOADING> section in
L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table> for more details.

=head2 prefetch_all_but_blobs

This method will set all the tables in the schema to prefetch all
their non-blob-type columns.

This method is called as soon as a schema is loaded.

=head2 prefetch_none

This method turns of all prefetching.

=for pod_merge name

=for pod_merge tables

=for pod_merge table

=for pod_merge has_table

=for pod_merge begin_work

=for pod_merge rollback

=for pod_merge commit

=for pod_merge run_in_transaction ( sub { code... } )

=for pod_merge driver

=for pod_merge rules

=for pod_merge sqlmaker

=head1 JOINING A TABLE MORE THAN ONCE

It is possible to join to the same table more than once in a query.
Table objects contain an L<C<alias()>|Alzabo::Runtime::Table/alias>
method that, when called, returns an object that can be used in the
same query as the original table object, but which will be treated as
a separate table.  This faciliaties queries similar to the following
SQL::

  SELECT ... FROM Foo AS F1, Foo as F2, Bar AS B ...

The object returned from the table functions more or less exactly like
a table object.  When using this table to set where clause or order by
(or any other) conditions, it is important that the column objects for
these conditions be retrieved from the alias object.

For example:

 my $foo_alias = $foo->alias;

 my $cursor = $schema->join( select => $foo,
                             join   => [ $foo, $bar, $foo_alias ],
                             where  => [ [ $bar->column('baz'), '=', 10 ],
                                         [ $foo_alias->column('quux'), '=', 100 ] ],
                             order_by => $foo_alias->column('briz') );

If we were to use the C<$foo> object to retrieve the 'quux' and
'briz' columns then the join would simply not work as expected.

It is also possible to use multiple aliases of the same table in a
join, so that this will work properly:

 my $foo_alias1 = $foo->alias;
 my $foo_alias2 = $foo->alias;

=head1 USER AND PASSWORD INFORMATION

This information is never saved to disk.  This means that if you're
operating in an environment where the schema object is reloaded from
disk every time it is used, such as a CGI program spanning multiple
requests, then you will have to make a new connection every time.  In
a persistent environment, this is not a problem.  For example, in a
mod_perl environment, you could load the schema and call the
L<C<set_user()>|Alzabo::Runtime::Schema/set_user ($user)> and
L<C<set_password()>|Alzabo::Runtime::Schema/set_password ($password)>
methods in the server startup file.  Then all the mod_perl children
will inherit the schema with the user and password already set.
Otherwise you will have to provide it for each request.

You may ask why you have to go to all this trouble to deal with the
user and password information.  The basic reason was that I did not
feel I could come up with a solution to this problem that was secure,
easy to configure and use, and cross-platform compatible.  Rather, I
think it is best to let each user decide on a security practice with
which they feel comfortable.

In addition, there are a number of modules aimed at helping store and
use this sort of information on CPAN, including C<DBIx::Connect> and
C<AppConfig>, among others.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
