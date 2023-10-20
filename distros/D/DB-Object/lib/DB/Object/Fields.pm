##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields.pm
## Version v1.1.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2023/03/24
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Fields;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use DB::Object::Fields::Field;
    use Devel::Confess;
    our $VERSION = 'v1.1.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{prefixed} = 0;
    # Property 'query_object' not used anymore. Instead, we use table_object->query_object
    $self->{table_object} = '';
    # $self->{fatal} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order} = [qw( table_object query_object prefixed )];
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

# sub query_object { return( shift->_set_get_object_without_init( 'query_object', 'DB::Object::Query', @_ ) ); }
sub query_object { return( shift->table_object->query_object ); }

sub table_object { return( shift->_set_get_object_without_init( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub _initiate_field_object
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided to get its object." ) );
    my $class = ref( $self ) || $self;
    my $tbl = $self->table_object;
    $self->messagec( 5, "Instantiating field {green}${field}{/} object for class {green}${class}{/} and table {green}", $tbl->name, "{/} having alias of {green}", ( $tbl->as // 'undef' ), "{/} ({green}", $self->{prefixed}, "{/})" );
    my $fields = $tbl->fields;
    return( $self->error( "Table ", $tbl->name, " has no such field \"$field\"." ) ) if( !CORE::exists( $fields->{ $field } ) );
    my $qo    = $tbl->query_object;
    my $def   = $tbl->default;
    my $types = $tbl->types;
    my $const = $tbl->types_const;
    my $debug = $self->debug;
    $const->{ $field }->{constant} //= q{''};
    $const->{ $field }->{name} //= '';
    $const->{ $field }->{type} //= '';
    my $hash  =
    {
    debug        => ( $self->debug || 0 ),
    name         => $field,
    type         => ( $types->{ $field } // '' ),
    default      => ( $def->{ $field } // '' ),
    pos          => ( $fields->{ $field } // '' ),
    const        => $const->{ $field },
    prefixed     => $self->{prefixed},
    query_object => $qo,
    table_object => $tbl,
    };
    my $perl = <<EOT;
package ${class};
sub ${field}
{
    my \$self = shift( \@_ );
    unless( \$self->{$field} )
    {
        \$self->{$field} = DB::Object::Fields::Field->new(
            debug => ( \$self->debug // 0 ),
            name => '$field',
            type => '$hash->{type}',
            default => '$hash->{default}',
            pos => $hash->{pos},
            constant => { constant => $hash->{const}->{constant}, name => '$hash->{const}->{name}', type => '$hash->{const}->{type}' },
            prefixed => \$self->{prefixed},
            query_object => \$self->table_object->query_object,
            table_object => \$self->table_object,
        );
    }
    return( \$self->{$field} );
}
EOT
    eval( $perl );
    die( $@ ) if( $@ );
    # my $o = DB::Object::Fields::Field->new( $hash );
    my $o = $self->$field;
    # $self->$field( $o ) || return( $self->error( "Unable to set field '$field' object to '$o': ", $self->error ) );
    return( $o );
}

# NOTE: AUTOLOAD
AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $fields = $self->table_object->fields;
    $self->messagec( 5, "Called for method {green}${method}{/}" );
    if( my $code = $self->can( $method ) )
    {
        return( $code->( $self, @_ ) );
    }
    elsif( exists( $fields->{ $method } ) )
    {
        $self->messagec( 5, "Instantiating a new field object for {green}${method}{/}" );
        return( $self->_initiate_field_object( $method ) );
    }
    else
    {
        # This is an unrecoverable error. We have no choice, but to die.
        my $error = "Table " . $self->table_object->name . " has no such field \"$method\"";
        $self->_load_class( 'Module::Generic::Exception' ) || die( $self->error );
        my $exception = Module::Generic::Exception->new( $error );
        my $on_unknown_field = $self->table_object->database_object->unknown_field;
        if( ref( $on_unknown_field ) eq 'CODE' )
        {
            return( $on_unknown_field->({
                table => $self->table_object,
                field => $method,
                error => $exception,
            }) );
        }
        elsif( defined( $on_unknown_field ) && ( $on_unknown_field eq 'die' || $on_unknown_field eq 'fatal' ) )
        {
            die( $exception );
        }
        else
        {
            $self->_load_class( 'DB::Object::Fields::Unknown' ) ||
                die( "${error}, and I could not load the module DB::Object::Fields::Unknown: ", $self->error );
            my $unknown = DB::Object::Fields::Unknown->new(
                table => $self->table_object->name,
                error => $exception,
                field => $method,
            ) || die( "${error}, and I could not instantiate a new instance of the module DB::Object::Fields::Unknown: ", DB::Object::Fields::Unknown->error );
            warn( "Table ", $self->table_object->name, " has no such field \"$method\".\n" ) if( $self->_is_warnings_enabled( 'DB::Object' ) );
            # return( $self->error( "Table ", $self->table_object->name, " has no such field \"$method\"." ) );
            #die( "Table ", $self->table_object->name, " has no such field \"$method\".\n" );
            return( $unknown );
        }
    }
};

1;
# NOTE: POD
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
        unknown_field => 'fatal',
        # debug => 3,
    }) || bailout( "Unable to connect to sql server on host localhost: ", DB::Object->error );
    
    my $tbl = $dbh->some_table || die( "No table \"some_table\" could be found: ", $dbh->error, "\n" );
    my $fo = $tbl->fields_object || die( $tbl->error );
    my $expr = $fo->id == 2;
    print "Expression is: $expr\n"; # Expression is: id = 2

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
    # Works also with the operators +, -, *, /, %, <, <=, >, >=, !=, <<, >>, &, |, ^, ==
    my $table = $dbh->dummy;
    $table->select( $c + 10 ); # SELECT currency + 10 FROM dummy;
    $c == 'NULL' # currency IS NULL

    # if DB::Object unknown_field option is set to fatal, this will die. By default, it will simply be ignored
    my $unknown_field = $tbl->unknown;

=head1 VERSION

    v1.1.1

=head1 DESCRIPTION

The purpose of this module is to enable access to the table fields as L<DB::Object::Fields::Field> objects.

The way this works is by having L<DB::Object::Tables/fields_object> or L<DB::Object::Tables/fo> for short, dynamically create a class based on the database name and table name. For example if the database driver were C<PostgreSQL>, the database were C<my_shop> and the table C<customers>, the dynamically created package would become C<DB::Object::Postgres::Tables::MyShop::Customers>. This class would inherit from this package L<DB::Object::Fields>.

Field objects can than be dynamically instantiated by accessing them, such as (assuming the table object C<$tbl_object> here represent the table C<customers>) C<$tbl_object->fo->last_name>. This will return a L<DB::Object::Fields::Field> object.

A note on the design: there had to be a separate this separate package L<DB::Object::Fields>, because access to table fields is done through the C<AUTOLOAD> and the methods within the package L<DB::Object::Tables> and its inheriting packages would clash with the tables fields. This package has very few methods, so the risk of a sql table field clashing with a method name is very limited. In any case, if you have in your table a field with the same name as one of those methods here (see below for the list), then you can instantiate a field object with:

    $tbl_object->_initiate_field_object( 'last_name' );

If you call an unknown field, its behaviour will change depending on the option value C<unknown_field> of L<DB::Object> upon instantiation:

=over 4

=item * C<ignore> (default)

The unknown field will be ignored and a warning will be emitted that this field does not exist in the given database table.

=item * C<fatal> or C<die>

This will trigger a L</die> using a L<Module::Generic::Exception> object. So you could catch it like this:

    use Nice::Try;
    
    try
    {
        # $opts contains the property 'unknown_field' set to 'die'
        my $dbh = DB::Object::Postgres->connect( $opts ) || die( "Unable to connect" );
        my $tbl = $dbh->some_table || die( "Unable to get the database table \"some_table\": ", $dbh->error );
        $tbl->where( $dbh->AND(
            $tbl->fo->faulty_field == '?',
            $tbl->fo->status == 'live',
        ) );
        my $ref = $tbl->select->fetchrow_hashref;
    }
    catch( $e isa( 'Module::Generic::Exception' ) )
    {
        die( "Caught error preparing SQL: $e" );
    }
    else
    {
        die( "Caught some other error." );
    }

=item * C<code reference>

When the option C<unknown_field> is set to a code reference, this will be executed and passed an hash reference that will contain 3 properties:

=over 8

=item 1. C<table>

The L<table object|DB::Object::Tables>

=item 2. C<field>

A regular string containing the unknown field name

=item 3. C<error>

The L<error object|Module::Generic::Exception>, which includes the error string and a stack trace

=back

=back

By default, the unknown field will be ignored.

=head1 CONSTRUCTOR

=head2 new

Creates a new L<DB::Object::Fields> objects. It may also take an hash like arguments, that also are method of the same name.

=over 4

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=head2 database_object

The database object, which is a L<DB::Object> object or one of its descendant.

=head2 prefixed

This si the prefix level, from 0 to 2.

2 or higher including the database, higher than 1 includes the schema name and above 0 includes the table name. 0 includes nothing.

When this value is changed, it is propagated to all the fields objects.

=head2 query_object

The query object, which is a L<DB::Object::Query> object or one of its descendant.

=head2 table_object

The query object, which is a L<DB::Object::Tables> object or one of its descendant.

=head2 _initiate_field_object

This method is called from C<AUTOLOAD>

Provided with a table column name and this will create a new L<DB::Object::Fields::Field> object and add dynamically the associated method for this column in the current package so that next time, it returns the cached object without using C<AUTOLOAD>

=head1 AUTOLOAD

Called with a column name and this will check if the given column name actually exists in this table. If it does, it will call L</_initiate_field_object> to instantiate a new field object and returns it.

If the column does not exist, it returns an error.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
