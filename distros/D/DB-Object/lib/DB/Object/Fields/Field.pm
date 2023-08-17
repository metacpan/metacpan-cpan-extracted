##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields/Field.pm
## Version v1.0.2
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2023/06/12
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Fields::Field;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use Devel::Confess;
    use Module::Generic::Array;
    use overload (
        '""'    => 'as_string',
        'bool'  => sub{1},
        '+'     => sub{ &_op_overload( @_, '+' ) },
        '-'     => sub{ &_op_overload( @_, '-' ) },
        '*'     => sub{ &_op_overload( @_, '*' ) },
        '/'     => sub{ &_op_overload( @_, '/' ) },
        '%'     => sub{ &_op_overload( @_, '%' ) },
        '<'     => sub{ &_op_overload( @_, '<' ) },
        '>'     => sub{ &_op_overload( @_, '>' ) },
        '<='    => sub{ &_op_overload( @_, '<=' ) },
        '>='    => sub{ &_op_overload( @_, '>=' ) },
        '!='    => sub{ &_op_overload( @_, '<>' ) },
        '<<'    => sub{ &_op_overload( @_, '<<' ) },
        '>>'    => sub{ &_op_overload( @_, '>>' ) },
        'lt'     => sub{ &_op_overload( @_, '<' ) },
        'gt'     => sub{ &_op_overload( @_, '>' ) },
        'le'    => sub{ &_op_overload( @_, '<=' ) },
        'ge'    => sub{ &_op_overload( @_, '>=' ) },
        'ne'    => sub{ &_op_overload( @_, '<>' ) },
        '&'     => sub{ &_op_overload( @_, '&' ) },
        '^'     => sub{ &_op_overload( @_, '^' ) },
        '|'     => sub{ &_op_overload( @_, '|' ) },
        '=='    => sub{ &_op_overload( @_, '=' ) },
        'eq'    => sub{ &_op_overload( @_, 'IS' ) },
        # Full Text Search operator
        '~~'    => sub{ &_op_overload( @_, '@@' ) },
        fallback => 1,
    );
    use Want;
    our( $VERSION ) = 'v1.0.2';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{default}        = '';
    $self->{name}           = '';
    $self->{pos}            = '';
    $self->{prefixed}       = 0;
    $self->{query_object}   = '';
    $self->{table_object}   = '';
    $self->{type}           = '';
    $self->{_init_params_order}   = [qw( table_object query_object default pos type prefixed name )];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self->error( "No table object was provided." ) ) if( !$self->{table_object} );
    return( $self->error( "Table object provided is not an object." ) ) if( !$self->_is_object( $self->{table_object} ) );
    return( $self->error( "Table object provided is not a DB::Object::Tables object." ) ) if( !$self->{table_object}->isa( 'DB::Object::Tables' ) );
    return( $self->error( "No name was provided for this field." ) ) if( !$self->{name} );
    $self->{trace} = $self->_get_stack_trace;
    return( $self );
}

sub as_string { return( shift->name ); }

# A data type constant
sub constant { return( shift->_set_get_hash_as_object( 'constant', @_ ) ); }

sub database { return( shift->database_object->database ); }

sub database_object { return( shift->table_object->database_object ); }

sub default { return( shift->_set_get_scalar( 'default', @_ ) ); }

sub first { return( shift->_find_siblings( 1 ) ); }

sub last
{
    my $self = shift( @_ );
    my $fields = $self->table_object->fields;
    my $pos = scalar( keys( %$fields ) );
    return( $self->_find_siblings( $pos ) );
}

sub name
{
    my $self = shift( @_ );
    no overloading;
    if( @_ )
    {
        $self->{name} = shift( @_ );
    }
    my $name = $self->{name};
    my $trace = $self->_get_stack_trace;
    my $alias = $self->query_object->table_alias;
    if( $self->{prefixed} )
    {
        my @prefix = ();
        if( length( $alias ) )
        {
            CORE::push( @prefix, $alias );
        }
        else
        {
            # if the value is higher than 1, we also add the database name as a prefix
            # For example $tbl->fields->some_field->prefixed(2)->name
            push( @prefix, $self->database ) if( $self->{prefixed} > 2 );
            push( @prefix, $self->table_object->schema ) if( $self->{prefixed} > 1 && CORE::length( $self->table_object->schema ) );
            push( @prefix, $self->table );
        }
        push( @prefix, $name );
        return( join( '.', @prefix ) );
    }
    else
    {
        return( $name );
    }
}

sub next
{
    my $self = shift( @_ );
    return( $self->_find_siblings( $self->pos + 1 ) );
}

sub pos { return( shift->_set_get_scalar( 'pos', @_ ) ); }

