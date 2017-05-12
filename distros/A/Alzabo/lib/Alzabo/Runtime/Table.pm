package Alzabo::Runtime::Table;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions ( abbr => [ qw( logic_exception not_nullable_exception
                                       params_exception ) ] );
use Alzabo::Runtime;
use Alzabo::Utils;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { params_exception join '', @_ } );

use Scalar::Util ();
use Tie::IxHash;

use base qw(Alzabo::Table);

$VERSION = 2.0;

sub insert
{
    my $self = shift;

    logic_exception "Can't make rows for tables without a primary key"
        unless $self->primary_key;

    my %p = @_;
    %p = validate( @_,
                   { ( map { $_ => { optional => 1 } } keys %p ),
                     values => { type => HASHREF, optional => 1 },
                     quote_identifiers => { type => BOOLEAN,
                                            optional => 1 },
                   },
                 );

    my $vals = delete $p{values} || {};

    my $schema = $self->schema;

    my @pk = $self->primary_key;
    foreach my $pk (@pk)
    {
        unless ( exists $vals->{ $pk->name } )
        {
            if ($pk->sequenced)
            {
                $vals->{ $pk->name } = $schema->driver->next_sequence_number($pk);
            }
            else
            {
                params_exception
                    ( "No value provided for primary key (" .
                      $pk->name . ") and no sequence is available." );
            }
        }
    }

    foreach my $c ($self->columns)
    {
        next if $c->is_primary_key;

        unless ( defined $vals->{ $c->name } || $c->nullable || defined $c->default )
        {
            not_nullable_exception
                ( error => $c->name . " column in " . $self->name . " table cannot be null.",
                  column_name => $c->name,
                  table_name  => $c->table->name,
                  schema_name => $c->table->schema->name,
                );
        }

        delete $vals->{ $c->name }
            if ! defined $vals->{ $c->name } && defined $c->default;
    }

    my @fk;
    @fk = $self->all_foreign_keys
        if $schema->referential_integrity;

    my $sql = ( Alzabo::Runtime::sqlmaker( $self->schema, \%p )->
                insert->
                into($self, $self->columns( sort keys %$vals ) )->
                values( map { $self->column($_) => $vals->{$_} } sort keys %$vals ) );

    my %id;

    $schema->begin_work if @fk;
    eval
    {
        foreach my $fk (@fk)
        {
            $fk->register_insert( map { $_->name => $vals->{ $_->name } } $fk->columns_from );
        }

        $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
        print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

        $self->schema->driver->do( sql => $sql->sql,
                                   bind => $sql->bind );

        foreach my $pk (@pk)
        {
            $id{ $pk->name } = ( defined $vals->{ $pk->name } ?
                                 $vals->{ $pk->name } :
                                 $schema->driver->get_last_id($self) );
        }

        # must come after call to ->get_last_id for MySQL because the
        # id will no longer be available after the transaction ends.
        $schema->commit if @fk;
    };
    if (my $e = $@)
    {
        eval { $schema->rollback };

        rethrow_exception $e;
    }

    return unless defined wantarray || $p{potential_row};

    return $self->row_by_pk( pk => \%id, %p );
}

sub insert_handle
{
    my $self = shift;

    logic_exception "Can't make rows for tables without a primary key"
        unless $self->primary_key;

    my %p = @_;
    %p = validate( @_,
                   { ( map { $_ => { optional => 1 } } keys %p ),
                     columns => { type => ARRAYREF, default => [] },
                     values  => { type => HASHREF, default => {} },
                     quote_identifiers => { type => BOOLEAN,
                                            optional => 1 },
                   },
                 );

    my %func_vals;
    my %static_vals;

    if ( $p{values} )
    {
        my $v = delete $p{values};
        while ( my ( $name, $val ) = each %$v )
        {
            if ( Alzabo::Utils::safe_isa( $val, 'Alzabo::SQLMaker::Function' ) )
            {
                $func_vals{$name} = $val;
            }
            else
            {
                $static_vals{$name} = $val
            }
        }
    }

    my $placeholder = $self->schema->sqlmaker->placeholder;

    my %cols;
    my %vals;
    # Get the unique set of columns and associated values
    foreach my $col ( @{ $p{columns} }, $self->primary_key )
    {
        $vals{ $col->name } = $placeholder;
        $cols{ $col->name } = 1;
    }

    foreach my $name ( keys %static_vals )
    {
        $vals{$name} = $placeholder;
        $cols{$name} = 1;
    }

    %vals = ( %vals, %func_vals );

    # At this point, %vals has each column's name and associated
    # value.  The value may be a placeholder or SQL function.

    $cols{$_} = 1 foreach keys %func_vals;

    foreach my $c ( $self->columns )
    {
        next if $c->is_primary_key  || $c->nullable || defined $c->default;

        unless ( $cols{ $c->name } )
        {
            not_nullable_exception
                ( error => $c->name . " column in " . $self->name . " table cannot be null.",
                  column_name => $c->name,
                  table_name  => $c->table->name,
                  schema_name => $c->table->schema->name,
                );
        }
    }

    my @columns = $self->columns( keys %vals );

    my $sql = ( Alzabo::Runtime::sqlmaker( $self->schema, \%p )->
                insert->
                into( $self, @columns )->
                values( map { $_ => $vals{ $_->name } } @columns ),
              );

    return Alzabo::Runtime::InsertHandle->new( table => $self,
                                               sql   => $sql,
                                               values  => \%static_vals,
                                               columns => \@columns,
                                               %p,
                                             );
}

