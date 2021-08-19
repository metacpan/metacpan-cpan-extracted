# -*- perl -*-
##----------------------------------------------------------------------------
# Database Object Interface - ~/lib/DB/Object/Tables.pm
# Version 0.4.1
# Copyright(c) 2020 DEGUEST Pte. Ltd.
# Author: Jacques Deguest <jack@deguest.jp>
# Created 2017/07/19
# Modified 2020/01/19
# All rights reserved
# 
# This program is free software; you can redistribute  it  and/or  modify  it
# under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This package's purpose is to separate the object of the tables from the main
# DB::Object package so that when they get DESTROY'ed, it does not interrupt
# the SQL connection
##----------------------------------------------------------------------------
package DB::Object::Tables;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object );
    use DB::Object::Fields;
    our( $VERSION, $VERBOSE, $DEBUG );
    $VERSION    = '0.4.1';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
    use Want;
};

sub init
{
    my $self  = shift( @_ );
    my $table = '';
    $table    = shift( @_ ) if( @_ && @_ % 2 );
    my %arg   = ( @_ );
    return( $self->error( "You must provide a table name to create a table object." ) ) if( !$table && !$arg{table} );
    $table ||= CORE::delete( $arg{table} );
    foreach my $k ( keys( %arg ) )
    {
        $self->{ $k } = $arg{ $k };
    }
    $self->{avoid}       = [];
    $self->{alias}       = {};
    $self->{bind}        = '';
    $self->{cache}       = '';
    $self->{default}   ||= {};
    $self->{enhance}     = '';
    $self->{fields}    ||= {};
    $self->{null}      ||= {};
    # The schema name, if any
    $self->{schema}      = '';
    $self->{structure} ||= {};
    $self->{table}       = $table if( $table );
    $self->{types}       = {};
    # The table type. It could be table or view
    $self->{type}        = '';
    # Load table default, fields, structure informations
    # my $db = $self->database();
    my $ref = $self->structure();
    return( $self->error( "There is no table by the name of $table" ) ) if( !%$ref );
    return( $self );
}

sub alter
{
    my $self  = shift( @_ );
    # Expecting a reference to an array
    my $spec  = '';
    $spec     = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    $spec     = [ @_ ] if( @_ && !$spec );
    my $table = $self->{table} ||
    return( $self->error( "No table was provided." ) );
    return( $self->error( "No proper ALTER specification was provided." ) ) if( !$spec || !ref( $spec ) || !@$spec );
    my $query = "ALTER TABLE $table " . CORE::join( ', ', @$spec );
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing ALTER query to modify table '$table':\n", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to ALTER table '$table':\n", $self->as_string(), $sth->errstr() ) );
    }
    return( $sth );
}

sub as
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    if( @_ )
    {
        my( $p, $f, $l ) = caller;
        $self->message( 3, "Setting table alias to '", $_[0], "'. Called from package $p in file $f at line $l" );
        $self->prefixed( length( $_[0] ) > 0 ? 1 : 0 );
    }
    return( $q->table_alias( @_ ) );
}

sub constant
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller;
    # $self->message( 3, "Called from package '$pack' in file '$file' at line '$line'." );
    my $base_class = $self->database_object->base_class;
    # This does not work for calls made internally
    return( $self ) if( $pack =~ /^${base_class}\b/ );
    my $sth = $self->database_object->constant_queries_cache_get({
        pack => $pack,
        file => $file,
        line => $line,
    });
    # $self->message( 3, "Statement handler returned is: '$sth'." );
    # $sth returned may be void if no cache was found or if the caller's file mod time has changed
    my $q;
    if( $sth )
    {
        $q = $sth->query_object;
        $self->query_object( $q );
    }
    else
    {
        $q = $self->_reset_query;
    }
    $q->constant({
        sth => $sth,
        pack => $pack,
        file => $file,
        line => $line,
    });
    return( $self );
}

# sub create must be superseded by sub classes
sub create
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "create() is not implemented by $class." ) );
}

sub create_info
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "create_info() is not implemented by $class." ) );
}

sub database { return( shift->database_object->database ); }

sub database_object { return( shift->{dbo} ); }

sub dbh { return( shift->_set_get( 'dbh', @_ ) ); }

sub default
{
    my $self = shift( @_ );
    $self->structure();
    my $default = $self->{default};
    return( wantarray() ? () : undef() ) if( !%$default );
    return( wantarray() ? %$default : \%$default );
}

sub drop
{
    my $self  = shift( @_ );
    my $table = $self->{table} || 
    return( $self->error( "No table was provided to drop." ) );
    my $query = "DROP TABLE $table";
    my $sth = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to drop table '$table':\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to drop table '$table':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub exists
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "exists() is not implemented by $class." ) );
}

