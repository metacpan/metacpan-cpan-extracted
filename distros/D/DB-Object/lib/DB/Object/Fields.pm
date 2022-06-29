##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields.pm
## Version v1.0.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2021/03/21
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
    use DB::Object::Fields::Field;
    use parent qw( Module::Generic );
    use Devel::Confess;
    our( $VERSION ) = 'v1.0.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{prefixed} = 0;
    $self->{query_object} = '';
    $self->{table_object} = '';
    ## $self->{fatal} = 1;
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
    $self->message( 3, "Instantiating table '", $self->table_object->name, "' field '$field' object using class '$class', prefixed '$self->{prefixed}', query_object '", $self->query_object, "' and table_object '", $self->table_object, "' with table alias '", $self->query_object->table_alias, "'." );
    my $fields = $self->table_object->fields;
    $self->message( 3, "Table ", $self->table_object->name, " has no such field \"$field\"." ) if( !CORE::exists( $fields->{ $field } ) );
    return( $self->error( "Table ", $self->table_object->name, " has no such field \"$field\"." ) ) if( !CORE::exists( $fields->{ $field } ) );
    # $self->message( 3, "Evaluating -> package ${class}; sub ${field} { return( shift->_set_get_object( '$field', 'DB::Object::Fields::Field', \@_ ) ); }" );
    # eval( "package ${class}; sub ${field} { return( shift->_set_get_object( '$field', 'DB::Object::Fields::Field', \@_ ) ); }" );
    my $def   = $self->table_object->default;
    my $types = $self->table_object->types;
    my $const = $self->table_object->types_const;
    my $hash  =
    {
    debug        => ( $self->debug || 0 ),
    name         => $field,
    type         => $types->{ $field },
    default      => $def->{ $field },
    pos          => $fields->{ $field },
    const        => $const->{ $field },
    prefixed     => $self->{prefixed},
    query_object => $self->query_object,
    table_object => $self->table_object,
    };
    my $perl = <<EOT;
package ${class};
sub ${field}
{
    my \$self = shift( \@_ );
    \$self->message( 3, "Does class '$class' already have a '$field' object? ", ( \$self->{$field} ? 'yes' : 'no' ) );
    unless( \$self->{$field} )
    {
        \$self->{$field} = DB::Object::Fields::Field->new(
            debug => ( \$self->debug || 0 ),
            name => '$field',
            type => '$hash->{type}',
            default => '$hash->{default}',
            pos => $hash->{pos},
            constant => { constant => $hash->{const}->{constant}, name => '$hash->{const}->{name}', type => '$hash->{const}->{type}' },
            prefixed => \$self->{prefixed},
            query_object => \$self->query_object,
            table_object => \$self->table_object,
        );
    }
    \$self->message( 3, "Returning field object '\$self->{$field}'" );
    return( \$self->{$field} );
}
EOT
    # $self->message( 3, "Evaluating -> $perl" );
    eval( $perl );
    die( $@ ) if( $@ );
    # my $o = DB::Object::Fields::Field->new( $hash );
    my $o = $self->$field;
    # $self->message( 3, "Calling $self->$field( $o )" );
    # $self->$field( $o ) || return( $self->error( "Unable to set field '$field' object to '$o': ", $self->error ) );
    # $self->message( 3, "$self->$field returns '", overload::StrVal( $self->$field ), "'." );
    $self->message( 3, "Returning field object '$o' (", overload::StrVal( $o ), ")" );
    return( $o );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $fields = $self->table_object->fields;
    # $self->debug(3);
    $self->message( 3, "Called for method '$method'. Fields for table '", $self->table_object->name, "' are: ", sub{ $self->dump( $fields ) } );
    if( $code = $self->can( $method ) )
    {
        $self->message( 3, "Method \"$method\" already exists in class '", ( ref( $self ) || $self ), "' ($self)." );
        return( $code->( $self, @_ ) );
    }
    ## elsif( CORE::exists( $self->{ $method } ) )
    elsif( exists( $fields->{ $method } ) )
    {
        $self->message( 3, "Instantiating object for field '$method'." );
        return( $self->_initiate_field_object( $method ) );
    }
    else
    {
        warn( "Table ", $self->table_object->name, " has no such field \"$method\".\n" );
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

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

The purpose of this module is to enable access to the table fields as L<DB::Object::Fields::Field> objects.

The way this works is by having L<DB::Object::Tables/fields_object> or L<DB::Object::Tables/fo> for short, dynamically create a class based on the database name and table name. For example if the database driver were C<PostgreSQL>, the database were C<my_shop> and the table C<customers>, the dynamically created package would become C<DB::Object::Postgres::Tables::MyShop::Customers>. This class would inherit from this package L<DB::Object::Fields>.

Field objects can than be dynamically instantiated by accessing them, such as (assuming the table object C<$tbl_object> here represent the table C<customers>) C<$tbl_object->fo->last_name>. This will return a L<DB::Object::Fields::Field> object.

A note on the design: there had to be a separate this separate package L<DB::Object::Fields>, because access to table fields is done through the C<AUTOLOAD> and the methods within the package L<DB::Object::Tables> and its inheriting packages would clash with the tables fields. This package has very few methods, so the risk of a sql table field clashing with a method name is very limited. In any case, if you have in your table a field with the same name as one of those methods here (see below for the list), then you can instantiate a field object with:

    $tbl_object->_initiate_field_object( 'last_name' );

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