sub row_by_pk
{
    my $self = shift;

    logic_exception "Can't make rows for tables without a primary key"
        unless $self->primary_key;

    my %p = @_;

    my $pk_val = $p{pk};

    my @pk = $self->primary_key;

    params_exception
        'Incorrect number of pk values provided.  ' . scalar @pk . ' are needed.'
            if ref $pk_val && @pk != scalar keys %$pk_val;

    if (@pk > 1)
    {
        params_exception
            ( 'Primary key for ' . $self->name . ' is more than one column.' .
              '  Please provide multiple key values as a hashref.' )
                unless ref $pk_val;

        foreach my $pk (@pk)
        {
            params_exception 'No value provided for primary key ' . $pk->name . '.'
                unless defined $pk_val->{ $pk->name };
        }
    }

    return $self->_make_row( %p,
                             table => $self,
                           );
}

sub _make_row
{
    my $self = shift;
    my %p = @_;

    my $class = $p{row_class} ? delete $p{row_class} : $self->_row_class;

    return $class->new(%p);
}

sub _row_class { 'Alzabo::Runtime::Row' }

sub row_by_id
{
    my $self = shift;
    my %p = @_;
    validate( @_, { row_id => { type => SCALAR },
                    ( map { $_ => { optional => 1 } } keys %p ) } );

    my (undef, undef, %pk) = split ';:;_;:;', delete $p{row_id};

    return $self->row_by_pk( %p, pk => \%pk );
}

sub rows_where
{
    my $self = shift;
    my %p = @_;

    my $sql = $self->_make_sql(%p);

    Alzabo::Runtime::process_where_clause( $sql, $p{where} ) if exists $p{where};

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    return $self->_cursor_by_sql( %p, sql => $sql );
}

sub one_row
{
    my $self = shift;
    my %p = @_;

    my $sql = $self->_make_sql(%p);

    Alzabo::Runtime::process_where_clause( $sql, $p{where} ) if exists $p{where};

    Alzabo::Runtime::process_order_by_clause( $sql, $p{order_by} ) if exists $p{order_by};

    if ( exists $p{limit} )
    {
        $sql->limit( ref $p{limit} ? @{ $p{limit} } : $p{limit} );
    }

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    my @return = $self->schema->driver->one_row( sql => $sql->sql,
                                                 bind => $sql->bind )
        or return;

    my @pk = $self->primary_key;

    my (%pk, %prefetch);

    @pk{ map { $_->name } @pk } = splice @return, 0, scalar @pk;

    # Must be some prefetch pieces
    if (@return)
    {
        @prefetch{ $self->prefetch } = @return;
    }

    return $self->row_by_pk( pk => \%pk,
                             prefetch => \%prefetch,
                           );
}

sub all_rows
{
    my $self = shift;

    my $sql = $self->_make_sql;

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    return $self->_cursor_by_sql( @_, sql => $sql );
}

sub _make_sql
{
    my $self = shift;
    my %p = @_;

    logic_exception "Can't make rows for tables without a primary key"
        unless $self->primary_key;

    my $sql = ( Alzabo::Runtime::sqlmaker( $self->schema, \%p )->
                select( $self->primary_key,
                        $self->prefetch ? $self->columns( $self->prefetch ) : () )->
                from( $self ) );

    return $sql;
}