sub fields
{
    my $self = shift( @_ );
    $self->structure();
    my $fields = $self->{fields};
    return( wantarray() ? () : undef() ) if( !%$fields );
    return( wantarray() ? %$fields : \%$fields );
}

sub fields_object
{
    my $self = shift( @_ );
    my $o = $self->{fields_object};
    $self->message( 3, "Do we already have a fields object? '$o'" );
    return( $o ) if( $o && $self->_is_object( $o ) );
    my $db_name = $self->database_object->database;
    $db_name =~ tr/-/_/;
    $db_name =~ s/\_{2,}/_/g;
    $db_name = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $db_name ) ) );
    my $name = $self->name;
    my $new_class = $name;
    $new_class =~ tr/-/_/;
    $new_class =~ s/\_{2,}/_/g;
    $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
    $class = ref( $self ) . "\::${db_name}\::${new_class}";
    $self->message( 3, "Creating and loading class '$class'" );
    unless( $self->_is_class_loaded( $class ) )
    {
        my $perl = <<EOT;
package $class;
BEGIN
{
    use strict;
    use parent qw( DB::Object::Fields );
};

1;

EOT
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
        $self->message( 3, "Evaluating\n$perl" );
        my $rc = eval( $perl );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
        die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    $self->message( 3, "Getting a new fields object for class '$class'." );
    $o = $class->new({
        table_object => $self,
        # For table alias
        query_object => $self->query_object,
        debug => $self->debug,
    });
    $o->prefixed( $self->{prefixed} );
    $self->{fields_object} = $o;
    $self->message( 3, "Returning newly created fields object '$o' that has debug value '", $o->debug, "'." );
    return( $o );
}

sub fo { return( shift->fields_object( @_ ) ); }

sub lock
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "lock() is not implemented by $class." ) );
}

sub name
{
    # Read-only
    return( shift->{table} );
}

sub null
{
    my $self = shift( @_ );
    $self->structure();
    my $null = $self->{null};
    return( wantarray() ? () : undef() ) if( !%$null );
    return( wantarray() ? %$null : $null );
}

sub optimize
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "optimize() is not implemented by $class." ) );
}

sub prefix
{
    my $self = shift( @_ );
    my @val = ();
    CORE::push( @val, $self->database_object->database ) if( $self->{prefixed} > 2 );
    CORE::push( @val, $self->schema ) if( $self->{prefixed} > 1 && $self->schema );
    CORE::push( @val, $self->name ) if( $self->{prefixed} > 0 );
    return( '' ) if( !scalar( @val ) );
    return( CORE::join( '.', @val ) );
}

sub prefix_database { return( shift->{prefixed} > 2 ); }

sub prefix_schema { return( shift->{prefixed} > 1 ); }

sub prefix_table { return( shift->{prefixed} > 0 ); }

# This the prefix intended for field in query
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
    my $fo = $self->{fields_object};
    $fo->prefixed( $self->{prefixed} ) if( $fo );
    return( want( 'OBJECT' ) ? $self : $self->{prefixed} );
}

sub primary
{
    my $self = shift( @_ );
    $self->structure();
    my $primary = $self->{primary};
    return( wantarray() ? () : undef() ) if( !$primary || !@$primary );
    return( wantarray() ? @$primary : \@$primary );
}

# In PostgreSQL, Oracle, SQL server this would be schema_name.table_name
sub qualified_name { return( shift->name ); }

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::Query', @_ ) ); }

sub query_reset { return( shift->_set_get_scalar( 'query_reset', @_ ) ); }

sub rename
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "rename() is not implemented by $class." ) );
}

sub repair
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "repair() is not implemented by $class." ) );
}

sub schema { return( shift->_set_get_scalar( 'schema', @_ ) ); }

sub stat
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "stat() is not implemented by $class." ) );
}

sub table { return( shift->{table} ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub types
{
    my $self = shift( @_ );
    $self->structure();
    my $types = $self->{types};
    return( wantarray() ? () : undef() ) if( !%$types );
    return( wantarray() ? %$types : $types );
}

# sub structure must be superseded by sub classes
sub structure
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "structure() is not implemented by $class." ) );
}

sub unlock
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "unlock() is not implemented by $class." ) );
}

