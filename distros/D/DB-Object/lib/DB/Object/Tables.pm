# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Tables.pm
## Version v0.5.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2022/11/04
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
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
    use vars qw( $VERSION $VERBOSE $DEBUG );
    use DB::Object::Fields;
    $VERSION    = 'v0.5.1';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
    use Want;
};

use strict;
use warnings;

sub init
{
    my $self  = shift( @_ );
    my $table = '';
    $table    = shift( @_ ) if( @_ && @_ % 2 );
    my %arg   = ( @_ );
    # Prioritise this, so we get debugging messages
    $self->{debug} = CORE::delete( $arg{delete} );
    return( $self->error( "You must provide a table name to create a table object." ) ) if( !$table && !$arg{table} );
    $table ||= CORE::delete( $arg{table} );
    $self->{avoid}          = [];
    $self->{alias}          = {};
#     $self->{bind}           = '';
#     $self->{cache}          = '';
    $self->{dbo}            = '';
    $self->{default}        = {};
    $self->{enhance}        = '';
    $self->{fields}         = {};
    # DB::Object::Fields
    $self->{fields_object}  = '';
    $self->{null}           = {};
    $self->{prefixed}       = 0;
    $self->{primary}        = [];
    $self->{query_object}   = '';
    $self->{query_reset}    = 0;
    $self->{reverse}        = 0;
    # The schema name, if any
    $self->{schema}         = '';
    $self->{structure}      = {};
    $self->{table}          = $table if( $table );
    $self->{types}          = {};
    # An hash to contain table field to an hash of constant value and constant name:
    # field => { constant => 12, name => PG_JSONB, type => 'jsonb' };
    $self->{types_const}    = {};
    # The table type. It could be table or view
    $self->{type}           = '';
    my $keys = [keys( %arg )];
    @$self{ @$keys } = @arg{ @$keys };
#     foreach my $k ( keys( %arg ) )
#     {
#         $self->{ $k } = $arg{ $k };
#     }
    # Load table default, fields, structure informations
    # my $db = $self->database();
    my $ref = $self->structure();
    return( $self->error( "There is no table by the name of $table" ) ) if( !defined( $ref ) || !%$ref );
    return( $self );
}

# Get/set alias
sub alias
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->alias( @_ ) );
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
        # my( $p, $f, $l ) = caller;
        $self->prefixed( length( $_[0] ) > 0 ? 1 : 0 );
    }
    return( $q->table_alias( @_ ) );
}

sub avoid
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->avoid( @_ ) );
}

sub constant
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller;
    my $base_class = $self->database_object->base_class;
    # This does not work for calls made internally
    return( $self ) if( $pack =~ /^${base_class}\b/ );
    my $sth = $self->database_object->constant_queries_cache_get({
        pack => $pack,
        file => $file,
        line => $line,
    });
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

sub delete
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    # If the user wants to execute this, then we reset the query, 
    # but if the user wants to call other methods chained like as_string we don't do anything
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    if( Want::want('VOID') || Want::want('OBJECT') )
    {
        CORE::delete( $self->{query_reset} ) if( Want::want('VOID') );
        # return( $q->select( @_ ) );
        # return( $q->select( @_ ) ) if( !defined( wantarray() ) );
        return( $q->delete( @_ ) );
    }
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    # return( $q->delete( @_ ) );
    # return( $q->delete( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
        my( @val ) = $q->delete( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( @val );
    }
    else
    {
        my $val = $q->delete( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( $val );
    }
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
    # This will make sure we have a query object which DB::Object::Fields and DB::Object::Field need
    $self->_reset_query;
    if( $o && $self->_is_object( $o ) )
    {
        $o->prefixed( $self->{prefixed} );
        $o->query_object( $self->query_object );
        return( $o );
    }
    my $db_name = $self->database_object->database;
    $db_name =~ tr/-/_/;
    $db_name =~ s/\_{2,}/_/g;
    $db_name = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $db_name ) ) );
    my $name = $self->name;
    my $new_class = $name;
    $new_class =~ tr/-/_/;
    $new_class =~ s/\_{2,}/_/g;
    $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
    my $class = ref( $self ) . "\::${db_name}\::${new_class}";
    if( !$self->_is_class_loaded( $class ) )
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
        my $rc = eval( $perl );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
        die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    else
    {
    }
    $o = $class->new(
        prefixed        => $self->{prefixed},
        # For table alias
        query_object    => $self->query_object,
        table_object    => $self,
        debug           => $self->debug,
    );
    $o->prefixed( $self->{prefixed} );
    $self->{fields_object} = $o;
    return( $o );
}

sub fo { return( shift->fields_object( @_ ) ); }

sub format_statement($;\%\%@)
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->format_statement( @_ ) );
}