sub _cursor_by_sql
{
    my $self = shift;

    my %p = @_;
    validate( @_, { sql => { isa => 'Alzabo::SQLMaker' },
                    order_by => { type => ARRAYREF | HASHREF | OBJECT,
                                  optional => 1 },
                    limit => { type => SCALAR | ARRAYREF,
                               optional => 1 },
                    ( map { $_ => { optional => 1 } } keys %p ) } );

    Alzabo::Runtime::process_order_by_clause( $p{sql}, $p{order_by} ) if exists $p{order_by};

    if ( exists $p{limit} )
    {
        $p{sql}->limit( ref $p{limit} ? @{ $p{limit} } : $p{limit} );
    }

    my $statement = $self->schema->driver->statement( sql => $p{sql}->sql,
                                                      bind => $p{sql}->bind,
                                                      limit => $p{sql}->get_limit );

    return Alzabo::Runtime::RowCursor->new( statement => $statement,
                                            table => $self,
                                          );
}

sub potential_row
{
    my $self = shift;
    my %p = @_;

    logic_exception "Can't make rows for tables without a primary key"
        unless $self->primary_key;

    my $class = $p{row_class} ? delete $p{row_class} : $self->_row_class;

    return $class->new( %p,
                        state => 'Alzabo::Runtime::RowState::Potential',
                        table => $self,
                      );
}

sub row_count
{
    my $self = shift;
    my %p = @_;

    my $count = Alzabo::Runtime::sqlmaker( $self->schema, \%p )->COUNT('*');

    return $self->function( select => $count, %p );
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

    return $self->schema->driver->$method( sql => $sql->sql,
                                           bind => $sql->bind );
}

sub select
{
    my $self = shift;

    my $sql = $self->_select_sql(@_);

    $sql->debug(\*STDERR) if Alzabo::Debug::SQL;
    print STDERR Devel::StackTrace->new if Alzabo::Debug::TRACE;

    return $self->schema->driver->statement( sql => $sql->sql,
                                             bind => $sql->bind );
}