DESTROY
{
    # Do nothing
    # DB::Object::Tables are never destroyed.
    # They are just gateway to tables, and they are cached by DB::Object::table()
    # print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

__END__

=encoding utf8

=head1 NAME

DB::Object::Tables - Database Table Object

=head1 SYNOPSIS

=head1 VERSION

    0.4.1

=head1 DESCRIPTION

This is the table object package used to represent and manipulate table objects.

=head1 CONSTRUCTOR

=head2 new

    my $tbl = DB::Object::Tables->new( 'my_table' ) || die( DB::Object::Tables->error );

Creates a new L<DB::Object::Tables> object.

A table name may be provided as first argument.

It may also take an hash of arguments, that also are method of the same name.

It will call L</structure> to get the table structure from database and returns an error if it fails.

Possible arguments are:

=over 4

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=head2 alter

Provided with an array or array reference of specification for the alter and this will prepare the proper query.

The specification array or array reference will be joined with a comma

If called in void context, the resulting statement handler will be executed immediately.

This returns the resulting statement handler.

=head2 as

Provided with a table alias and this will call L<DB::Object::Query/table_alias> passing it whatever arguments were provided.

=head2 constant

Sets the query object constant for statement caching and return our current object.

=head2 create

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/create>, L<DB::Object::Postgres::Tables/create> or L<DB::Object::SQLite::Tables/create>

=head2 create_info

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/create_info>, L<DB::Object::Postgres::Tables/create_info> or L<DB::Object::SQLite::Tables/create_info>

=head2 database

Returns the name of the current database by calling L<DB::Object/database>

=head2 database_object

Returns the database object (L<DB::Object>)

=head2 dbh

Returns the database handler (L<DBI>)

=head2 default

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to its default values pairs.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 drop

This will prepare the query to drop the current table.

In void context, this will execute the resulting statement handler.

It returns the resulting statement handler

=head2 exists

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/exists>, L<DB::Object::Postgres::Tables/exists> or L<DB::Object::SQLite::Tables/exists>

=head2 fields

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to its order (integer) in the table pairs.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 fields_object

    my $tbl = $dbh->user || die( "No table \"user\" found in database\n" );
    # get the field object for "name"
    my $name = $tbl->fields_object->name
    # Do something with it
    my $expr = $name == 'joe';
    # Resulting in an DB::Object::Fields::Field::Overloaded object

This returns the cached object if there is one.

This will dynamically create a package based on the database and table name. For example a database C<Foo> and a table C<Bar> would result in the following dynamically created package: C<DB::Object::Tables::Foo::Bar>

This new package will inherit from L<DB::Object::Fields>, which enable the dynamic loading of column object using C<AUTOLOAD>

This will instantiate an object from this newly created package, cache it and return it.

=head2 fo

This is a convenient shortcut for L</fields_object>

    my $tbl = $dbh->user || die( "No table \"user\" found in database\n" );
    # get the field object for "name"
    my $name = $tbl->fo->name

=head2 lock

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/lock>, L<DB::Object::Postgres::Tables/lock> or L<DB::Object::SQLite::Tables/lock>

=head2 name

Returns the table name. This is read-only.

=head2 null

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to its default null values pairs.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 optimize

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/optimize>, L<DB::Object::Postgres::Tables/optimize> or L<DB::Object::SQLite::Tables/optimize>

=head2 prefix

Based on the prefix level, this will return a string with the database name if prefix is higher than 2, with the schema if the prefix level is higher than 1 and with the table name if the prefix level is higher than 0.

The resulting string is used as prefix to table columns when preparing queries.

=head2 prefix_database

Returns true if L</prefixed> is higher than 2.

=head2 prefix_schema

Returns true if L</prefixed> is higher than 1.

=head2 prefix_table

Returns true if L</prefixed> is higher than 0.

=head2 prefixed

Sets or gets the prefix level. 0 being no prefix and 2 implying the use of the database name in prefix.

=head2 primary

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to primary keys pairs. If a column has no primary keys, its value would be empty.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 qualified_name

Returns the table name. This is read-only.

=head2 query_object

Returns the query object (L<DB::Object::Query>)

=head2 query_reset

Reset the query object (L<DB::Object::Query>)

=head2 rename

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/rename>, L<DB::Object::Postgres::Tables/rename> or L<DB::Object::SQLite::Tables/rename>

=head2 repair

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/repair>, L<DB::Object::Postgres::Tables/repair> or L<DB::Object::SQLite::Tables/repair>

=head2 schema

Returns the schema name, if any. For example, with PostgreSQL, the default schema name would be C<public>.

=head2 stat

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/stat>, L<DB::Object::Postgres::Tables/stat> or L<DB::Object::SQLite::Tables/stat>

=head2 table

Returns the table name. This is read-only.

=head2 type

The table type

=head2 types

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to data type.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 structure

The implementation is driver specific.

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/structure>, L<DB::Object::Postgres::Tables/structure> or L<DB::Object::SQLite::Tables/structure>

=head2 unlock

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/unlock>, L<DB::Object::Postgres::Tables/unlock> or L<DB::Object::SQLite::Tables/unlock>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
