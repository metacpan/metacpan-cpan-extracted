##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields/Field.pm
## Version 0.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2020/01/01
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Fields::Field;
BEGIN
{
    use strict;
    use common::sense;
    use parent qw( Module::Generic );
    use Devel::Confess;
    use overload ('""'     => 'as_string',
                  fallback => 1,
                 );
    our( $VERSION ) = '0.1';
};

sub init
{
    my $self = shift( @_ );
    $self->{name} = '';
    $self->{type} = '';
    $self->{default} = '';
    $self->{pos} = '';
    $self->{prefixed} = 0;
    $self->{table_object} = '';
    $self->SUPER::init( @_ );
    return( $self->error( "No table object was provided." ) ) if( !$self->{table_object} );
    return( $self->error( "Table object provided is not an object." ) ) if( !$self->_is_object( $self->{table_object} ) );
    return( $self->error( "Table object provided is not a DB::Object::Tables object." ) ) if( !$self->{table_object}->isa( 'DB::Object::Tables' ) );
    return( $self->error( "No name was provided for this field." ) ) if( !$self->{name} );
    return( $self );
}

sub as_string { return( shift->name ); }

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
    if( $self->{prefixed} )
    {
        my @prefix = ();
        ## if the value is higher than 1, we also add the database name as a prefix
        ## For example $tbl->fields->some_field->prefixed(2)->name
        push( @prefix, $self->database ) if( $self->{prefixed} > 2 );
        push( @prefix, $self->table_object->schema ) if( $self->{prefixed} > 1 && CORE::length( $self->table_object->schema ) );
        push( @prefix, $self->table );
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
    return( $self );
}

sub prev
{
    my $self = shift( @_ );
    return( $self->_find_siblings( $self->pos - 1 ) );
}

sub schema { return( shift->table_object->schema ); }

sub table { return( shift->table_object->name ); }

sub table_name { return( shift->table_object->name ); }

sub table_object { return( shift->_set_get_object( 'table_object', 'DB::Object::Tables', @_ ) ); }

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

1;

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
    ## would print: my_shop.public.customers.currency
    print( "Trying again (should keep prefix): ", $c->name, "\n" );
    ## would print again: my_shop.public.customers.currency
    print( "Now cancel prefixing at the table fields level.\n" );
    $tbl_object->fo->prefixed( 0 );
    print( "Showing name fully qualified again (should not be prefixed): ", $c->name, "\n" );
    ## would print currency
    print( "First element is: ", $c->first, "\n" );
    print( "Last element is: ", $c->last, "\n" );

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is a table field object as instantiated by L<DB::Object::Fields>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %arg )

Creates a new L<DB::Object::Fields::Field> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<debug>

Toggles debug mode on/off

=back

=back

=head1 METHODS

=over 4

=item B<_find_siblings>()

Given a field position from 1 to n, this will find and return the field object. It returns undef or empty list if none could be found.

=item B<as_string>()

This returns the name of the field, possibly prefixed

This is also called to stringify the object

    print( "Field is: $field\n" );

=item B<database>()

Returns the name of the database this field is attached to.

=item B<database_object>()

Returns the database object, ie the one used to make sql queries

=item B<default>()

Returns the default value, if any, for that field.

=item B<first>()

Returns the first field in the table.

=item B<last>()

Returns the last field in the table.

=item B<name>()

Returns the field name. This is also what is returned when object is stringified. For example

    my $c = $tbl_object->fo->last_name;
    print( "$c\n" );
    ## will produce "last_name"

The output is altered by the use of B<prefixed>. See below.

=item B<next>()

Returns the next field object.

=item B<pos>()

Returns the position of the field in the table. This is an integer starting from 1.

=item B<prefixed>()

Called without argument, this will instruct the field name to be returned prefixed by the table name.

    print( $tbl_object->fo->last_name->prefixed, "\n" );
    ## would produce my_shop.last_name

B<prefixed> can also be called with an integer as argument. 1 will prefix it with the table name, 2 with the schema name and 3 with the database name.

=item B<prev>()

Returns the previous field object.

=item B<schema>()

Returns the table schema to which this field is attached.

=item B<table>()

Returns the table name for this field.

=item B<table_name>()

Same as above. This returns the table name.

=item B<table_object>()

Returns the table object which is a L<DB::Object::Tables> object.

=item B<type>()

Returns the field type such as C<jsonb>, Cjson>, C<varchar>, C<integer>, etc.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