use constant
    _SELECT_SQL_SPEC => { select => { type => SCALAR | ARRAYREF | OBJECT },
                          where  => { type => ARRAYREF | OBJECT,
                                      optional => 1 },
                          order_by => { type => ARRAYREF | HASHREF | OBJECT,
                                        optional => 1 },
                          group_by => { type => ARRAYREF | HASHREF | OBJECT,
                                        optional => 1 },
                          having   => { type => ARRAYREF,
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

    my @funcs = Alzabo::Utils::is_arrayref( $p{select} ) ? @{ $p{select} } : $p{select};

    my $sql = Alzabo::Runtime::sqlmaker( $self->schema, \%p )->select(@funcs)->from($self);

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

sub set_prefetch
{
    my $self = shift;

    $self->{prefetch} = $self->_canonize_prefetch(@_);
}

sub _canonize_prefetch
{
    my $self = shift;

    validate_pos( @_, ( { isa => 'Alzabo::Column' } ) x @_ );

    foreach my $c (@_)
    {
        params_exception "Column " . $c->name . " doesn't exist in $self->{name}"
            unless $self->has_column( $c->name );
    }

    return [ map { $_->name } grep { ! $_->is_primary_key } @_ ];
}

sub prefetch
{
    my $self = shift;

    return ref $self->{prefetch} ? @{ $self->{prefetch} } : ();
}

sub add_group
{
    my $self = shift;

    validate_pos( @_, ( { isa => 'Alzabo::Column' } ) x @_ );

    my @names = map { $_->name } @_;
    foreach my $col (@_)
    {
        params_exception "Column " . $col->name . " doesn't exist in $self->{name}"
            unless $self->has_column( $col->name );

        next if $col->is_primary_key;
        $self->{groups}{ $col->name } = \@names;
    }
}

sub group_by_column
{
    my $self = shift;
    my $col = shift;

    return exists $self->{groups}{$col} ? @{ $self->{groups}{$col} } : $col;
}

my $alias_num = '000000000';
sub alias
{
    my $self = shift;

    my $clone;
    %$clone = %$self;

    bless $clone, ref $self;

    $clone->{alias_name} = $self->name . ++$alias_num;
    $clone->{real_table} = $self;

    $clone->{columns} = Tie::IxHash->new( map { $_->name => $_ } $self->columns );

    # Force clone of primary key columns right away.
    $clone->column($_) foreach map { $_->name } $self->primary_key;

    return $clone;
}

#
# Since its unlikely that a user will end up needing clones of more
# than 1-2 columns each time an alias is used, we only make copies as
# needed.
#
sub column
{
    my $self = shift;

    # I'm an alias, make an alias column
    if ( $self->{alias_name} )
    {
        my $name = shift;
        my $col = $self->SUPER::column($name);

        # not previously cloned
        unless ( $col->table eq $self )
        {
            # replace our copy of this column with a clone
            $col = $col->alias_clone( table => $self );
            my $index = $self->{columns}->Indices($name);
            $self->{columns}->Replace( $index, $col, $name );

            Scalar::Util::weaken( $col->{table} );

            delete $self->{pk_array} if $col->is_primary_key;
        }

        return $col;
    }
    else
    {
        return $self->SUPER::column(@_);
    }
}

sub alias_name
{
    # intentionally don't call $_[0]->name for a noticeable
    # performance boost
    return $_[0]->{alias_name} || $_[0]->{name};
}

sub real_table
{
    return $_[0]->{real_table} || $_[0];
}

# This gets called a _lot_ so doing this sort of 'memoization' helps
sub primary_key
{
    my $self = shift;

    $self->{pk_array} ||= [ $self->SUPER::primary_key ];

    return ( wantarray ?
             @{ $self->{pk_array} } :
             $self->{pk_array}->[0]
           );
}

1;

__END__

=head1 NAME

Alzabo::Runtime::Table - Table objects

=head1 SYNOPSIS

  my $table = $schema->table('foo');

  my $row = $table->row_by_pk( pk => 1 );

  my $row_cursor =
      $table->rows_where
          ( where =>
            [ Alzabo::Column object, '=', 5 ] );

=head1 DESCRIPTION

This object is able to create rows, either by making objects based on
existing data or inserting new data to make new rows.

This object also implements a method of lazy column evaluation that
can be used to save memory and database wear and tear.  Please see the
L<LAZY COLUMN LOADING> section for details.

=head1 INHERITS FROM

C<Alzabo::Table>

=for pod_merge merged

=head1 METHODS

=head2 Methods that return an C<Alzabo::Runtime::Row> object

All of these methods accept the "no_cache" parameter, which will be
passed on to C<< Alzabo::Runtime::Row->new >>.

=head2 insert

Inserts the given values into the table.  If no value is given for a
primary key column and the column is
L<"sequenced"|Alzabo::Column/sequenced> then the primary key will be
auto-generated.

It takes the following parameters:

=over 4

=item * values => $hashref

The hashref contains column names and values for the new row.  This
parameter is optional.  If no values are specified, then the default
values will be used.

=back

This methods return a new
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> object.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::NotNullable>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 row_by_pk

The primary key can be either a simple scalar, as when the table has a
single primary key, or a hash reference of column names to primary key
values, for multi-column primary keys.

It takes the following parameters:

=over 4

=item * pk => $pk_val or \%pk_val

=back

It returns a new L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>
object.  If no rows in the database match the value(s) given then an
empty list or undef will be returned (for list or scalar context).

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 row_by_id

This method is useful for regenerating a row that has been saved by
reference to its id (returned by the
L<C<Alzabo::Runtime::Row-E<gt>id>|Alzabo::Runtime::Row/id> method).
This may be more convenient than saving a multi-column primary key
when trying to maintain state in a web app, for example.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

This method takes a single parameter, "row_id", which is the string
representation of a row's id, as returned by the L<C<<
Alzabo::Runtime::Row->id_as_string()
>>|Alzabo::Runtime::Row/id_as_string> method.

It returns a new L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>
object.  If no rows in the database match the value(s) given then an
empty list or undef will be returned (for list or scalar context).


=head2 Insert Handles

If you are going to be inserting many rows at once, it is more
efficient to create an insert handle and re-use that.  This is similar
to how DBI allows you to create statement handles and execute them
multiple times.

=head2 insert_handle

This method takes the following parameters:

=over 4

=item * columns => $arrayref

This should be an array reference containing zero or more
C<Alzabo::Runtime::Column> objects.

If it is empty, or not provided, then defaults will be used for all
columns.

=item * values => $hashref

This is used to specify values that will be the same for each row.
These can be actual values or SQL functions.

=back

The return value of this method is an C<Alzabo::Runtime::InsertHandle>
object.  This object has a single method, C<insert()>.  See the
L<C<Alzabo::Runtime::InsertHandle>|Alzabo::Runtime::InsertHandle> docs
for details.

Throws: L<C<Alzabo::Exception::NotNullable>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 Common Parameters

A number of methods in this clas take the same parameters.  These are
documented below.

=over 4

=item * where => <see below>

This parameter can take a variety of values.  The most basic "where" parameter is a single array reference of this form:

  [ Alzabo::Column object or SQL function,
    $comparison,
    $value or Alzabo::Column object ]

The C<$comparison> should be a string containing a SQL operator such
as C<< > >>, C<=>, or C<IN>.

The parameter can also be an array reference containing many such
arrays:

 [
   [ Alzabo::Column object or SQL function,
     $comparison,
     $value or Alzabo::Column object ],
   [ Alzabo::Column object or SQL function,
     $comparison,
     $value or Alzabo::Column object ],
   ...
 ]

If the comparison is "BETWEEN", then it should be followed by two
values.  If it is "IN" or "NOT IN", then it should be followed by a
list of one or more values.

By default, each clause represented by an array reference is joined
together with an 'AND'.  However, you can put the string 'or' between
two array references to cause them to be joined with an 'OR', such as:

 [ [ $foo_col, '=', 5 ],
   'or',
   [ $foo_col, '>', 10 ] ]

which would generate SQL something like:

 WHERE foo = 5 OR foo > 10

If you want to be explicit, you can also use the string 'and'.

If you need to group conditionals you can use '(' and ')' strings in
between array references representing a conditional.  For example:

 [ [ $foo_col, '=', 5 ],
   '(',
     [ $foo_col, '>', 10 ]
     'or',
     [ $bar_col, '<', 50, ')' ],
   ')' ]

which would generate SQL something like:

 WHERE foo = 5 AND ( foo > 10 OR bar < 50 )

Make sure that your parentheses balance out or an exception will be
thrown.

You can also use the SQL functions (L<Using SQL
functions|Alzabo::Intro/Using SQL functions>) exported from the
SQLMaker subclass you are using.  For example:

 [ LENGTH($foo_col), '<', 10 ]

would generate something like:

 WHERE LENGTH(foo) < 10

=item * order_by => see below

This parameter can take one of two different values.  The simplest
form is to just give it a single column object or SQL function.
Alternatively, you can give it an array reference to a list of column
objects, SQL functions and strings like this:

  order_by => [ $col1, COUNT('*'), $col2, 'DESC', $col3, 'ASC' ]

It is important to note that you cannot simply use any arbitrary SQL
function as part of your order by clause.  You need to use a function
that is exactly the same as one that was given as part of the "select"
parameter.

=item * group_by => see below

This parameter can take either a single column object or an array of
column objects.

=item * having => same as "where"

This parameter is specified in the same way as the "where" parameter.

=item * limit => $limit or [ $limit, $offset ]

For databases that support LIMIT clauses, this incorporates such a
clause into the SQL.

For databases that don't, the limit will be implemented
programatically as rows are being requested.  If an offset is given,
this will be the number of rows skipped in the result set before the
first one is returned.

=back

=head2 Methods that return an C<Alzabo::Runtime::RowCursor> object

The C<rows_where()> and C<all_rows()> methods both return an
L<C<Alzabo::Runtime::RowCursor>|Alzabo::Runtime::RowCursor> object
representing the results of the query.  This is the case even for
queries that end up returning one or zero rows, because Alzabo cannot
know in advance how many rows these queries will return.

=head2 rows_where

This method provides a simple way to retrieve a row cursor based on
one or more colum values.

It takes the following parameters, all of which were described in the
L<Common Parameters|Alzabo::Runtime::Table/Common Parameters> section.

=over 4

=item * where

=item * order_by

=item * limit

=back

It returns n
L<C<Alzabo::Runtime::RowCursor>|Alzabo::Runtime::RowCursor> object
representing the query.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 all_rows

This method simply returns all the rows in the table.

It takes the following parameters:

=over 4

=item * order_by

=item * limit

=back

It returns an
L<C<Alzabo::Runtime::RowCursor>|Alzabo::Runtime::RowCursor> object
representing the query.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 one_row

This method takes the exact same parameters as the
L<C<rows_where()>|Alzabo::Runtime::table/rows_where> method but
instead of returning a cursor, it returns a single row.  This row
represents the first row returned by the database.

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 potential_row

This method is used to create a new
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> object, in the
"potential" state.

It takes the following parameters.

=over 4

=item * values => \%values

This should be a hash reference containing column names, just as is
given to L<insert()|/insert>.

It is ok to omit columns that are normally not nullable, but they
cannot be B<explicitly> set to null.

Any values given will be set in the new potential row object.  If a
column has a default, and a value for that column is not given, then
the default will be used.

Unlike the L<insert()\/insert> method, you cannot use SQL functions as
values here.

=back

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 Other Methods

This method returns a count of the rows in the table.  It takes the
following parameters:

=head2 row_count

=over 4

=item * where

=back

Throws: L<C<Alzabo::Exception::Logic>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 function and select

These two methods differ only in their return values.

They both take the following parameters:

=over 4

=item * select => $function or [ scalars, SQL functions and/or C<Alzabo::Column> objects ]

If you pass an array reference for this parameter, it may contain
scalars, SQL functions, or column objects.  For example:

  $table->function( select =>
                    [ 1,
                      $foo->column('name'),
                      LENGTH( $foo->column('name') ) ] );

This is equivalent to the following SQL:

  SELECT 1, foo.name, LENGTH( foo.name )
    FROM foo

=item * where

=item * order_by

=item * group_by

=item * limit

=back

This method is used to call arbitrary SQL functions such as 'AVG' or
'MAX', or to select arbitrary column data.  The function (or
functions) should be the return values from the functions exported by
the SQLMaker subclass that you are using.  Please see L<Using SQL
functions|Alzabo/Using SQL functions> for more details.

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

=head2 alias

This returns an object which can be used in joins to allow a
particular table to be involved in the join under multiple aliases.
This allows for self-joins as well as more complex joins involving
multiple aliases to a given table.

The object returned by this method is more or less identical to a
table object in terms of the methods it supports.  This includes
methods that were generated by C<Alzabo::MethodMaker>.

However, B<this object should not be used outside the context of a
join query> because the results will be unpredictable.  In addition,
B<the column objects that the aliased table object returns should also
not be used outside of the context of a join>.

=for pod_merge schema

=for pod_merge name

=for pod_merge column

=for pod_merge columns

=for pod_merge has_column

=for pod_merge primary_key

=for pod_merge primary_key_size

=for pod_merge column_is_primary_key

=for pod_merge foreign_keys

=for pod_merge foreign_keys_by_table

=for pod_merge foreign_keys_by_column

=for pod_merge all_foreign_keys

=for pod_merge index

=for pod_merge has_index

=for pod_merge indexes

=for pod_merge attributes

=for pod_merge has_attribute

=for pod_merge comment

=head1 LAZY COLUMN LOADING

This concept was taken directly from Michael Schwern's Class::DBI
module (credit where it is due).

By default, L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> objects
load all data from the database except blob type columns (columns with
an unbounded length).  This data is stored internally in the object
after being fetched.

If you want to change what data is prefetched, there are two methods
you can use.

The first method,
L<C<set_prefetch()>|Alzabo::Runtime::Table/set_prefetch (Alzabo::Column
objects)>, allows you to specify a list of columns to be fetched
immediately after object creation.  These should be columns that you
expect to use extremely frequently.

The second method, L<C<add_group()>|Alzabo::Runtime::Table/add_group
(Alzabo::Column objects)>, allows you to group columns together.  If
you attempt to fetch one of these columns, then all the columns in the
group will be fetched.  This is useful in cases where you don't often
want certain data, but when you do you need several related pieces.

=head2 Lazy column loading related methods

=head3 set_prefetch (C<Alzabo::Column> objects)

Given a list of column objects, this makes sure that all
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> objects fetch this
data as soon as they are created.

NOTE: It is pointless (though not an error) to give primary key column
here as these are always prefetched (in a sense).

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head3 add_group (C<Alzabo::Column> objects)

Given a list of L<C<Alzabo::Column>|Alzabo::Column> objects, this
method creates a group containing these columns.  This means that if
any column in the group is fetched from the database, then they will
all be fetched.  Otherwise column are always fetched singly.
Currently, a column cannot be part of more than one group.

NOTE: It is pointless to include a column that was given to the
L<C<set_prefetch()>|Alzabo::Runtime::Table/set_prefetch
(Alzabo::Column objects)> method in a group here, as it always fetched
as soon as possible.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 prefetch

This method primarily exists for use by the
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> class.

It returns a list of column names (not objects) that should be
prefetched.

=head2 group_by_column ($column_name)

This method primarily exists for use by the
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> class.

It returns a list of column names representing the group that the
given column is part of.  If the column is not part of a group, only
the name passed in is returned.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