sub format_update($;%)
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->format_update( @_ ) );
}

sub from_unixtime
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->from_unixtime( @_ ) );
}

sub group
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->group( @_ ) );
}

sub insert
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    # If the user wants to execute this, then we reset the query, 
    # but if the user wants to call other methods chained like as_string we don't do anything
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    if( Want::want('VOID') || Want::want('OBJECT') )
    {
        CORE::delete( $self->{query_reset} ) if( Want::want('VOID') );
        # return( $q->select( @_ ) );
        # return( $q->select( @_ ) ) if( !defined( wantarray() ) );
        return( $q->insert( @_ ) );
    }
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    # return( $q->insert( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
        my( @val ) = $q->insert( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( @val );
    }
    else
    {
        my $val = $q->insert( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( $val );
    }
}

sub limit
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->limit( @_ ) );
}

sub local
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->local( @_ ) );
}

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

sub on_conflict { return( shift->error( "The on conflict clause is not supported by this driver." ) ); }

sub optimize
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "optimize() is not implemented by $class." ) );
}

sub order
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->order( @_ ) );
}

sub prefix
{
    my $self = shift( @_ );
    my @val = ();
    my $alias = $self->query_object->table_alias;
    #my $q = $self->query_object || die( "No query object could be created or gotten: ", $self->error );
    #my $alias = $q->table_alias;
    return( $alias ) if( $alias && $self->{prefixed} > 0 );
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
    # return( want( 'OBJECT' ) ? $self : $self->{prefixed} );
    return( $self->{prefixed} );
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

sub query_object { return( shift->_set_get_object_without_init( 'query_object', 'DB::Object::Query', @_ ) ); }

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

sub replace
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    # If the user wants to execute this, then we reset the query, 
    # but if the user wants to call other methods chained like as_string we don't do anything
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    if( Want::want('VOID') || Want::want('OBJECT') )
    {
        CORE::delete( $self->{query_reset} ) if( Want::want('VOID') );
        # return( $q->select( @_ ) );
        # return( $q->select( @_ ) ) if( !defined( wantarray() ) );
        return( $q->replace( @_ ) );
    }
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    # return( $q->replace( @_ ) );
    # return( $q->replace( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
        my( @val ) = $q->replace( @_ ) || return( $self->pass_error( $q->error ) );
        return( @val );
    }
    else
    {
        my $val = $q->replace( @_ ) || return( $self->pass_error( $q->error ) );
        return( $val );
    }
}

sub reset 
{
    my $self = shift( @_ );
    CORE::delete( $self->{query_reset} );
    $self->_reset_query( @_ ) || return( $self->pass_error );
    CORE::delete( $self->{fields_object} );
    ## To allow chaining of commands
    return( $self );
}

# Modelled after PostgreSQL and available since 3.35.0 released 2021-03-12
# <https://www.sqlite.org/lang_returning.html>
sub returning
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->returning( @_ ) );
}

sub reverse
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $q = $self->_reset_query;
        $self->{reverse}++;
        $q->reverse( $self->{reverse} );
    }
    return( $self->{reverse} );
}

sub schema { return( shift->_set_get_scalar( 'schema', @_ ) ); }

sub select
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    # If the user wants to execute this, then we reset the query, 
    # but if the user wants to call other methods chained like as_string we don't do anything
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    if( Want::want('VOID') || Want::want('OBJECT') )
    {
        CORE::delete( $self->{query_reset} ) if( Want::want('VOID') );
        # return( $q->select( @_ ) );
        # return( $q->select( @_ ) ) if( !defined( wantarray() ) );
        return( $q->select( @_ ) );
    }
    
    if( wantarray() )
    {
        my( @val ) = $q->select( @_ ) || return( $self->pass_error( $q->error ) );
        # a statement handler is returned and we reset the query so that other calls would not use the previous DB::Object::Query object
        $self->reset;
        return( @val );
    }
    else
    {
        my $val = $q->select( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( $val );
    }
}

sub sort
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $q = $self->_reset_query;
        $self->{reverse} = 0;
        $q->sort( $self->{reverse} );
    }
    return( $self->{reverse} );
}

sub stat
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "stat() is not implemented by $class." ) );
}

# sub structure must be superseded by sub classes
sub structure
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "structure() is not implemented by $class." ) );
}

sub table { return( shift->{table} ); }

sub tie
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->tie( @_ ) );
}

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub types
{
    my $self = shift( @_ );
    $self->structure();
    my $types = $self->{types};
    return( wantarray() ? () : undef() ) if( !%$types );
    return( wantarray() ? %$types : $types );
}

