# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Tables.pm
## Version v1.0.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2023/11/17
## All rights reserved
## 
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
    use vars qw( $VERSION $DEBUG );
    use DB::Object::Fields;
    use Devel::Confess;
    use Want;
    our $DEBUG = 0;
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

sub new { return( shift->Module::Generic::new( @_ ) ); }

sub init
{
    my $self = shift( @_ );
    my $table;
    my @test_args;
    if( @_ &&
        (
            # $self->init( $table_name )
            (
                @_ == 1 && 
                defined( $_[0] ) &&
                (
                    !ref( $_[0] ) || 
                    $self->_can_overload( $_[0] => '""' )
                )
            ) ||
            # $self->init( $table_name, $opts_hash_ref );
            (
                @_ == 2 &&
                defined( $_[0] ) &&
                defined( $_[1] ) &&
                (
                    !ref( $_[0] ) || 
                    $self->_can_overload( $_[0] => '""' )
                ) &&
                ref( $_[1] ) eq 'HASH'
            ) ||
            # $self->init( $table_name, opt11 => val1, opt2 => val2 );
            (
                @_ > 2 && 
                defined( $_[0] ) &&
                (
                    !ref( $_[0] ) || $self->_can_overload( $_[0] => '""' )
                ) &&
                ( @test_args = @_[1..$#_] ) &&
                !( @test_args % 2 )
            )
        ) )
    {
        $table = shift( @_ );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    unless( defined( $table ) )
    {
        if( !CORE::exists( $opts->{table} ) || !CORE::length( $opts->{table} // '' ) )
        {
            return( $self->error( "You must provide a table name to create a table object." ) );
        }
        else
        {
            $table = CORE::delete( $opts->{table} );
        }
    }
    $self->{check}          = {};
    $self->{dbo}            = undef;
    # $self->{default}        = {};
    # Containing all the table field objects
    $self->{fields}         = {};
    # DB::Object::Fields
    $self->{fields_object}  = undef;
    $self->{foreign}        = {};
    $self->{indexes}        = {};
    # $self->{null}           = {};
    $self->{prefixed}       = 0;
    $self->{primary}        = [];
    $self->{query_object}   = undef;
    $self->{query_reset}    = 0;
    $self->{reverse}        = 0;
    # The schema name, if any
    $self->{schema}         = undef;
    $self->{structure}      = {};
    $self->{table_alias}    = undef;
    # $self->{types}          = {};
    # An hash to contain table field to an hash of constant value and constant name:
    # field => { constant => 12, name => PG_JSONB, type => 'jsonb' };
    $self->{types_const}    = {};
    # The table type. It could be table or view
    $self->{type}           = undef;
    $self->{_init_params_order} = [qw( dbo query_object )];
    $self->{_init_strict_use_sub} = 1;
    $self->Module::Generic::init( %$opts ) || return( $self->pass_error );
    $self->dbo( $opts->{dbo} );
    $self->{table} = $table;
    $self->{_cache_structure} = '';
    # Load table default, fields, structure informations
    my $ref = $self->structure || return( $self->pass_error );
    # return( $self->error( "There is no table by the name of $table" ) ) if( !defined( $ref ) || !%$ref );
    return( $self );
}

# Get/set alias
sub alias { return( shift->_method_to_query( 'alias', @_ ) ); }

sub alter
{
    my $self  = shift( @_ );
    # Expecting a reference to an array
    my $spec;
    if( @_ == 1 && $self->_is_array( $_[0] ) )
    {
        $spec = shift( @_ );
    }
    elsif( @_ )
    {
        $spec = [@_];
    }
    my $table = $self->{table} ||
    return( $self->error( "No table was provided." ) );
    return( $self->error( "No proper ALTER specification was provided." ) ) if( !defined( $spec ) || !@$spec );
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
        $self->{table_alias} = $_[0];
        $self->prefixed( length( $_[0] ) > 0 ? 1 : 0 );
        $q->table_alias( $self->{table_alias} );
    }
    return( $self->{table_alias} );
}

sub avoid { return( shift->_method_to_query( 'avoid', @_ ) ); }

sub check { return( shift->_set_get_hash_as_mix_object( 'check', @_ ) ); }

sub columns
{
    my $self = shift( @_ );
    my $fields = $self->fields;
    # my $cols = [sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields )];
    my $cols = [sort{ $fields->{ $a }->pos <=> $fields->{ $b }->pos } keys( %$fields )];
    return( $self->new_array( $cols ) );
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

sub database_object { return( shift->_set_get_object_without_init( 'dbo', 'DB::Object', @_ ) ); }

sub dbh { return( shift->_set_get( 'dbh', @_ ) ); }

sub dbo { return( shift->_set_get_object_without_init( 'dbo', 'DB::Object', @_ ) ); }

sub default
{
    my $self = shift( @_ );
    $self->structure || return( $self->pass_error );
    my $fields = $self->{fields};
    my $default = +{ map{ defined( $fields->{ $_ }->default ) ? ( $_ => $fields->{ $_ }->default ) : () } keys( %$fields ) };
    return( $default );
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
        $sth->execute ||
            return( $self->error( "Error while executing query to drop table '$table':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub enhance { return( shift->_method_to_query( 'enhance', @_ ) ); }

sub exists
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "exists() is not implemented by $class." ) );
}

sub fields
{
    my $self = shift( @_ );
    $self->structure || return( $self->pass_error );
    my $fields = $self->{fields};
    if( @_ )
    {
        my $field = shift( @_ );
        my $obj = $fields->{ $field } || return( $self->error( "No field object found for \"${field}\"." ) );
        return( $obj->clone );
    }
    # return( +{ map{ $_ => $fields->{ $_ }->clone } keys( %$fields ) } );
    my $ref = {};
    foreach my $f ( keys( %$fields ) )
    {
        my $new = $fields->{ $f }->clone || return( $self->pass_error( $fields->{ $f }->error ) );
        $ref->{ $f } = $new;
    }
    return( $ref );
}

sub fields_as_array
{
    my $self = shift( @_ );
    $self->structure || return( $self->pass_error );
    my $fields = $self->{fields};
    return( $self->new_array( [sort{ $fields->{ $a }->pos <=> $fields->{ $b }->pos } keys( %$fields )] ) );
}

sub field_exists
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided." ) );
    $self->structure || return( $self->pass_error );
    my $fields = $self->{fields};
    return( CORE::exists( $fields->{ $field } ) );
}

sub fields_object
{
    my $self = shift( @_ );
    my $o = $self->{fields_object};
    # This will make sure we have a query object which DB::Object::Fields and DB::Object::Field need
    $self->_reset_query;
    my $qo = $self->query_object;
    $qo->table_object( $self );
    $self->messagec( 5, "Called for table {green}", $self->name, "{/} aliased to {green}", ( $self->as // 'undef' ), "{/}" );
    if( $o && $self->_is_object( $o ) )
    {
        $o->prefixed( $self->{prefixed} );
        $o->query_object( $qo );
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
        my $rc = eval( $perl );
        die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    else
    {
        # Class already exists
    }
    $o = $class->new(
        prefixed        => $self->{prefixed},
        # For table alias
        # query_object    => $self->query_object,
        # query_object    => $qo,
        table_object    => $self,
        debug           => $self->debug,
    );
    $o->prefixed( $self->{prefixed} );
    $self->messagec( 5, "Saving fields object whose table object has name {green}", $o->table_object->name, "{/} and alias {green}", $o->table_object->as, "{/}. Fields object has debug value '", $o->debug, "'" );
    $self->{fields_object} = $o;
    return( $o );
}

sub fo { return( shift->fields_object( @_ ) ); }

sub foreign { return( shift->_set_get_hash_as_mix_object( 'foreign', @_ ) ); }

sub format_statement($;\%\%@) { return( shift->_method_to_query( 'format_statement', @_ ) ); }

sub format_update($;%) { return( shift->_method_to_query( 'format_update', @_ ) ); }

sub from_unixtime { return( shift->_method_to_query( 'from_unixtime', @_ ) ); }

sub get_query_object { return( shift->_reset_query ); }

sub group { return( shift->_method_to_query( 'group', @_ ) ); }

# sub indexes { return( shift->_set_get_class_array_object( 'indexes', {
#     is_primary => { type => 'boolean' },
#     is_unique => { type => 'boolean' },
#     fields => { type => 'array_as_object' },
# }, @_ ) ); }
sub indexes { return( shift->_set_get_hash_as_mix_object( 'indexes', @_ ) ); }

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

sub limit { return( shift->_method_to_query( 'limit', @_ ) ); }

sub local { return( shift->_method_to_query( 'local', @_ ) ); }

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

sub new_check
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'DB::Object::Constraint::Check' ) ||
        return( $self->pass_error );
    $args->{debug} = $self->debug if( !CORE::exists( $args->{debug} ) || !defined( $args->{debug} ) );
    my $this = DB::Object::Constraint::Check->new( %$args ) ||
        return( $self->pass_error( DB::Object::Constraint::Check->error ) );
    return( $this );
}

sub new_foreign
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'DB::Object::Constraint::Foreign' ) ||
        return( $self->pass_error );
    $args->{debug} = $self->debug if( !CORE::exists( $args->{debug} ) || !defined( $args->{debug} ) );
    my $this = DB::Object::Constraint::Foreign->new( %$args ) ||
        return( $self->pass_error( DB::Object::Constraint::Foreign->error ) );
    return( $this );
}

sub new_index
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'DB::Object::Constraint::Index' ) ||
        return( $self->pass_error );
    $args->{debug} = $self->debug if( !CORE::exists( $args->{debug} ) || !defined( $args->{debug} ) );
    my $this = DB::Object::Constraint::Index->new( %$args ) ||
        return( $self->pass_error( DB::Object::Constraint::Index->error ) );
    return( $this );
}

sub no_bind { return( shift->_set_get_boolean( { field => 'no_bind', callbacks =>
{
    set => sub
    {
        my $self = shift( @_ );
        my $val = shift( @_ );
        return if( !$val );
        my $q = $self->_reset_query;
        my $where = $q->where();
        my $group = $q->group();
        my $order = $q->order();
        my $limit = $q->limit();
        my $binded_where = $q->binded_where;
        my $binded_group = $q->binded_group;
        my $binded_order = $q->binded_order;
        my $binded_limit = $q->binded_limit;
        # Replace the placeholders by their corresponding value
        # and have them re-processed by their corresponding method
        if( $where && @$binded_where )
        {
            $where =~ s/(=\s*\?)/"='" . quotemeta( $binded_where->[ $#+ ] ) . "'"/ge;
            $self->where( $where );
        }
        if( $group && @$binded_group )
        {
            $group =~ s/(=\s*\?)/"='" . quotemeta( $binded_group->[ $#+ ] ) . "'"/ge;
            $self->group( $group );
        }
        if( $order && @$binded_order )
        {
            $order =~ s/(=\s*\?)/"='" . quotemeta( $binded_order->[ $#+ ] ) . "'"/ge;
            $self->order( $order );
        }
        if( $limit && @$binded_limit )
        {
            # $limit =~ s/(=\s*\?)/"='" . quotemeta( $binded_limit[ $#+ ] ) . "'"/ge;
            $self->limit( @$binded_limit );
        }
        $q->reset_bind;
        return( $self );
    },
} }, @_ ) ); }

sub null
{
    my $self = shift( @_ );
    $self->structure || return( $self->pass_error );
    my $fields = $self->fields;
    # my $null = $self->{null};
    my $null = +{ map{ $_ => ( $fields->{ $_ }->is_nullable ? 1 : 0 ) } keys( %$fields ) };
    return( $self->_clone( $null ) );
}

sub on_conflict { return( shift->error( "The on conflict clause is not supported by this driver." ) ); }

sub optimize
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "optimize() is not implemented by $class." ) );
}

sub order { return( shift->_method_to_query( 'order', @_ ) ); }

sub parent { return( shift->error( "The table parent() method is not supported by this driver." ) ); }

sub prefix
{
    my $self = shift( @_ );
    my @val = ();
    my $alias = $self->query_object->table_alias;
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
    $self->structure || return( $self->pass_error );
    my $primary = $self->{primary};
    # return( wantarray() ? () : undef() ) if( !$primary || !@$primary );
    # return( wantarray() ? @$primary : \@$primary );
    return( $self->_clone( $primary ) );
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
    # To allow chaining of commands
    return( $self );
}

sub reset_structure
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset_structure} // '' ) && scalar( @_ ) )
    {
        $self->{_reset_structure} = scalar( @_ );
    }
    return( $self );
}

# Modelled after PostgreSQL and available since 3.35.0 released 2021-03-12
# <https://www.sqlite.org/lang_returning.html>
sub returning { return( shift->_method_to_query( 'returning', @_ ) ); }

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
        $self->messagec( 5, "Calling select() on query object for table {green}", $self->name, "{/} with alias {green}", $self->as, "{/}" );
        my $val = $q->select( @_ ) || return( $self->pass_error( $q->error ) );
        $self->messagec( 5, "select() on query object for table {green}", $self->name, "{/} with alias {green}", $self->as, "{/} returned {green}", $val, "{/}" );
        $self->reset;
        $self->messagec( 5, "Table {green}", $self->name, "{/} is {green}", $self->as, "{/}" );
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
    $self->structure || return( $self->pass_error );
    # my $types = $self->{types};
    my $fields = $self->fields;
    my $types = +{ map{ $_ => $fields->{ $_ }->type } keys( %$fields ) };
    # return( $self->_clone( $types ) );
    return( $types );
}

sub types_const
{
    my $self = shift( @_ );
    $self->structure || return( $self->pass_error );
    my $fields = $self->fields;
    # my $types = $self->{types_const};
    my $types = +{ map{ $_ => $fields->{ $_ }->datatype } keys( %$fields ) };
    # return( $self->_clone( $types ) );
    return( $types );
}

sub unlock
{
    my $self = shift( @_ );
    my $class = ref( $self );
    return( $self->error( "unlock() is not implemented by $class." ) );
}

sub unix_timestamp { return( shift->_method_to_query( 'unix_timestamp', @_ ) ); }

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

sub where { return( shift->_method_to_query( 'where', @_ ) ); }

sub _method_to_query
{
    my $self = shift( @_ );
    my $meth = shift( @_ );
    my $q = $self->_reset_query;
    my $code = $q->can( $meth ) || return( $self->error( "Query class '", ref( $q ), "' has no method '$meth'." ) );
    my $rv = $code->( $q, @_ );
    return( $self->pass_error( $q->error ) ) if( !defined( $rv ) && $q->error );
    return( $rv );
}

sub AUTOLOAD
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

sub DESTROY
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

    v1.0.0

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

=item * C<debug>

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

=head2 check

Sets or gets the L<hash object|Module::Generic::Hash> of L<check constraint objects|DB::Object::Constraint::Check> for this table.

Each key in the hash represents the foreign key constraint name and its value is an L<check constraint object|DB::Object::Constraint::Check> that contains the following methods:

=over 4

=item * C<expr>

The check constraint expression

=item * C<fields>

The L<array object|Module::Generic::Array> of table columns associated with this check constraint.

=item * C<name>

The check constraint name.

=back

=head2 columns

Returns an L<array object|Module::Generic::Array> of the table columns.

This information is provided by L</fields>, which is in turn provided by L</structure>

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

=head2 dbo

Sets or get the L<database object|DB::Object>, which can be one of L<DB::Object::Mysql>, L<DB::Object::Postgres> or L<DB::Object::SQLite>

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

=head2 enhance

Sets or gets the boolean value. When true, this will instruct the query object to make certain enhancements to the SQL query.

=head2 exists

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/exists>, L<DB::Object::Postgres::Tables/exists> or L<DB::Object::SQLite::Tables/exists>

=head2 field_exists

Provided with a field name, and this returns a boolean value as to whether that field exists in the table or not.

=head2 fields_as_array

Returns the table fields name as an L<array object|Module::Generic::Array>

=head2 fields

This calls L</structure> which may return cached data.

Returns an hash of fields to their corresponding L<object|DB::Object::Fields::Field>. Those objects are instantiated once by the L<structure method|DB::Object::Tables/structure>. If you plan on making change, make sure to clone them first.

If nothing is found, it returns an empty list in list context and L<perlfunc/undef> in scalar context.

It takes an optional parameter representing a field name, and will return its corresponding object, such as:

    my $tbl = $dbh->my_database_table || die( "No table 'my_database_table' in database" );
    my $field_object = $tbl->fields( 'my_table_field' ):

=head2 fields_object

    my $tbl = $dbh->user || die( "No table \"user\" found in database\n" );
    # get the field object for "name"
    my $name = $tbl->fields_object->name
    # Do something with it
    my $expr = $name == 'joe';
    # Resulting in an DB::Object::Fields::Overloaded object

This returns the cached object if there is one.

This will dynamically create a package based on the database and table name. For example a database C<Foo> and a table C<Bar> would result in the following dynamically created package: C<DB::Object::Tables::Foo::Bar>

This new package will inherit from L<DB::Object::Fields>, which enable the dynamic loading of column object using C<AUTOLOAD>

This will instantiate an object from this newly created package, cache it and return it.

=head2 fo

This is a convenient shortcut for L</fields_object>

    my $tbl = $dbh->user || die( "No table \"user\" found in database\n" );
    # get the field object for "name"
    my $name = $tbl->fo->name

=head2 foreign

Sets or gets the L<hash object|Module::Generic::Hash> of L<foreign key constraint objects|DB::Object::Constraint::Foreign> for this table.

Each key in the hash represents the foreign key constraint name and its value is an L<foreign key constraint object|DB::Object::Constraint::Foreign> that contains the following methods:

=over 4

=item * C<match>

Typical value is C<full>, C<partial> and C<simple>

=item * C<on_delete>

The action the database is to take upon deletion. For example: C<nothing>, C<restrict>, C<cascade>, C<null> or C<default>

=item * C<on_update>

The action the database is to take upon update. For example: C<nothing>, C<restrict>, C<cascade>, C<null> or C<default>

=item * C<table>

The table name of the foreign key.

=item * C<fields>

The L<array object|Module::Generic::Array> of associated column names for this foreign key constraint.

=item * C<name>

The foreign key constraint name.

=back

=head2 format_statement

This is a convenient wrapper around L<DB::Object::Query/format_statement>

Format the sql statement for queries of types C<select>, C<delete> and C<insert>

In list context, it returns 2 strings: one comma-separated list of fields and one comma-separated list of values. In scalar context, it only returns a comma-separated string of fields.

=head2 format_update

This is a convenient wrapper around L<DB::Object::Query/format_update>

Formats update query based on the following arguments provided:

=over 4

=item * C<data>

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

=head2 get_query_object

Get the L<DB::Object::Query> object. If none is set yet, it will instantiate one automatically.

=head2 group

This is a convenient wrapper around L<DB::Object::Query/group>

=head2 indexes

    my $idx = $tbl->indexes;
    my $in0 = $idx->{some_index};
    say "Is primary: ", $in0->is_primary ? 'yes' : 'no';
    say "Is unique: ", $in0->is_unique ? 'yes' : 'no';
    say "Associated fields: ", $in0->fields->join( ', ' );

Sets or gets the L<hash object|Module::Generic::Hash> of L<index objects|DB::Object::Constraint::Index> for this table.

Each key in the hash represents the index name and its value is an L<index object|DB::Object::Constraint::Index> that contains the following methods:

=over 4

=item * C<fields>

An L<array object|Module::Generic::Array> of table field names.

=item * C<is_primary>

Boolean value whether this index is the table primary index.

=item * C<is_unique>

Boolean value whether this is a unique index.

=back

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

=head2 new_check

This takes an hash or an hash reference of parameters and instantiate a new L<DB::Object::Constraint::Check> object.

If no C<debug> parameter is provided, the one of the current table object will be used.

It returns the new object upon success, or upon error, it sets an L<exception object|Module::Generic::Exception> and return C<undef> in scalar context, or an empty list in list context.

=head2 new_foreign

This takes an hash or an hash reference of parameters and instantiate a new L<DB::Object::Constraint::Foreign> object.

If no C<debug> parameter is provided, the one of the current table object will be used.

It returns the new object upon success, or upon error, it sets an L<exception object|Module::Generic::Exception> and return C<undef> in scalar context, or an empty list in list context.

=head2 new_index

This takes an hash or an hash reference of parameters and instantiate a new L<DB::Object::Constraint::Index> object.

If no C<debug> parameter is provided, the one of the current table object will be used.

It returns the new object upon success, or upon error, it sets an L<exception object|Module::Generic::Exception> and return C<undef> in scalar context, or an empty list in list context.

=head2 no_bind

Boolean. Sets the C<no bind> flags to true or false.

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

=head2 parent

For the drivers who support it, this will represent the parent table if the current table inherits from another table.

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

=head2 reset_structure

Resets the cache for the L</structure> method

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

=head2 structure

The implementation is driver specific.

This must be implemented by the driver package, so check L<DB::Object::Mysql::Tables/structure>, L<DB::Object::Postgres::Tables/structure> or L<DB::Object::SQLite::Tables/structure>

This returns a cached data for speed. See L</reset_structure> to reset that cache.

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

L<DB::Object::Mysql::Tables>, L<DB::Object::Postgres::Tables> or L<DB::Object::SQLite::Tables>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
