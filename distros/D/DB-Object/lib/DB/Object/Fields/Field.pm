##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields/Field.pm
## Version v1.2.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2025/03/06
## All rights reserved
## 
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
    use DB::Object::Fields::Overloaded;
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
        # In most SQL driver, '<>' is more portable tan '!='
        '!='    => sub{ &_op_overload( @_, '<>' ) },
        '<<'    => sub{ &_op_overload( @_, '<<' ) },
        '>>'    => sub{ &_op_overload( @_, '>>' ) },
        'lt'    => sub{ &_op_overload( @_, '<' ) },
        'gt'    => sub{ &_op_overload( @_, '>' ) },
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
    use Wanted;
    our $VERSION = 'v1.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{check_name}     = undef;
    $self->{comment}        = undef;
    $self->{datatype}       = undef;
    $self->{default}        = undef;
    $self->{foreign_name}   = undef;
    $self->{index_name}     = undef;
    $self->{is_array}       = undef;
    $self->{is_check}       = undef;
    $self->{is_foreign}     = undef;
    $self->{is_nullable}    = undef;
    $self->{is_primary}     = undef;
    $self->{is_unique}      = undef;
    $self->{name}           = undef;
    $self->{pos}            = undef;
    $self->{prefixed}       = 0;
    $self->{query_object}   = undef;
    $self->{size}           = undef;
    $self->{table_object}   = undef;
    $self->{type}           = undef;
    $self->{_init_params_order}   = [qw( table_object query_object default pos type prefixed name )];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_fields} = [qw(
        check_name comment datatype default foreign_name index_name is_array is_check
        is_foreign is_nullable is_primary is_unique name pos prefixed size type
    )];
    return( $self->error( "No table object was provided." ) ) if( !$self->{table_object} );
    return( $self->error( "Table object provided is not an object." ) ) if( !$self->_is_object( $self->{table_object} ) );
    return( $self->error( "Table object provided is not a DB::Object::Tables object." ) ) if( !$self->{table_object}->isa( 'DB::Object::Tables' ) );
    return( $self->error( "No name was provided for this field." ) ) if( !$self->{name} );
    $self->{trace} = $self->_get_stack_trace;
    return( $self );
}

sub as_string { return( shift->name ); }

sub clone
{
    my $self = shift( @_ );
    # Fields to clone: we explicitly want to avoid cloning query_object, because it is not necessary and because it contains an object to the database connection that we do not want to clone.
    # Likewise, the query object, we do not want to clone either.
    # my $keys = [qw( default is_nullable name pos prefixed size type )];
    my $keys = $self->_fields;
    my $hash = {};
    @$hash{ @$keys } = @$self{ @$keys };
    # $hash->{datatype} = {};
    # for( qw( alias constant name re type ) )
    # {
    #     $hash->{datatype}->{ $_ } = $self->datatype->$_;
    # }
    my $dt = $self->datatype;
    $hash->{datatype} = 
    {
    alias => $dt->alias->clone,
    constant => $dt->{constant},
    name => $dt->{name},
    re => $dt->{re},
    type => $dt->{type},
    };
    $self->_load_class( 'Clone' ) || return( $self->pass_error );
    my $copy = Clone::clone( $hash );
    $copy->{query_object} = $self->query_object;
    $copy->{table_object} = $self->table_object;
    my $new = $self->new( %$copy, debug => $self->debug ) || return( $self->pass_error );
    return( $new );
}

sub check_name { return( shift->_set_get_scalar( 'check_name', @_ ) ); }

sub comment { return( shift->_set_get_scalar( 'comment', @_ ) ); }

# A data type constant
# sub constant { return( shift->_set_get_hash_as_object( 'constant', @_ ) ); }
sub constant { return( shift->datatype->constant( @_ ) ); }

sub database { return( shift->database_object->database ); }

sub database_object { return( shift->table_object->database_object ); }

sub datatype { return( shift->_set_get_class( 'datatype', {
    alias => { type => 'array_as_object' },
    constant => { type => 'scalar' },
    name => { type => 'scalar_as_object' },
    re => { type => 'object', package => 'Regexp' },
    type => { type => 'scalar_as_object' },
}, @_ ) ); }

sub default { return( shift->_set_get_scalar( 'default', @_ ) ); }

sub foreign_name { return( shift->_set_get_scalar( 'foreign_name', @_ ) ); }

sub first { return( shift->_find_siblings(1) ); }

sub index_name { return( shift->_set_get_scalar( 'index_name', @_ ) ); }

sub is_array { return( shift->_set_get_boolean( 'is_array', @_ ) ); }

sub is_check { return( shift->_set_get_boolean( 'is_check', @_ ) ); }

sub is_foreign { return( shift->_set_get_boolean( 'is_foreign', @_ ) ); }

sub is_nullable { return( shift->_set_get_boolean( 'is_nullable', @_ ) ); }

sub is_primary { return( shift->_set_get_boolean( 'is_primary', @_ ) ); }

sub is_unique { return( shift->_set_get_boolean( 'is_unique', @_ ) ); }

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