sub types_const
{
    my $self = shift( @_ );
    $self->structure();
    my $types = $self->{types_const};
    return( wantarray() ? () : undef() ) if( !%$types );
    return( wantarray() ? %$types : $types );
}

sub unlock
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "unlock() is not implemented by $class." ) );
}

sub unix_timestamp
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->unix_timestamp( @_ ) );
}

sub update
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    # If the user wants to execute this, then we reset the query, 
    # but if the user wants to call other methods chained like as_string we don't do anything
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    if( Want::want('VOID') || Want::want('OBJECT') )
    {
        CORE::delete( $self->{query_reset} ) if( Want::want('VOID') );
        # return( $q->select( @_ ) );
        # return( $q->select( @_ ) ) if( !defined( wantarray() ) );
        return( $q->update( @_ ) );
    }
    # CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    # return( $q->update( @_ ) );
    # return( $q->update( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
        my( @val ) = $q->update( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( @val );
    }
    else
    {
        my $val = $q->update( @_ ) || return( $self->pass_error( $q->error ) );
        $self->reset;
        return( $val );
    }
}

sub where
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->where( @_ ) );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $fields = $self->fields;
    # User called a field on a table object, instead of using the method fields_object or its shortcut 'fo'
    if( CORE::exists( $fields->{ $method } ) )
    {
        warn( "You have called a field name '$method' using a table object. This practice is discouraged, although it works for now. Best to use something like: \$tbl->fo->$method rather than just \$tbl->$method\n" );
        return( $self->fields_object->_initiate_field_object( $method ) );
    }
    else
    {
        warn( "You called table '", $self->name, "' object \$tbl->$method, but no such method exist.\n" );
        return( $self->error( "You called table '", $self->name, "' object \$tbl->$method, but no such method exist." ) );
    }
};

