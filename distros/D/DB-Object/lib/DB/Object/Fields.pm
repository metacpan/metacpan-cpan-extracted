##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields.pm
## Version 0.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2020/01/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Fields;
BEGIN
{
    use strict;
    use common::sense;
    use DB::Object::Fields::Field;
    use parent qw( Module::Generic );
    use Devel::Confess;
    our( $VERSION ) = '0.1';
};

sub init
{
    my $self = shift( @_ );
    $self->{table_object} = '';
    $self->{prefixed} = 0;
    ## $self->{fatal} = 1;
    $self->SUPER::init( @_ );
    return( $self->error( "No table object was provided" ) ) if( !$self->{table_object} );
    return( $self );
}

sub database_object { return( shift->table_object->database_object ); }

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
    my $fields = $self->table_object->fields;
    foreach my $f ( keys( %$fields ) )
    {
        next if( !CORE::length( $self->{ $f } ) );
        next if( !$self->_is_object( $self->{ $f } ) );
        my $o = $self->{ $f };
        $o->prefixed( $self->{prefixed} );
    }
    return( $self );
}

sub table_object { return( shift->_set_get_object( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub _initiate_field_object
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided to get its object." ) );
    my $class = ref( $self ) || $self;
    my $fields = $self->table_object->fields;
    return( $self->error( "Table ", $self->table_object->name, " has no such field \"$field\"." ) ) if( !CORE::exists( $fields->{ $field } ) );
    eval( "sub ${class}::${field} { return( shift->_set_get_object( '$field', 'DB::Object::Fields::Field', \@_ ) ); }" );
    die( $@ ) if( $@ );
    my $def    = $self->table_object->default;
    my $types  = $self->table_object->types;
    my $hash =
    {
    debug => $self->debug,
    name => $field,
    type => $types->{ $field },
    default => $def->{ $field },
    pos => $fields->{ $field },
    prefixed => $self->{prefixed},
    table_object => $self->table_object,
    };
#     $self->message( 3, "Initiating field '$field' with hash data: ", sub{ $self->dump( $hash ) } );
    my $o = DB::Object::Fields::Field->new( $hash );
    $self->$field( $o ) || return;
    return( $o );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $fields = $self->table_object->fields;
    if( $code = $self->can( $method ) )
    {
        return( $code->( @_ ) );
    }
    ## elsif( CORE::exists( $self->{ $method } ) )
    elsif( exists( $fields->{ $method } ) )
    {
        return( $self->_initiate_field_object( $method ) );
    }
    else
    {
        return( $self->error( "Table ", $self->table_object->name, " has no such field \"$method\"." ) );
        #die( "Table ", $self->table_object->name, " has no such field \"$method\".\n" );
    }
};

1;

__END__

=encoding utf8

=head1 NAME

DB::Object::Fields - Tables Fields Object Accessor

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

The purpose of this module is to enable access to the table fields as L<DB::Object::Fields::Field> objects.

The way this works is by having L<DB::Object::Tables> B<fields_object> or B<fo> for short, dynamically create a class based on the database name and table name. For example if the database driver were C<PostgreSQL>, the database were C<my_shop> and the table C<customers>, the dynamically created package would become L<DB::Object::Postgres::Tables::MyShop::Customers>. This class would inherit from this package L<DB::Object::Fields>.

Field objects can than be dynamically instantiated by accessing them, such as (assuming the table object C<$tbl_object> here represent the table C<customers>) C<$tbl_object->fo->last_name>. This will return a L<DB::Object::Fields::Field> object.

A note on the design: there had to be a separate this separate package L<DB::Object::Fields>, because access to table fields is done through the C<AUTOLOAD> and the methods within the package L<DB::Object::Tables> and its inheriting packages would clash with the tables fields. This package has very few methods, so the risk of a sql table field clashing with a method name is very limited. In any case, if you have in your table a field with the same name as one of those methods here (see below for the list), then you can instantiate a field object with:

    $tbl_object->_initiate_field_object( 'last_name' );

=head1 CONSTRUCTOR

=over 4

=item B<new>( %arg )

Creates a new L<DB::Object::Fields> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<debug>

Toggles debug mode on/off

=back

=back

=head1 METHODS

=over 4

=item B<_initiate_field_object>()

=item B<database_object>()

=item B<init>()

=item B<prefixed>()

=item B<table_object>()

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