sub schema { return( shift->table_object->schema ); }

sub size { return( shift->_set_get_number( 'size', @_ ) ); }

sub table { return( shift->table_object->name ); }

sub table_name { return( shift->table_object->name ); }

sub table_object { return( shift->_set_get_object_without_init( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub _fields { return( shift->_set_get_array_as_object( '_fields', @_ ) ); }

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
    if( $self->_is_a( $val => [qw( DB::Object::IN DB::Object::LIKE )] ) )
    {
        return( $val->_opt_overload( $self, 1, $op ) );
    }

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
    my $dbo = $self->database_object;
    my $qo = $self->query_object;
    my $placeholder_re = $dbo->_placeholder_regexp;
    my $const = $self->datatype->constant;
    # $op = 'IS' if( $op eq '=' and $val eq 'NULL' );
    # If the value specified in the operation is a placeholder, or a field object or a statement object, we do not want to quote process it
    unless( $val =~ /^$placeholder_re$/ || 
            ( $self->_is_object( $val ) && 
              (
                $val->isa( 'DB::Object::Fields::Field' ) ||
                $val->isa( 'DB::Object::Statement' )
              )
            ) || 
            $dbo->placeholder->has( \$val ) ||
            $self->_is_scalar( $val ) ||
            uc( $val ) eq 'NULL' )
    {
        $val = $dbo->quote( $val, $const ) if( $dbo );
    }

    my $types;
    # If the value is a statement object, stringify it, surround it with parenthesis and use it
    if( $self->_is_a( $val, 'DB::Object::Statement' ) )
    {
        $self->messagec( 5, "Merging {green}", $val->query_object->elements->length, "{/} elements from this statement object associated with out field {green}", $self->as_string, "{/}" );
        $qo->elements->merge( $val->query_object->elements );
        $val = '(' . $val->as_string . ')';
    }
    elsif( $dbo->placeholder->has( $self->_is_scalar( $val ) ? $val : \$val ) )
    {
        $types = $dbo->placeholder->replace( $self->_is_scalar( $val ) ? $val : \$val );
    }
    # A placeholder, but don't know the type
    elsif( $val =~ /^$placeholder_re$/ )
    {
        $types = Module::Generic::Array->new( [''] );
    }
    elsif( $self->_is_scalar( $val ) )
    {
        $val = $$val;
    }
#     return( DB::Object::Fields::Overloaded->new(
#         expression => 
#             (
#                 $swap
#                     ? "${val} ${op} ${field}" 
#                     : "${field} ${op} ${val}"
#             ),
#         field => $self,
#         # binded => ( $val =~ /^$placeholder_re$/ || $types ) ? 1 : 0,
#         ( $val =~ /^$placeholder_re$/ ? ( placeholder => $val ) : () ),
#         type => $self->type,
#         # query_object => $self->query_object,
#         debug => $self->debug,
#         ( $val !~ /^$placeholder_re$/ ? ( value => $val ) : () ),
#         # binded_offset => ( $val =~ /^$placeholder_re$/ && defined( $+{offset} ) ) ? ( $+{offset} - 1 ) : undef,
#         # types => $types,
#     ) );
    my $over = DB::Object::Fields::Overloaded->new(
        expression => 
            (
                $swap
                    ? "${val} ${op} ${field}" 
                    : "${field} ${op} ${val}"
            ),
        field => $self,
        # binded => ( $val =~ /^$placeholder_re$/ || $types ) ? 1 : 0,
        ( $val =~ /^$placeholder_re$/ ? ( placeholder => $val ) : () ),
        # Actually type() will return us the actual data type, not the driver constant
        # type => $self->type,
        ( defined( $const ) ? ( type => $const ) : () ),
        query_object => $qo,
        debug => $self->debug,
        ( $val !~ /^$placeholder_re$/ ? ( value => $val ) : () ),
        # binded_offset => ( $val =~ /^$placeholder_re$/ && defined( $+{offset} ) ) ? ( $+{offset} - 1 ) : undef,
        # types => $types,
    );
    return( $over );
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
    printf( "Is nullable: %s\n", $c->is_nullable );
    printf( "Is primary key: %s\n", $c->is_primary );
    printf( "Is an array: %s\n", $c->is_array );
    printf( "Position: %s\n", $c->pos );
    # For example for varchar, this could be 255 based on the table schema
    printf( "Size: %s\n", $c->size );
    printf( "Table: %s\n", $c->table );
    printf( "Database: %s\n", $c->database );
    printf( "Schema: %s\n", $c->schema );
    printf( "Field comment: %s\n", $c->comment );
    printf( "Constant value: %s\n", $c->datatype->constant ); # 12
    printf( "Constant name: %s\n", $c->datatype->name ); # For example: SQL_VARCHAR
    printf( "Constant type: %s\n", $c->datatype->type ); # varchar
    printf( "Next field: %s (%s)\n", $c->next, ref( $c->next ) );
    print( "Showing name fully qualified: ", $c->prefixed(3)->name, "\n" );
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

    v1.2.0

=head1 DESCRIPTION

This is a table field object as instantiated by L<DB::Object::Fields>

=head1 CONSTRUCTOR

=head2 new

Takes an hash or hash reference of parameters and this will create a new L<DB::Object::Fields::Field> object.

=over 4

=item * C<check_name>

Specifies the name of the check constraint associated wit this field.

=item * C<comment>

Specifies the field comment, if any.

=item * C<datatype>

Specifies an hash of key-value pairs, namely: C<name>, C<constant>, C<type> and C<re>

=item * C<debug>

Toggles debug mode on/off

=item * C<default>

Specifies the  default field value.

=item * C<foreign_name>

Specifies the name of the foreign key constraint associated wit this field.

=item * C<index_name>

Specifies the index name to which this field is related.

=item * C<is_array>

Specifies a boolean value whether the field value represents an array or not.

=item * C<is_check>

Specifies a boolean value whether the field is associated with a check constraint or not.

=item * C<is_foreign>

Specifies a boolean value whether the field is associated with a foreign key constraint or not.

=item * C<is_nullable>

Specifies a boolean value whether the field value can be null or not.

=item * C<is_primary>

Specifies a boolean value whether the field is the primary key for its table or not.

=item * C<is_unique>

Specifies a boolean value whether the field is part of a unique index or not.

=item * C<name>

The table column name.

An error will be returned if this value is not provided upon instantiation.

=item * C<pos>

The table column position in the table.

=item * C<prefixed>

Defaults to 0

=item * C<query_object>

The L<DB::Object::Query> object.

=item * C<size>

Set the field size, such as for varchar.

Defaults to C<undef>

=item * C<table_object>

The L<DB::Object::Tables> object.

An error will be returned if this value is not provided upon instantiation.

=item * C<type>

The column data type.

=back

=head1 METHODS

=head2 as_string

This returns the name of the field, possibly prefixed

This is also called to stringify the object

    print( "Field is: $field\n" );

=head2 clone

Makes a clone of the object and returns it.

However, it does not makes a clone of the entire field object, but instead leaves out the L<query object|DB::Object::Query> and the L<table object|DB::Object::Tables>

=head2 constant

A data type constant set by L<DB::Object::Table/structure>. This helps determine how to deal with some fields.

This is an hash object that contains 3 properties:

=over 4

=item * C<constant>

An integer set by the database driver to represent the constant

=item * C<name>

The constant name, e.g. C<PG_JSONB>

=item * C<type>

The data type, e.g. C<jsonb>

=back

=head2 check_name

Sets or gets the optional name of the check constraint associated with this field.

=head2 comment

Sets or gets the optional comment that may have been set for this table field.

=head2 database

Sets or gets the name of the database this field is attached to.

=head2 database_object

Returns the database object, ie the one used to make sql queries

=head2 default

Sets or gets the default value, if any, for that field.

=head2 foreign_name

Sets or gets the optional name of the foreign key constraint associated with this field.

=head2 first

Returns the first field in the table.

=head2 index_name

Sets or gets the index name to which this field is related. Defaults to C<undef>

=head2 is_array

Sets or gets true if the field is an array, or false otherwise.

=head2 is_check

Sets or gets true if the field is associated with a check constraint, or false otherwise.

=head2 is_foreign

Sets or gets true if the field is associated with a foreign key constraint, or false otherwise.

=head2 is_nullable

Sets or gets true if the field can be null, or false otherwise.

=head2 is_primary

Sets or gets true if the field is the primary key of the table, or false otherwise.

=head2 is_unique

Sets or gets true if the field is part of a unique index, or false otherwise.

If it is, check out the value for L<index_name|/index_name>

=head2 last

Returns the last field in the table.

=head2 name

Sets or gets the field name. This is also what is returned when object is stringified. For example

    my $c = $tbl_object->fo->last_name;
    print( "$c\n" );
    # will produce "last_name"

The output is altered by the use of B<prefixed>. See below.

=head2 next

Returns the next field object.

=head2 pos

Sets or gets the position of the field in the table. This is an integer starting from 1.

=head2 prefixed

Called without argument, this will instruct the field name to be returned prefixed by the table name.

    print( $tbl_object->fo->last_name->prefixed, "\n" );
    # would produce my_shop.last_name

B<prefixed> can also be called with an integer as argument. 1 will prefix it with the table name, 2 with the schema name and 3 with the database name.

=head2 prev

Returns the previous field object.

=head2 query_object

Sets or gets the query object (L<DB::Object::Query> or one of its descendant)

=head2 schema

Returns the table schema to which this field is attached.

=head2 size

Sets or gets the size of the field when appropriate, such as when the type is C<varchar> or C<char>

=head2 table

Returns the table name for this field.

=head2 table_name

Same as above. This returns the table name.

=head2 table_object

Sets or gets the table object which is a L<DB::Object::Tables> object.

=head2 type

Returns the field type such as C<jsonb>, C<json>, C<varchar>, C<integer>, etc.

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