DESTROY
{
    # Do nothing
    # DB::Object::Tables are never destroyed.
    # They are just gateway to tables, and they are cached by DB::Object::table()
    # print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DB::Object::Tables - Database Table Object

=head1 SYNOPSIS

=head1 VERSION

    v0.5.1

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

=head2 alias

This is a convenient wrapper around L<DB::Object::Query/alias>

It takes a column name to alias hash and sets those aliases for the following query.

Get/set alias for table fields in SELECT queries. The hash provided thus contain a list of field => alias pairs.

=head2 alter

Provided with an array or array reference of specification for the alter and this will prepare the proper query.

The specification array or array reference will be joined with a comma

If called in void context, the resulting statement handler will be executed immediately.

This returns the resulting statement handler.

=head2 as

Provided with a table alias and this will call L<DB::Object::Query/table_alias> passing it whatever arguments were provided.

=head2 avoid

Takes a list of array reference of column to avoid in the next query.

This is a convenient wrapper around L<DB::Object::Query/avoid>

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

=head2 delete

L</delete> will format a delete query based on previously set parameters, such as L</where>.

L</delete> will refuse to execute a query without a where condition. To achieve this, one must prepare the delete query on his/her own by using the L</do> method and passing the sql query directly.

    $tbl->where( login => 'jack' );
    $tbl->limit(1);
    my $rows_affected = $tbl->delete();
    # or passing the where condition directly to delete
    my $sth = $tbl->delete( login => 'jack' );

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

=head2 format_statement

This is a convenient wrapper around L<DB::Object::Query/format_statement>

Format the sql statement for queries of types C<select>, C<delete> and C<insert>

In list context, it returns 2 strings: one comma-separated list of fields and one comma-separated list of values. In scalar context, it only returns a comma-separated string of fields.

=head2 format_update

This is a convenient wrapper around L<DB::Object::Query/format_update>

Formats update query based on the following arguments provided:

=over 4

=item I<data>

An array of key-value pairs to be used in the update query. This array can be provided as the prime argument as a reference to an array, an array, or as the I<data> element of a hash or a reference to a hash provided.

Why an array if eventually we build a list of key-value pair? Because the order of the fields may be important, and if the key-value pair list is provided, L</format_update> honors the order in which the fields are provided.

=back

L</format_update> will then iterate through each field-value pair, and perform some work:

If the field being reviewed was provided to B<from_unixtime>, then L</format_update> will enclose it in the function FROM_UNIXTIME() as in:

    FROM_UNIXTIME(field_name)
  
If the the given value is a reference to a scalar, it will be used as-is, ie. it will not be enclosed in quotes or anything. This is useful if you want to control which function to use around that field.

If the given value is another field or looks like a function having parenthesis, or if the value is a question mark, the value will be used as-is.

If L<DB::Object/bind> is off, the value will be escaped and the pair field='value' created.

If the field is a SET data type and the value is a number, the value will be used as-is without surrounding single quote.

If L<DB::Object/bind> is enabled, a question mark will be used as the value and the original value will be saved as value to bind upon executing the query.

Finally, otherwise the value is escaped and surrounded by single quotes.

L</format_update> returns a string representing the comma-separated list of fields that will be used.

=head2 from_unixtime

Provided with an array or array reference of table columns and this will set the list of fields that are to be treated as unix time and converted accordingly after the sql query is executed.

It returns the list of fields in list context or a reference to an array in scalar context.

=head2 group

This is a convenient wrapper around L<DB::Object::Query/group>

=head2 insert

This is a convenient wrapper around L<DB::Object::Query/insert>

=head2 limit

This is a convenient wrapper around L<DB::Object::Query/limit>

=head2 local

This is a convenient wrapper around L<DB::Object::Query/local>

=head2 lock

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/lock>, L<DB::Object::Postgres::Tables/lock> or L<DB::Object::SQLite::Tables/lock>

=head2 name

Returns the table name. This is read-only.

=head2 null

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to its default null values pairs.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 on_conflict

The SQL C<ON CONFLICT> clause needs to be implemented by the driver and is currently supported only by L<DB::Object::Postgres> and L<DB::Object::SQLite>.

=head2 optimize

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/optimize>, L<DB::Object::Postgres::Tables/optimize> or L<DB::Object::SQLite::Tables/optimize>

=head2 order

This is a convenient wrapper around L<DB::Object::Query/order>

Prepares the C<ORDER BY> clause and returns the value of the clause in list context or the C<ORDER BY> clause in full in scalar context, ie. "ORDER BY $clause"

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

=head2 replace

Just like for the C<INSERT> query, L</replace> takes one optional argument representing a L<DB::Object::Statement> C<SELECT> object or a list of field-value pairs.

If a C<SELECT> statement is provided, it will be used to construct a query of the type of C<REPLACE INTO mytable SELECT FROM other_table>

Otherwise the query will be C<REPLACE INTO mytable (fields) VALUES(values)>

In scalar context, it execute the query and in list context it simply returns the statement handler.

=head2 reset

This is used to reset a prepared query to its default values. If a field is a date/time type, its default value will be set to NOW()

It execute an update with the reseted value and return the number of affected rows.

=head2 returning

The SQL C<RETURNING> clause needs to be implemented by the driver and is currently supported only by and L<DB::Object::Postgres> (see L<DB::Object::Postgres::Query/returning>) and L<DB::Object::SQLite> (see L<DB::Object::SQLite::Query/returning>).

=head2 reverse

Get or set the reverse mode.

=head2 schema

Returns the schema name, if any. For example, with PostgreSQL, the default schema name would be C<public>.

=head2 select

Given an optional list of fields to fetch, L</select> prepares a C<SELECT> query.

If no field was provided, L</select> will use default value where appropriate like the C<NOW()> for date/time fields.

L<DB::Object::Query/select> calls upon L<DB::Object::Query/tie>, L<DB::Object::Query/where>, L<DB::Object::Query/group>, L<DB::Object::Query/order>, L<DB::Object::Query/limit>, L<DB::Object::Query/local>, and possibly more depending on the driver implementation, to build the query.

In scalar context, it execute the query and return it. In list context, it just returns the statement handler.

=head2 sort

It toggles sort mode on and consequently disable reverse mode.

=head2 stat

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/stat>, L<DB::Object::Postgres::Tables/stat> or L<DB::Object::SQLite::Tables/stat>

=head2 table

Returns the table name. This is read-only.

=head2 tie

This is a convenient wrapper around L<DB::Object::Query/tie>

=head2 type

The table type

=head2 types

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to data type.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 types_const

This calls L</structure> which may return cached data.

Returns an hash in list context and an hash reference in scalar representing column to hash that defines the driver constant for this data type:

    some_column => { constant => 17, name => 'PG_JSONB', type => 'jsonb' }

This is used to help manage binded value with the right type, or helps when converting an hash into json.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

=head2 structure

The implementation is driver specific.

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/structure>, L<DB::Object::Postgres::Tables/structure> or L<DB::Object::SQLite::Tables/structure>

=head2 unix_timestamp

This is a convenient wrapper around L<DB::Object::Query/unix_timestamp>

=head2 unlock

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/unlock>, L<DB::Object::Postgres::Tables/unlock> or L<DB::Object::SQLite::Tables/unlock>

=head2 update

Given a list of field-value pairs, L</update> prepares a sql update query.

It calls upon L<DB::Object::Query/where> and L<DB::Object::Query/limit> as previously set.

It returns undef and sets an error if it failed to prepare the update statement. In scalar context, it execute the query. In list context, it simply return the statement handler.

=head2 where

This is a convenient wrapper around L<DB::Object::Query/where>

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