sub prefixed
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{prefixed} = ( $_[0] =~ /^\d+$/ ? $_[0] : ( $_[0] ? 1 : 0 ) );
    }
    else
    {
        $self->{prefixed} = 1;
    }
    return( want( 'OBJECT' ) ? $self : $self->{prefixed} );
}

sub prev
{
    my $self = shift( @_ );
    return( $self->_find_siblings( $self->pos - 1 ) );
}

sub query_object { return( shift->_set_get_object_without_init( 'query_object', 'DB::Object::Query', @_ ) ); }
# sub query_object { return( shift->table_object->query_object ); }

sub schema { return( shift->table_object->schema ); }

sub table { return( shift->table_object->name ); }

sub table_name { return( shift->table_object->name ); }

sub table_object { return( shift->_set_get_object_without_init( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub _find_siblings
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    return( $self->error( "No field position provided." ) ) if( !CORE::length( $pos ) );
    return if( $pos < 0 );
    my $fields = $self->table_object->fields;
    my $next_field;
    foreach my $f ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
    {
        if( $fields->{ $f } == $pos )
        {
            $next_field = $f;
            CORE::last;
        }
    }
    return if( !defined( $next_field ) );
    my $o = $self->table_object->fields_object->_initiate_field_object( $next_field ) ||
    return( $self->pass_error( $self->table_object->fields_object->error ) );
    return( $o );
}

# Ref:
# <https://www.postgresql.org/docs/10/functions-comparison.html>
# <https://www.postgresql.org/docs/10/functions-math.html>
# <https://dev.mysql.com/doc/refman/5.7/en/comparison-operators.html>
# <https://sqlite.org/lang_expr.html>
sub _op_overload
{
    my( $self, $val, $swap, $op ) = @_;
    if( $self->_is_a( $val => 'DB::Object::IN' ) )
    {
        return( $val->_opt_overload( $self, 1, $op ) );
    }
    
    # print( STDERR ref( $self ), "::_op_overload: Parameters provided are: '", join( "', '", @_ ), "'\n" );
    my $field = $self->name;
    my $map =
    {
    '!=' => '<>',
    'lt' => '<',
    'gt' => '>',
    'le' => '<=',
    'ge' => '>=',
    # '=' works for all types, but IS does not work with everything.
    # For example:
    # select * from ip_table where ip_addr IS inet '192.168.2.12' OR inet '192.168.2.12' << ip_addr
    # does not work, but
    # select * from ip_table where ip_addr = inet '192.168.2.12' OR inet '192.168.2.12' << ip_addr
    # works better
    '==' => '=',
    };
    $op = $map->{ $op } if( exists( $map->{ $op } ) );
    # $op = 'IS' if( $op eq '=' and $val eq 'NULL' );
    # If the value specified in the operation is a placeholder, or a field object or a statement object, we do not want to quote process it
    unless( $val eq '?' || 
            ( $self->_is_object( $val ) && 
              (
                $val->isa( 'DB::Object::Fields::Field' ) ||
                $val->isa( 'DB::Object::Statement' )
              )
            ) || 
            $self->database_object->placeholder->has( \$val ) ||
            $self->_is_scalar( $val ) ||
            uc( $val ) eq 'NULL' )
    {
        $val = $self->database_object->quote( $val, $self->constant->constant ) if( $self->database_object );
    }
    
    my $types;
    # If the value is a statement object, stringify it, surround it with parenthesis and use it
    if( $self->_is_a( $val, 'DB::Object::Statement' ) )
    {
        $val = '(' . $val->as_string . ')';
    }
    elsif( $self->database_object->placeholder->has( $self->_is_scalar( $val ) ? $val : \$val ) )
    {
        $types = $self->database_object->placeholder->replace( \$val );
    }
    # A placeholder, but don't know the type
    elsif( $val eq '?' )
    {
        $types = Module::Generic::Array->new( [''] );
    }
    elsif( $self->_is_scalar( $val ) )
    {
        $val = $$val;
    }
    return( DB::Object::Fields::Field::Overloaded->new(
        expression => 
            (
                $swap
                    ? "${val} ${op} ${field}" 
                    : "${field} ${op} ${val}"
            ),
        field => $self,
        binded => ( $val eq '?' || $types ) ? 1 : 0,
        # types => $types,
    ) );
}

{
    # NOTE: package DB::Object::Fields::Field::Overloaded
    # The purpose of this package is to tag overloaded operation so we can handle them properly later
    # such as in a where clause
    package
        DB::Object::Fields::Field::Overloaded;
    use strict;
    use common::sense;
    use overload (
        '""'    => sub{ return( $_[0]->{expression} ) },
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';

    sub new
    {
        my $this = shift( @_ );
        # This contains the result of the sql field with its operator and value during overloading
        # expression, field, binded, types
        my $opts = { @_ };
        # So it can be called in chaining whether it contains data or not
        $opts->{types} //= Module::Generic::Array->new;
        return( bless( $opts => ref( $this ) || $this ) );
    }
    
    sub binded { return( shift->{binded} ); }
    
    sub field { return( shift->{field} ); }

    sub types { return( shift->{types} ); }
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DB::Object::Fields::Field - Table Field Object

=head1 SYNOPSIS

    my $dbh = DB::Object->connect({
        driver => 'Pg',
        conf_file => $conf,
        database => 'my_shop',
        host => 'localhost',
        login => 'super_admin',
        schema => 'auth',
        # debug => 3,
    }) || bailout( "Unable to connect to sql server on host localhost: ", DB::Object->error );
    my $tbl_object = $dbh->customers || die( "Unable to get the customers table object: ", $dbh->error, "\n" );
    my $fields = $tbl_object->fields;
    print( "Fields for table \"", $tbl_object->name, "\": ", Dumper( $fields ), "\n" );
    my $c = $tbl_object->fo->currency;
    print( "Got field object for currency: \"", ref( $c ), "\": '$c'\n" );
    printf( "Name: %s\n", $c->name );
    printf( "Type: %s\n", $c->type );
    printf( "Default: %s\n", $c->default );
    printf( "Position: %s\n", $c->pos );
    printf( "Table: %s\n", $c->table );
    printf( "Database: %s\n", $c->database );
    printf( "Schema: %s\n", $c->schema );
    printf( "Next field: %s (%s)\n", $c->next, ref( $c->next ) );
    print( "Showing name fully qualified: ", $c->prefixed( 3 )->name, "\n" );
    # would print: my_shop.public.customers.currency
    print( "Trying again (should keep prefix): ", $c->name, "\n" );
    # would print again: my_shop.public.customers.currency
    print( "Now cancel prefixing at the table fields level.\n" );
    $tbl_object->fo->prefixed( 0 );
    print( "Showing name fully qualified again (should not be prefixed): ", $c->name, "\n" );
    # would print currency
    print( "First element is: ", $c->first, "\n" );
    print( "Last element is: ", $c->last, "\n" );
    # Works also with the operators +, -, *, /, %, <, <=, >, >=, !=, <<, >>, &, |, ^, ==
    my $table = $dbh->dummy;
    $table->select( $c + 10 ); # SELECT currency + 10 FROM dummy;
    $c == 'NULL' # currency IS NULL

You can also use a L<DB::Object::Statement> as a value in the operation:

    my $tbl = $dbh->services || die( "Unable to get the table object \"services\": ", $dbh->error );
    my $userv_tbl = $dbh->user_services || die( "Unable to get the table object \"user_services\": ", $tbl->->error );
    $tbl->where( $tbl->fo->name == '?' );
    my $sub_sth = $tbl->select( 'id' ) || die( "Unable to prepare the sql query to get the service id: ", $tbl->error );
    $userv_tbl->where(
        $dbh->AND(
            $tbl->fo->user_id == '?',
            $tbl->fo->service_id == $sub_sth
        )
    );
    my $query = $userv_tbl->delete->as_string || die( $tbl->error );

This would yield:

    DELETE FROM user_services WHERE user_id = ? AND name = (SELECT id FROM services WHERE name = ?)

=head1 VERSION

    v1.0.2

=head1 DESCRIPTION

This is a table field object as instantiated by L<DB::Object::Fields>

=head1 CONSTRUCTOR

=head2 new

Takes an hash or hash reference of parameters and this will create a new L<DB::Object::Fields::Field> object.

=over 4

=item I<debug>

Toggles debug mode on/off

=item I<default>

=item I<name>

The table column name.

An error will be returned if this value is not provided upon instantiation.

=item I<pos>

The table column position in the table.

=item I<prefixed>

Defaults to 0

=item I<query_object>

The L<DB::Object::Query> object.

=item I<table_object>

The L<DB::Object::Tables> object.

An error will be returned if this value is not provided upon instantiation.

=item I<type>

The column data type.

=back

=head1 METHODS

=head2 as_string

This returns the name of the field, possibly prefixed

This is also called to stringify the object

    print( "Field is: $field\n" );

=head2 constant

A data type constant set by L<DB::Object::Table/structure>. This helps determine how to deal with some fields.

This is an hash object that contains 3 properties:

=over 4

=item I<constant>

An integer set by the database driver to represent the constant

=item I<name>

The constant name, e.g. C<PG_JSONB>

=item I<type>

The data type, e.g. C<jsonb>

=back

=head2 database

Returns the name of the database this field is attached to.

=head2 database_object

Returns the database object, ie the one used to make sql queries

=head2 default

Returns the default value, if any, for that field.

=head2 first

Returns the first field in the table.

=head2 last

Returns the last field in the table.

=head2 name

Returns the field name. This is also what is returned when object is stringified. For example

    my $c = $tbl_object->fo->last_name;
    print( "$c\n" );
    # will produce "last_name"

The output is altered by the use of B<prefixed>. See below.

=head2 next

Returns the next field object.

=head2 pos

Returns the position of the field in the table. This is an integer starting from 1.

=head2 prefixed

Called without argument, this will instruct the field name to be returned prefixed by the table name.

    print( $tbl_object->fo->last_name->prefixed, "\n" );
    # would produce my_shop.last_name

B<prefixed> can also be called with an integer as argument. 1 will prefix it with the table name, 2 with the schema name and 3 with the database name.

=head2 prev

Returns the previous field object.

=head2 query_object

The query object (L<DB::Object::Query> or one of its descendant)

=head2 schema

Returns the table schema to which this field is attached.

=head2 table

Returns the table name for this field.

=head2 table_name

Same as above. This returns the table name.

=head2 table_object

Returns the table object which is a L<DB::Object::Tables> object.

=head2 type

Returns the field type such as C<jsonb>, Cjson>, C<varchar>, C<integer>, etc.

See also L</constant> for an even more accurate data type, and the driver associated constant that is used for binding values to placeholders.

=head2 _find_siblings

Given a field position from 1 to n, this will find and return the field object. It returns undef or empty list if none could be found.

=head1 OVERLOADING

The following operators are overloaded:

    +, -, *, /, %, <, <=, >, >=, !=, <<, >>, lt, gt, le, ge, ne, &, |, ^, ==, eq, ~~

Thus a field named "dummy" could be used like:

    $f + 10

which would become:

    dummy + 10

And this works too:

    10 + $f # 10 + dummy

Another example, which works in PostgreSQL:

    $ip_tbl->where( 'inet 192.16.1.20' << $ip_tbl->fo->ip_addr );
    my $ref = $ip_tbl->select->fetchrow_hashref;

The equal operator C<==> would become C<=>:

    $f == 'NULL' # dummy = NULL

but, if you use perl's C<eq> instead of C<==>, you would get:

    $f eq 'NULL' # dummy IS NULL

Note that you have to take care of quotes yourself, because there is no way to tell if the right hand side is a string or a function

    $f == q{'JPY'} # dummy IS 'JPY'

or, to insert a placeholder

    $f == '?' # dummy = ?
    # or;
    $f eq '?' # dummy IS ?
    my $sth = $table->select( $f eq '?' ); # SELECT dummy IS ? FROM some_table
    my $row = $sth->exec( 'JPY' )->fetchrow;

of course

    my $sth = $table->select( dummy => '?' );

also works

The C<=~> and C<!~> operators cannot be overloaded in perl, so for regular expressions, use the C<REGEXP> function if available, or provided the expression directly as a string:

    $table->select( "currency ~ '^[A-Z]{3}$'" );

If you want to use placeholder in the value provided, you will have to provide a C<?> in the value next to the operator. This module will not parse the value used with the operation, so if you wanted to use a placeholder in:

    $f == "'JPY'"

Simply provide:

    $f == '?'

You can use the search operator C<~~> for SQL Full Text Search and it would be converted into C<@@>:

Let's imagine a table C<articles> in a L<PostgreSQL database|https://www.postgresql.org/docs/current/textsearch.html>, such as:

    CREATE TABLE articles (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        ts TSVECTOR GENERATED ALWAYS AS
            (setweight(to_tsvector('english', coalesce(title, '')), 'A') || 
            setweight(to_tsvector('english', coalesce(content, '')), 'B')) STORED
    );

them you coud do:

    $tbl->where(
        \"websearch_to_tsquery(?)" ~~ $tbl->fo->ts,
    );

and this would create a C<WHERE> clause, such as:

    WHERE websearch_to_tsquery(?) @@ ts

See L<PostgreSQL documentation|https://www.postgresql.org/docs/current/textsearch.html> for more details.

but, under L<SQLite|https://www.sqlite.org/fts5.html>, this is not necessary, because the Full Text Search syntax is different:

Create a FTS-enabled virtual table.

    CREATE VIRTUAL TABLE articles 
    USING FTS5(title, content);

then query it:

    SELECT * FROM articles WHERE articles MATCH(?);

See L<SQLite documentation|https://www.sqlite.org/fts5.html> for more details.

and, in a L<MySQL database|https://dev.mysql.com/doc/refman/8.0/en/fulltext-search.html>, also unnecessary, because a bit different:

    CREATE TABLE articles (
        id INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        FULLTEXT (title,content)
    ) ENGINE=InnoDB;

then:

    SELECT * FROM articles WHERE MATCH(title,content) AGAINST(? IN NATURAL LANGUAGE MODE);

See L<MySQL documentation|https://dev.mysql.com/doc/refman/8.0/en/fulltext-search.html> for more details.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
