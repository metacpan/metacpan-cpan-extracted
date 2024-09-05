# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Query.pm
## Version v0.7.1
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2024/09/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Query;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object );
    use vars qw( $VERSION $DEBUG );
    use DB::Object::Query::Clause;
    use DB::Object::Query::Elements;
    use DB::Object::Query::Element;
    use Want;
    our $DEBUG = 0;
    our $VERSION = 'v0.7.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{alias}          = {} unless( CORE::exists( $self->{alias} ) );
    $self->{avoid}          = [] unless( CORE::exists( $self->{avoid} ) );
    $self->{binded}         = [] unless( CORE::exists( $self->{binded} ) );
    $self->{binded_group}   = [] unless( CORE::exists( $self->{binded_group} ) );
    $self->{binded_limit}   = [] unless( CORE::exists( $self->{binded_limit} ) );
    $self->{binded_order}   = [] unless( CORE::exists( $self->{binded_order} ) );
    $self->{binded_types}   = [] unless( CORE::exists( $self->{binded_types} ) );
    $self->{binded_values}  = [] unless( CORE::exists( $self->{binded_values} ) );
    $self->{binded_where}   = [] unless( CORE::exists( $self->{binded_where} ) );
    $self->{elements}       = undef unless( CORE::exists( $self->{elements} ) );
    $self->{enhance}        = 0 unless( CORE::exists( $self->{enhance} ) );
    $self->{from_table}     = [] unless( CORE::exists( $self->{from_table} ) );
    $self->{from_unixtime}  = [] unless( CORE::exists( $self->{from_unixtime} ) );
    $self->{group_by}       = '' unless( CORE::exists( $self->{group_by} ) );
    $self->{having}         = '' unless( CORE::exists( $self->{having} ) );
    $self->{join_fields}    = '' unless( CORE::exists( $self->{join_fields} ) );
    $self->{left_join}      = {} unless( CORE::exists( $self->{left_join} ) );
    $self->{limit}          = '' unless( CORE::exists( $self->{limit} ) );
    $self->{local}          = {} unless( CORE::exists( $self->{local} ) );
    $self->{order_by}       = '' unless( CORE::exists( $self->{order_by} ) );
    $self->{prepare_options}= {} unless( CORE::exists( $self->{prepare_options} ) );
    $self->{query_values}   = undef unless( CORE::exists( $self->{query_values} ) );
    $self->{reverse}        = '' unless( CORE::exists( $self->{reverse} ) );
    $self->{sorted}         = [] unless( CORE::exists( $self->{sorted} ) );
    $self->{table_alias}    = '' unless( CORE::exists( $self->{table_alias} ) );
    $self->{table_object}   = '' unless( CORE::exists( $self->{table_object} ) );
    $self->{unix_timestamp} = [] unless( CORE::exists( $self->{unix_timestamp} ) );
    $self->{where}          = '' unless( CORE::exists( $self->{where} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{constant}       = {};
    $self->{query}          = '';
    $self->{query_reset}    = 0;
    $self->{query_reset_core_keys} = [qw( alias binded binded_group binded_limit binded_order binded_types binded_values binded_where from_unixtime group_by limit local order_by reverse sorted table_alias unix_timestamp where )];
    $self->{selected_fields} = '';
    $self->{table_object}   = '';
    $self->{tie_order}      = [];
    unless( $self->{elements} )
    {
        $self->{elements} = $self->new_elements;
    }
    return( $self );
}

sub alias { return( shift->_set_get_hash( 'alias', @_ ) ); }

sub as_string { return( shift->{query} ); }

sub avoid { return( shift->_set_get_array_as_object( 'avoid', @_ ) ); }

sub binded { return( shift->_set_get_array_as_object( 'binded', @_ ) ); }

sub binded_group { return( shift->group->values ); }

sub binded_limit { return( shift->limit->values ); }

sub binded_order { return( shift->order->values ); }

# NOTE: sub binded_types is not used anymore as of 2023-07-19 (v0.11.7)
sub binded_types { return( shift->_set_get_array_as_object( 'binded_types', @_ ) ); }
# sub binded_types
# {
#     my $self = shift( @_ );
#     my $arr = $self->new_array;
#     my $e = $self->elements;
#     $e->keys->sort->foreach(sub
#     {
#         my $k = shift( @_ );
#         $arr->push( $e->{ $k }->type );
#     });
#     return( $arr );
# }

# sub binded_types_as_param
# {
#     my $self = shift( @_ );
#     return( $self->error( "The driver has not implemented the method binded_types_as_param." ) );
# }
sub binded_types_as_param
{
    my $self = shift( @_ );
    my $params = $self->new_array;
    $self->elements->foreach(sub
    {
        my $elem = shift( @_ );
        my $type;
        if( $elem && $elem->as_is )
        {
            return;
        }
        elsif( $elem && defined( $type = $elem->type ) )
        {
            $params->push( $type );
        }
        else
        {
            $params->push( '' );
        }
    });
    return( $params );
}

sub binded_values { return( shift->_set_get_array_as_object( 'binded_values', @_ ) ); }

sub binded_where { return( shift->_set_get_array_as_object( 'binded_where', @_ ) ); }

sub constant
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $def = shift( @_ );
        return( $self->error( "I was expecting a hash reference, but got '$def' instead." ) ) if( !$self->_is_hash( $def => 'strict' ) );
        foreach my $k (qw( pack file line ))
        {
            return( $self->error( "Parameter \"$k\" is missing in hash refernece provided." ) ) if( !$def->{ $k } );
        }
        ## sth may or may not be there
        return( $self->error( "Statement handler provided is not a DB::Object::Statement object." ) ) if( $def->{sth} && ( !$self->_is_object( $def->{sth} ) && !$def->{sth}->isa( 'DB::Object::Statement' ) ) );
        $self->{constant} = $def;
    }
    return( $self->{constant} );
}

# sub database_object { return( shift->table_object->database_object ) }
sub database_object { return( shift->_set_get_object_without_init( 'database_object', 'DB::Object', @_ ) ); }

sub delete
{
    my $self  = shift( @_ );
    my $constant = $self->constant;
    if( scalar( keys( %$constant ) ) )
    {
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table = $tbl_o->name ||
    return( $self->error( "No table to delete entries from was set." ) );
    my $where = '';
    $self->where( @_ ) if( @_ );
    # if( !$where && $self->{ 'query_reset' } )
    if( !$where )
    {
        $where = $self->where();
    }
    if( !$where )
    {
        return( $self->error( "You have provided no where clause. If you intend to delete all records from table '$table', you must do explicitly by preparing the statement yourself." ) );
    }
    my $clauses = $self->_query_components( 'delete' );
    my @query = ( "DELETE FROM $table" );
    # 'query_reset' condition to avoid catching parameters from pervious queries.
    push( @query, @$clauses ) if( scalar( @$clauses ) );
    my $query = $self->{query} = CORE::join( ' ', @query );
    return( $self->error( "Refusing to do a bulk delete. Enable the allow_bulk_delete database object property if you want to do so. Original query was: $query" ) ) if( !$self->where && !$self->database_object->allow_bulk_delete );
    $self->_save_bind();
    my $sth = $tbl_o->_cache_this( $self ) ||
        return( $self->error( "Error while preparing query to delete from table '$table':\n$query" ) );
    # Routines such as as_string() expect an array on pupose so we do not have to commit the action
    # but rather get the statement string. At the end, we write:
    # $obj->delete() to really delete
    # $obj->delete->as_string() to ONLY get the formatted statement
    # wantarray returns undef in void context, i.e. $obj->delete()
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
            return( $self->error( "Error while executing query to delete from table '$table':\n$query" ) );
        # Will be destroyed anyway and permits the end user to manipulate the object if needed
        # $sth->finish();
    }
    # wantarray returns false but not undef() otherwise, i.e.
    # $obj->delete->as_string();
    return( $sth );
}

# sub elements { return( shift->_set_get_hash_as_mix_object( 'elements', @_ ) ); }
sub elements { return( shift->_set_get_object_without_init( 'elements', 'DB::Object::Query::Elements', @_ ) ); }

sub enhance { return( shift->_set_get_boolean( 'enhance', @_ ) ); }

# Used in conjonction with constant(), allows internally to know if the query has reached the end of the chain
# Such as $tbl->select->join( $tbl_object, $conditions )->join( $other_tbl_object, $other_conditions );
# final() enables to know the query reached the end, so that when constant is used, all the processing can be skipped
sub final { return( shift->_set_get_scalar( 'final', @_ ) ); }

sub format_from_epoch
{
    warn( "This method \"format_from_epoch\" was not superseded.\n" );
}

sub format_to_epoch
{
    warn( "This method \"format_to_epoch\" was not superseded.\n" );
}

# NOTE: For select or insert queries
sub format_statement
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    # Should we use bind statement?
    my $bind  = $tbl_o->database_object->use_bind;
    $opts->{data} = $self->{_default} if( !$opts->{data} );
    $opts->{order} = $self->{_fields} if( !$opts->{order} );
    $opts->{table} = $tbl_o->qualified_name if( !$opts->{table} );
    local $_;
    my $data  = $opts->{data};
    my $order = $opts->{order};
    my $table = $opts->{table};
    my $prefix = $tbl_o->prefix;
    my $from_unix = {};
    my $unixtime  = {};
    my $args = $self->{_args};
    my $fields = '';
    my $values = '';
    my $base_class = $self->base_class;
    $from_unix = $self->{_from_unix};
    my $tmp_ref = $self->from_unixtime();
    map{ $from_unix->{ $_ }++ } @$tmp_ref;
    $tmp_ref = $self->unix_timestamp();
    map{ $unixtime->{ $_ }++ } @$tmp_ref;
    my @format_fields = ();
    my @format_values = ();
    # my $binded   = $self->{binded_values} = [];
    my $multi_db = $tbl_o->prefix_database;
    my $db       = $tbl_o->database;
    my $fields_ref = $tbl_o->fields_as_array;
    my $ok_list  = $fields_ref->join( '|' )->scalar;
    my $tables   = CORE::join( '|', @{$tbl_o->database_object->tables} );
    my $struct   = $tbl_o->structure || return( $self->pass_error( $tbl_o->error ) );
    my $query_type = $self->{query_type};
    my @sorted   = ();
    $self->messagec( 6, "{green}", scalar( @$args ), "{/} arguments provided are -> ", sub{ $self->Module::Generic::dump( $args ) } );
    $self->messagec( 6, "\$order contains -> {green}", join( "{/}, {green}", sort( keys( %$order ) ) ), "{/}" );
    if( $self->query_type eq 'insert' &&
        @$args && 
        !( @$args % 2 ) )
    {
        for( my $i = 0; $i < @$args; $i += 2 )
        {
            push( @sorted, $args->[ $i ] ) if( exists( $order->{ $args->[ $i ] } ) );
            $data->{ $args->[ $i ] } = $args->[ $i + 1 ] if( !exists( $data->{ $args->[ $i ] } ) );
        }
    }
    @sorted = sort{ $order->{ $a }->pos <=> $order->{ $b }->pos } keys( %$order ) if( !@sorted );
    $self->messagec( 6, "\@sorted contains -> {green}", join( "{/}, {green}", @sorted ), "{/}" );
    # Used for insert or update so that execute can take a hash of key => value pair and we would bind the values in the right order
    # But or that we need to know the order of the fields.
    $self->{sorted} = \@sorted;
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    my $elems = $self->new_elements;
    
    foreach( @sorted )
    {
        my $elem = $self->new_element;
        if( exists( $data->{ $_ } ) )
        {
            my $value = $data->{ $_ };
            $self->messagec( 4, "Checking field {green}${_}{/} with value {green}", ( $value // 'undef' ), "{/}" );
            if( $self->_is_a( $value => "${base_class}::Statement" ) )
            {
                $elem->value( '(' . $value->as_string . ')' );
                # push( @format_values, '(' . $value->as_string . ')' );
                # $self->binded_types->push( $value->query_object->binded_types_as_param );
                # $elems->merge( $value->query_object->elements );
                $elem->elements( $value->query_object->elements );
            }
            # This is for insert or update statement types
            elsif( exists( $from_unix->{ $_ } ) )
            {
                if( $bind )
                {
                    # push( @$binded, $value );
                    # push( @format_values, $self->format_from_epoch({ value => $value, bind => 1 }) );
                    $elem->value( $value );
                    $elem->format( $self->format_from_epoch({ value => $value, bind => 1 }) );
                }
                else
                {
                    # push( @format_values, $self->format_from_epoch({ value => $value, bind => 0 }) );
                    $elem->format( $self->format_from_epoch({ value => $value, bind => 0 }) );
                }
                # $self->binded_types->push( '' );
            }
            elsif( exists( $unixtime->{ $_ } ) )
            {
                if( $bind )
                {
                    # push( @$binded, $value );
                    # push( @format_values, $self->format_to_epoch({ value => $value, bind => 1 }) );
                    $elem->value( $value );
                    $elem->format( $self->format_to_epoch({ value => $value, bind => 1 }) );
                }
                else
                {
                    # push( @format_values, $self->format_to_epoch({ value => $value, bind => 0 }) );
                    $elem->format( $self->format_to_epoch({ value => $value, bind => 0 }) );
                }
                # $self->binded_types->push( '' );
            }
            elsif( ref( $value ) eq 'SCALAR' )
            {
                # push( @format_values, $$value );
                $elem->format( $$value );
            }
            elsif( $value =~ /^($placeholder_re)$/ )
            {
                # push( @format_values, $1 );
                # $self->binded_types->push( '' );
                $elem->placeholder( $1 );
                $elem->format( $1 );
            }
            elsif( $struct->{ $_ } =~ /^\s*\bBLOB\b/i )
            {
                # push( @format_values, '?' );
                # push( @$binded, $value );
                # $self->binded_types->push( '' );
                $elem->placeholder( '?' );
                $elem->format( '?' );
                $elem->value( $value );
            }
            # If the value itself looks like a field name or like a SQL function
            # or simply if bind option is inactive
            # This stinks too much. It is way too complex to parse or guess a sql query
            # use \( instead to pass a scalar reference
#             elsif( $value =~ /(?:\.|\A)(?:$ok_list)\b/ ||
#                    $value =~ /[a-zA-Z_]{3,}\([^\)]*\)/ ||
#                       $value eq '?' )
#             {
#                 push( @format_values, $value );
#             }
            elsif( !$bind )
            {
                # push( @format_values, sprintf( "%s", $tbl_o->database_object->quote( $value ) ) );
                $elem->format( sprintf( "%s", $tbl_o->database_object->quote( $value ) ) );
            }
            # We do this before testing for param binding because DBI puts quotes around SET number :-(
            elsif( $value =~ /^\d+$/ && $struct->{ $_ } =~ /\bSET\(/i )
            {
                # push( @format_values, $value );
                $elem->format( $value );
            }
            elsif( $value =~ /^\d+$/ && 
                   $struct->{ $_ } =~ /\bENUM\(/i && 
                      ( $query_type eq 'insert' || $query_type eq 'update' ) )
            {
                # push( @format_values, "'$value'" );
                $elem->format( "'$value'" );
            }
            # Otherwise, bind option is enabled, we bind parameter
            elsif( $bind )
            {
                # push( @format_values, '?' );
                # push( @$binded, $value );
                # $self->binded_types->push( '' );
                $elem->placeholder( '?' );
                $elem->format( '?' );
                $elem->value( $value );
            }
            # In last resort, we handle the formatting ourself
            else
            {
                # push( @format_values, $tbl_o->database_object->quote( $value ) );
                $elem->format( $tbl_o->database_object->quote( $value ) );
            }
        }
    
        if( $prefix ) 
        {
            s{
                (?<![\.\"])\b($ok_list)\b(\s*)?(?!\.)
            }
            {
                my( $field, $spc ) = ( $1, $2 );
                if( $` =~ /\s+(?:AS|FROM)\s+$/i )
                {
                    "$field$spc";
                }
                elsif( $query_type eq 'select' && $prefix )
                {
                    "$prefix.$field$spc";
                }
                else
                {
                    "$field$spc";
                }
            }gex;
            s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
            # push( @format_fields, $_ );
        }
#         else
#         {
#             push( @format_fields, $_ );
#         }
        $elem->field( $_ );
        $elems->push( $elem );
    }
    if( !wantarray() && scalar( @{$self->{_extra}} ) )
    {
        # push( @format_fields, @{$self->{_extra}} );
        foreach my $this ( @{$self->{_extra}} )
        {
            $elems->push({
                field => $this,
                debug => $self->debug,
            });
        }
    }
    
    return( $elems );
}

sub format_update
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( $self->_is_array( $_[0] ) || $self->_is_hash( $_[0] => 'strict' ) || @_ % 2 );
    my @arg  = @_;
    if( !@arg && $data )
    {
        if( $self->_is_hash( $data => 'strict' ) )
        {
            @arg = %$data;
        }
        elsif( $self->_is_array( $data ) )
        {
            @arg = @$data;
        }
    }
    
    return( $self->error( "Must provide key => value pairs. I received an odd number of arguments" ) ) if( @arg && ( scalar( @arg ) % 2 ) );
    my %arg  = ( @arg );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    $arg{default} ||= $self->{_default};
    if( $arg{data} && !$data )
    {
        my $hash = $arg{data};
        my @vals = %$hash;
        $data    = \@vals;
    }
    elsif( $self->_is_hash( $data => 'strict' ) )
    {
        my @vals = %$data;
        $data    = \@vals;
    }
    my $info = $data || \@arg;
    if( !$info || !scalar( @$info ) )
    {
        return( $self->error( "No data to update was provided to format update." ) );
    }
    my $bind   = $tbl_o->database_object->use_bind;
    my $def    = $arg{default} || $self->{_default};
    my $fields_ref = $tbl_o->fields;
    my $fields_list = CORE::join( '|', keys( %$fields_ref ) );
    my $struct = $tbl_o->structure || return( $self->pass_error( $tbl_o->error ) );
    my $types  = $tbl_o->types;
    my $from_unix = $self->from_unixtime();
    my $from_unixtime = { map{ $_ => 1 } @$from_unix };
    my @fields = ();
    my @binded = ();
    my @types  = ();
    # Get the constant has definition for each table fields
    my $types_const = $tbl_o->types_const;
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    # Before we used to call getdefault supplying it our new values and the
    # format_statement() that would take the default supplied values
    # Now, this works differently since we use update() method and supply 
    # directly our value to update to it
    # In this context, getting the default values is dangerous, since resetting
    # the values to their default ones is not was we want, is it?
    my $elems = $self->new_elements;
    while( @$info )
    {
        my( $field, $value ) = splice( @$info, 0, 2 );
        $self->messagec( 4, "Processing field {green}${field}{/}" );
        # Do not update a field that does not belong in this table
        next if( !exists( $fields_ref->{ $field } ) );
        # DB::Object::Fields::Field object
        my $fo = $fields_ref->{ $field };
        my $elem = $self->new_element( field => $field );
        # Make it a FROM_UNIXTIME field if this is what we need.
        # $value = "FROM_UNIXTIME($value)" if( exists( $from_unixtime->{ $field } ) );
        # $value = \"TO_TIMESTAMP($value)" if( exists( $from_unixtime->{ $field } ) );
        # This is for insert or update statement types
        if( exists( $from_unixtime->{ $field } ) )
        {
            if( $bind )
            {
                $elem->value( $value );
                $elem->format( "$field=" . $self->format_from_epoch({ value => $value, bind => 1 }) );
            }
            else
            {
                $elem->format( "$field=" . $self->format_from_epoch({ value => $value, bind => 0 }) );
            }
        }
        elsif( ref( $value ) eq 'SCALAR' )
        {
            $elem->format( "$field=$$value" );
            $elem->as_is(1);
        }
        # Maybe $bind is not enabled, but the user may have manually provided a placeholder, i.e. '?'
        elsif( !$bind )
        {
            my $const;
            if( $value =~ /^($placeholder_re)$/ )
            {
                $elem->placeholder( $1 );
                $elem->format( "$field = $1" );
                if( $const = $fo->datatype->constant )
                {
                    $elem->type( $const );
                }
            }
            elsif( $self->_is_hash( $value => 'strict' ) &&
                   ( $fo->type eq 'jsonb' || $fo->type eq 'json' ) )
            {
                my $this_json = $self->_encode_json( $value );
                $const = $fo->datatype->constant;
                $elem->format( sprintf( "$field=%s", $tbl_o->database_object->quote( $this_json, $const ) ) );
            }
            elsif( $tbl_o->database_object->placeholder->has( $self->_is_scalar( $value ) ? $value : \$value ) )
            {
                $tbl_o->database_object->placeholder->replace( $self->_is_scalar( $value ) ? $value : \$value );
                $elem->placeholder( '?' );
                $elem->format( "$field = ${value}" );
                if( $const = $fo->datatype->constant )
                {
                    $elem->type( $const );
                }
            }
            elsif( $const = $fo->datatype->constant )
            {
                $elem->format( sprintf( "$field=%s", $tbl_o->database_object->quote( $value, $const ) ) );
            }
            else
            {
                $elem->format( sprintf( "$field=%s", $tbl_o->database_object->quote( $value ) ) );
            }
        }
        # if this is a SET field type and value is a number, treat it as a number and not as a string
        # We do this before testing for param binding because DBI puts quotes around SET number :-(
        elsif( $value =~ /^\d+$/ && $struct->{ $field } =~ /\bSET\(/i )
        {
            $elem->format( "$field=$value" );
        }
        elsif( $bind )
        {
            $elem->placeholder( '?' );
            $elem->format( "$field=?" );
            $elem->value( $value );
            my $const;
            if( $const = $fo->datatype->constant )
            {
                $elem->type( $const );
            }
        }
        else
        {
            my $const;
            if( $const = $fo->datatype->constant )
            {
                $elem->format( "$field=" . $tbl_o->database_object->quote( $value, $const ) );
            }
            else
            {
                $elem->format( "$field=" . $tbl_o->database_object->quote( $value ) );
            }
        }
        $elems->push( $elem );
    }
    return( $elems );
}

sub from_table { return( shift->_set_get_array_as_object( 'from_table', @_ ) ); }

sub from_unixtime { return( shift->_set_get_array_as_object( 'from_unixtime', @_ ) ); }

sub getdefault
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table = $opts->{table} || $tbl_o->name;
    my $prefix = $tbl_o->query_object->table_alias ? $tbl_o->query_object->table_alias : $tbl_o->prefix;
    my $arg = [];
    if( $opts->{arg} )
    {
        return( $self->error( "arg parameter provided, but is not an array reference." ) ) if( !$self->_is_array( $opts->{arg} ) );
        $arg = $opts->{arg};
        return( $self->error( "arg parameter provided is not a key => value pair. Its number of elements should be an even number." ) ) if( scalar( @$arg ) && ( @$arg % 2 ) );
    }
    my %arg       = ();
    my $default   = {};
    my $fields    = [];
    my $structure = {};
    my $base_class = $self->base_class;
    # Contains some extra parameters for SELECT queries only
    # Right now a concatenation of 'last_name' and 'first_name' fields into field named 'name'
    my @extra      = ();
    $self->messagec( 5, "{green}", scalar( @$arg ), "{/} arguments provided." );
    %arg = @$arg if( scalar( @$arg ) );
    $opts->{table} = lc( $opts->{table} );
    $opts->{time} = time() if( !defined( $opts->{time} ) );
    my $time        = '';
    $time           = $opts->{time} if( $opts->{time} =~ /^\d+$/ );
    $time         ||= $opts->{unixtime} || time();
    my $query_type  = $opts->{query_type};
    if( !$query_type )
    {
        my( $pkg, $file, $line, $sub ) = caller(1);
        $sub =~ s/(.*):://;
        $query_type = $sub;
    }
    my $alias = '';
    if( $query_type ne 'insert' && $query_type ne 'delete' && $query_type ne 'replace' )
    {
        $alias = $opts->{as};
        $alias = $self->alias if( !$alias || !%$alias );
    }
    my $avoid       = $opts->{avoid} || $self->avoid();
    my $unix_time   = $opts->{unix_timestamp} || $self->unix_timestamp;
    my $from_unix   = $opts->{from_unixtime} || $self->from_unixtime;

    my $enhance     = $tbl_o->enhance;
    # Need to do hard copy of hashes
    $default   = $tbl_o->default || return( $self->pass_error( $tbl_o->error ) );
    $fields    = $tbl_o->fields || return( $self->pass_error( $tbl_o->error ) );
    $structure = $tbl_o->structure || return( $self->pass_error( $tbl_o->error ) );
    
    $self->messagec( 4, "For table {green}${table}{/} {green}", scalar( keys( %$default ) ), "{/} defaults found and {green}", scalar( keys( %$fields ) ), "{/} fields found." );
    if( !scalar( keys( %$fields ) ) )
    {
        return( $self->error( "Missing fields (", scalar( keys( %$fields ) ), " found) for table \"$table\"." ) );
    }
    
    if( $query_type eq 'select' && $enhance )
    {
        my @sorted = sort{ $fields->{ $a }->pos <=> $fields->{ $b }->pos } keys( %$fields );
        foreach my $field ( @sorted )
        {
            if( $structure->{ $field } =~ /^\s*(?:DATE(?:TIME)?|TIMESTAMP)\s*/i )
            {
                my $f = $self->format_to_epoch({
                    value => ( $prefix ? "${prefix}.${field}" : $field ),
                    bind => 0,
                    quote => 0,
                });
                my $fo = $tbl_o->fo->new_field(
                    debug => $self->debug,
                    name => "$f AS ${field}_unixtime",
                    pos => ( scalar( keys( %$fields ) ) + 1 ),
                    query_object => $self,
                    table_object => $self->table_object,
                    type => 'integer',
                ) || return( $self->pass_error( $tbl_o->fo->error ) );
                # $fields->{ "$f AS ${field}_unixtime" } = scalar( keys( %$fields ) ) + 1;
                $fields->{ "$f AS ${field}_unixtime" } = $fo;
            }
        }
    }
    
    my %to_unixtime = ();
    if( $self->_is_array( $unix_time ) )
    {
        %to_unixtime = map{ $_ => 1 } @$unix_time;
    }
    elsif( $self->_is_hash( $unix_time => 'strict' ) )
    {
        %to_unixtime = %$unix_time;
    }
    
    if( %to_unixtime && scalar( keys( %to_unixtime ) ) )
    {
        foreach my $field ( keys( %to_unixtime ) )
        {
            if( exists( $fields->{ $field } ) )
            {
                my $func = $self->format_to_epoch({
                    value => ( $prefix ? "${prefix}.${field}" : $field ),
                    bind => 0,
                    quote => 0,
                });
                my $fo = $tbl_o->fo->new_field(
                    debug => $self->debug,
                    name => $func . ' AS ' . $field,
                    pos => $fields->{ $field }->pos,
                    query_object => $self,
                    table_object => $self->table_object,
                    type => 'integer',
                ) || return( $self->pass_error( $tbl_o->fo->error ) );
                $fields->{ $func . ' AS ' . $field } = $fo;
                delete( $fields->{ $field } );
            }
        }
    }
    
    my %avoid = ();
    if( $self->_is_array( $avoid ) )
    {
        %avoid = map{ $_ => 1 } @$avoid;
    }
    elsif( $self->_is_hash( $avoid => 'strict' ) )
    {
        %avoid = %$avoid;
    }
    
    if( %avoid && scalar( keys( %avoid ) ) )
    {
        foreach my $field ( keys( %avoid ) )
        {
            if( exists( $fields->{ $field } ) )
            {
                delete( $fields->{ $field } );
                delete( $default->{ $field } );
            }
        }
    }
    
    my %as = ();
    if( $self->_is_hash( $alias => 'strict' ) )
    {
        %as = %$alias;
        foreach my $field ( keys( %as ) )
        {
            my $f;
            if( exists( $fields->{ $field } ) )
            {
                $f = $prefix 
                        ? "${prefix}.${field}" 
                        : $field;
                # delete( $fields{ $field } );
            }
            else
            {
                $f = $field;
            }
            my $fo = $tbl_o->fo->new_field(
                debug => $self->debug,
                name => $f . ' AS "' . $as{ $field } . '"',
                pos => ( scalar( keys( %$fields ) ) + 1 ),
                query_object => $self,
                table_object => $self->table_object,
                type => 'integer',
            ) || return( $self->pass_error( $tbl_o->fo->error ) );
            $fields->{ $f . ' AS "' . $as{ $field } . '"' } = $fo;
        }
    }
    if( $query_type eq 'select' && 
        $enhance &&
        exists( $fields->{last_name} ) && 
        exists( $fields->{first_name} ) && 
        !exists( $fields->{name} ) )
    {
    
        my $f = $prefix 
                ? "CONCAT(${prefix}.first_name, ' ', ${prefix}.last_name)" 
                : "CONCAT(first_name, ' ', last_name)";
        push( @extra, "$f AS name" );
    }
    
    if( ( exists( $default->{auth} ) && !defined( $arg{auth} ) ) || 
        defined( $arg{auth} ) )
    {
        $default->{auth} = defined( $arg{auth} ) 
            ? $arg{auth}
            : 0;
    }
    if( ( exists( $default->{status} ) && !defined( $default->{status} ) ) || 
        defined( $arg{status} ) )
    {
        $default->{status} = defined( $arg{status} ) 
            ? $arg{status}
            : 1;
    }
    
    foreach my $data ( keys( %arg ) )
    {
        if( exists( $default->{ $data } ) )
        {
            $default->{ $data } = $arg{ $data };
        }
    }
    my %from_unixtime = ();
    if( $self->_is_array( $from_unix ) )
    {
        %from_unixtime = map{ $_ => 1 } @$from_unix;
    }
    elsif( $self->_is_hash( $from_unix => 'strict' ) )
    {
        %from_unixtime = %$from_unix;
    }
    
    
    $self->{_args} = $arg;
    $self->{_default} = $default;
    $self->{_fields} = $fields;
    $self->{_extra} = \@extra;
    $self->{_structure} = $structure;
    $self->{_from_unix} = \%from_unixtime;
    $self->{_to_unix} = \%to_unixtime;
    $self->{query_type} = $query_type;
    $self->{bind} = $tbl_o->database_object->use_bind;
    return( $self );
}

sub group { return( shift->_group_order( 'group', 'group_by', @_ ) ); }

sub having { return( shift->error( "Having clause is not supported by this driver." ) ); }

# $tbl->insert( field1 => $val1, field2 => $val2 );
# or
# $tbl->insert([ field1 => $val1, field2 => $val2 ]);
# or
# $tbl->insert({ field1 => $val1, field2 => $val2 });
# or
# my $select_statement_object = $tbl2->select || die( $tbl2->error );
# $tbl->insert( $select_statement_object );
# or
# my $select_statement_object = $tbl2->select || die( $tbl2->error );
# $tbl->insert( field1 => $val1, field2 => $val2, $select_statement_object );
# or
# my $select_statement_object = $tbl2->select || die( $tbl2->error );
# $tbl->insert([ field1 => $val1, field2 => $val2, $select_statement_object ]);
sub insert
{
    my $self = shift( @_ );
    # Could be an array of fields, or a SQL statement object.
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    my $constant = $self->constant;
    if( scalar( keys( %$constant ) ) )
    {
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my %arg = ();
    my $select = '';
    my $base_class = $self->base_class;
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table = $tbl_o->name ||
        return( $self->error( "No table was provided to insert data." ) );
    # We do not decide of the value of AUTO_INCREMENT fields, so we do not use them in
    # our INSERT statement.
    my $fields_ref = $tbl_o->fields || return( $self->pass_error( $tbl_o->error ) );
    my @avoid  = ();
    my( $fields, $values, $elems );
    my $el = $self->elements;

    if( !@arg && $data && $self->_is_hash( $data => 'strict' ) )
    {
        @arg = %$data;
    }
    # User passed an array reference
    elsif( !@arg && ref( $data ) && $self->_is_array( $data ) )
    {
        @arg = @$data;
        if( scalar( @arg ) && $self->_is_a( $arg[-1] => "${base_class}::Statement" ) )
        {
            my $sth = pop( @arg );
            $select = $sth->as_string;
            $self->messagec( 5, "Merging {green}", $sth->query_object->elements->length, "{/} elements from this statement object into our INSERT query." );
            $el->merge( $sth->query_object->elements );
        }
    }
    # insert into (field1, field2, field3) select field1, field2, field3 from some_table where some_id=12
    elsif( $data && ref( $data ) eq "${base_class}::Statement" )
    {
        $select = $data->as_string;
        $self->messagec( 4, "Select statement object provided as sole argument for this INSERT query -> ${select} with {green}", $data->query_object->elements, "{/} elements to merge from this statement object with our INSERT query." );
        $el->merge( $data->query_object->elements );
    }
    elsif( scalar( @arg ) && $self->_is_a( $arg[-1] => "${base_class}::Statement" ) )
    {
        my $sth = pop( @arg );
        $select = $sth->as_string;
        $self->messagec( 5, "Merging {green}", $sth->query_object->elements->length, "{/} elements from this statement object into our INSERT query." );
        $el->merge( $sth->query_object->elements );
    }
    $self->messagec( 4, "{green}", scalar( @arg ), "{/} arguments provided: {green}", ( scalar( @arg ) / 2 ). "{/} fields and {green}", ( scalar( @arg ) / 2 ), "{/} values." );
    my @query = ();
    if( $select )
    {
        my $sql;
        if( scalar( @arg ) )
        {
            for( my $i = 0; $i < scalar( @arg ); $i++ )
            {
                if( $self->_is_a( $arg[$i] => 'DB::Object::Fields::Unknown' ) )
                {
                    warn( "Unknown field object '", $arg[$i]->field, "' provided for INSERT into table '", $arg[$i], "'" ) if( $self->_is_warnings_enabled( 'DB::Object' ) );
                    splice( @arg, $i, 1 );
                }
            }
            $sql = "INSERT INTO $table (" . join( ', ', @arg ) . ") $select";
        }
        else
        {
            $sql = "INSERT INTO $table $select";
        }
        @query = ( $sql );
    }
    else
    {
        %arg = @arg if( @arg );
        foreach my $field ( keys( %$fields_ref ) )
        {
            my $fo = $fields_ref->{ $field };
            # push( @avoid, $field ) if( $fields_ref->{ $field } =~ /\b(AUTO_INCREMENT|SERIAL|nextval)\b/i && !$arg{ $field } );
            if( defined( $fo->default ) && 
                $fo->default =~ /\b(AUTO_INCREMENT|SERIAL|nextval)\b/i &&
                !$arg{ $field } )
            {
                push( @avoid, $field );
            }
            # It is useless to insert a blank data in a field whose default value is NULL.
            # Especially since a test on a NULL field may be made specifically.
            if( scalar( @arg ) && 
                !exists( $arg{ $field } ) &&
                $fo->is_nullable )
            {
                push( @avoid, $field );
            }
        }
        $self->getdefault(
            table => $table,
            arg => \@arg,
            avoid => \@avoid,
        ) || return( $self->pass_error );
        $elems = $self->format_statement || return( $self->pass_error );
        $fields = $elems->fields->join( ', ' );
        $values = $elems->formats->join( ', ' );
        $el->merge( $elems );
        @query = ( "INSERT INTO $table ($fields) VALUES($values)" );
    }
    
    if( $data && $self->_is_hash( $data => 'strict' ) && $el->types->length )
    {
        warn( "You have passed arguments to this insert as hash reference, and you are using placeholders. Using placeholders requires fixed order of arguments which an hash reference cannot guarantee. This will potentially lead to error when executing the query. I recommend you switch to an array of arguments instead, i.e. from { field1 => value1, field2 => value2 } to ( field1 => value1, field2 => value2 ), or to use numbered placeholders like \$1, \$2, etc...\n" );
    }
    $self->messagec( 5, "So far this query object has {green}", $el->length, "{/} elements." );
    my $clauses = $self->_query_components( 'insert' ) || return( $self->pass_error );
    $self->messagec( 5, "After getting the components, this query object has {green}", $el->length, "{/} elements." );
    push( @query, @$clauses ) if( scalar( @$clauses ) );
    my $query = $self->{query} = CORE::join( ' ', @query );
    # Everything meaningfull lies within the object
    # If no bind should be done _save_bind does nothing
    $self->_save_bind();
    # Query string should lie within the object
    # _cache_this sends back an object no matter what or unde() if an error occurs
    my $sth = $tbl_o->_cache_this( $self );
    # STOP! No need to go further
    if( !defined( $sth ) )
    {
        return( $self->error( "Error '", $tbl_o->error, "' while preparing query to insert data into table '$table':\n$query" ) );
    }
    # Called in void context
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to insert data to table '$table':\n$query" ) );
    }
    return( $sth );
}

sub is_upsert { return( shift->_set_get_boolean( 'is_upsert', @_ ) ); }

sub join_fields { return( shift->_set_get_scalar( 'join_fields', @_ ) ); }

sub join_tables { return( shift->_set_get_object_array_object( 'join_tables', 'DB::Object::Tables', @_ ) ); }

sub left_join { return( shift->_set_get_hash( 'left_join', @_ ) ); }

sub limit
{
    my $self  = shift( @_ );
    my $limit = $self->{limit};
    if( @_ )
    {
        # Returns a DB::Object::Query::Clause
        $limit = $self->_process_limit( @_ ) ||
            return( $self->pass_error );
        if( CORE::length( $limit->metadata->limit // '' ) )
        {
            $limit->generic( CORE::length( $limit->metadata->offset // '' ) ? 'LIMIT ?, ?' : 'LIMIT ?' );
            # %s works for integer, and also for numbered placeholders like $1 or ?1, or regular placeholder like ?
            $limit->value(
                CORE::length( $limit->metadata->offset // '' )
                    ?  sprintf( "LIMIT %s, %s", $limit->metadata->offset, $limit->metadata->limit )
                    : sprintf( "LIMIT %s", $limit->metadata->limit )
            );
        }
    }
    
    if( !$limit && want( 'OBJECT' ) )
    {
        return( $self->new_null( type => 'object' ) );
    }
    return( $limit );
}

sub local
{
    my $self = shift( @_ );
    $self->{local} ||= {};
    my $local = $self->{local};
    if( @_ )
    {
        my $data = $self->_get_args_as_hash( @_ );
        my $str  = '';
        if( scalar( keys( %$data ) ) )
        {
            my @keys = keys( %$data );
            @$local{ @keys } = @$data{ @keys };
        }
    }
    return( wantarray() ? () : undef() ) if( !$local || !%$local );
    return( %$local ) if( wantarray() );
    my $str = join( ', ', map{ "\@${_} = '" . $local->{ $_ } . "'" } keys( %$local ) );
    # return( "SET $str" );
    return( $str );
}

sub new_clause
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug if( !exists( $opts->{debug} ) );
    $opts->{query_object} = $self;
    my $o = DB::Object::Query::Clause->new( %$opts ) ||
        return( $self->error( "Unable to create a DB::Object::Query::Clause object: ", DB::Object::Query::Clause->error ) );
    return( $o );
}

sub new_element
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug if( !exists( $opts->{debug} ) );
    $opts->{query_object} = $self;
    my $elem = DB::Object::Query::Element->new( %$opts ) ||
        return( $self->pass_error( DB::Object::Query::Element->error ) );
    return( $elem );
}

sub new_elements
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug if( !exists( $opts->{debug} ) );
    $opts->{query_object} = $self;
    my $e = DB::Object::Query::Elements->new( %$opts ) ||
        return( $self->pass_error( DB::Object::Query::Elements->error ) );
    return( $e );
}

sub order { return( shift->_group_order( 'order', 'order_by', @_ ) ); }

sub prepare_options { return( shift->_set_get_hash_as_mix_object( 'prepare_options', @_ ) ); }

sub query { return( shift->_set_get_scalar( 'query', @_ ) ); }

sub query_reset { return( shift->_set_get_boolean( 'query_reset', @_ ) ); }

sub query_reset_core_keys { return( shift->_set_get_array_as_object( 'query_reset_core_keys', @_ ) ); }

sub query_reset_keys { return( shift->_set_get_array_as_object( 'query_reset_keys', @_ ) ); }

sub query_type { return( shift->_set_get_scalar( 'query_type', @_ ) ); }

sub query_values { return( shift->_set_get_scalar_as_object( 'query_values', @_ ) ); }

sub replace { return( shift->error( "The replace sql query is not supported by this driver." ) ); }

sub reset
{
    my $self = shift( @_ );
    if( !$self->{query_reset} )
    {
        my $core_keys = $self->query_reset_core_keys;
        my $keys      = $self->query_reset_keys;
        # Make sure the driver's list of keys for query reset is complete by merging this base class keys with the diver's one
        unless( $core_keys == $keys )
        {
            my $new_keys = $keys->merge( $core_keys )->unique->sort;
            $keys = $self->query_reset_keys( $new_keys );
        }
        CORE::delete( @$self{ @$keys } );
        $self->{query_reset}++;
        $self->{enhance} = 1;
    }
    return( $self );
}

sub reset_bind
{
    my $self = shift( @_ );
    my @f = qw( binded binded_group binded_limit binded_order binded_types binded_where );
    foreach my $field ( @f )
    {
        $self->{ $field } = [];
    }
    return( $self );
}

sub returning { return( shift->error( "Returning clause is not supported by this driver" ) ); }

sub reverse
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{reverse}++;
    }
    return( $self->{reverse} );
}

sub select
{
    my $self   = shift( @_ );
    my $constant = $self->constant;
    if( scalar( keys( %$constant ) ) )
    {
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my $tbl_o    = $self->table_object || return( $self->error( "No table object is set." ) );
    my $prefix   = $tbl_o->query_object->table_alias ? $tbl_o->query_object->table_alias : $tbl_o->prefix;
    my $table    = $tbl_o->qualified_name ||
    return( $self->error( "No table name provided to perform select statement." ) );
    my $bind     = $tbl_o->use_bind;
    my $cache    = $tbl_o->use_cache;
    # my $multi_db = $tbl_o->param( 'multi_db' );
    my $multi_db = $tbl_o->prefix_database;
    my $db       = $tbl_o->database();
    my $fields   = '';
    my $ok_ref   = $tbl_o->fields;
    my $ok_list  = CORE::join( '|', keys( %$ok_ref ) );
    my $tables   = CORE::join( '|', @{$tbl_o->database_object->tables} );
    if( @_ )
    {
        # Get aliases
        my $alias = $self->alias();
        my $data = ( @_ == 1 && ref( $_[0] ) ) ? shift( @_ ) : [ @_ ];
        if( ref( $data ) eq 'SCALAR' )
        {
            $fields = $$data;
        }
        elsif( $self->_is_array( $data ) )
        {
            # Remove from the provided list any name that are aliases
            FIELD: for( my $i = 0; $i < scalar( @$data ); $i++ )
            {
                if( $self->_is_a( $data->[$i] => 'DB::Object::Fields::Unknown' ) )
                {
                    warn( "Unknown field object '", $data->[$i]->field, "' of table '", $data->[$i]->table, "' used in SELECT statement" ) if( $self->_is_warnings_enabled( 'DB::Object' ) );
                    splice( @$data, $i, 1 );
                    $i--;
                    next;
                }
                
                foreach my $n ( keys( %$alias ) )
                {
                    if( lc( $alias->{ $n } ) eq lc( $data->[$i] ) )
                    {
                        splice( @$data, $i, 1 );
                        $i--;
                        next FIELD;
                    }
                }
            }
            # No fields provided after all? We fallback to use the magic '*' optimizer
            $fields = @$data
                ? CORE::join( ', ', @$data )
                : scalar( keys( %$alias ) )
                    ? ''
                    : ( $prefix ? "${prefix}.*" : '*' );
        }
        else
        {
            $fields = $data;
        }
        
        if( length( $fields ) )
        {
            # Now, we eventually add the table and database specification to the fields
            $fields =~ s{
                (?<![\.\"])\b($ok_list)\b(\s*)?(?!\.)
            }
            {
                my( $field, $spc ) = ( $1, $2 );
                if( $` =~ /\s+(?:AS|FROM)\s+$/i || !$field )
                {
                    "${field}${spc}";
                }
                elsif( $prefix )
                {
                    "${prefix}.${field}${spc}";
                }
                else
                {
                    "${field}${spc}";
                }
            }gex;
            $fields =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
        }
        
        $self->messagef_colour( 3, "<green>%d</> aliases were provided: <red>%s</>", scalar( keys( %$alias ) ), join( ', ', keys( %$alias ) ) );
        if( $alias && %$alias )
        {
            my @aliases = ();
            foreach my $f ( keys( %$alias ) )
            {
                if( ref( $alias->{ $f } ) eq 'SCALAR' )
                {
                    CORE::push( @aliases, "$f AS " . ${$alias->{ $f }} );
                }
                elsif( CORE::exists( $ok_ref->{ $f } ) && $prefix )
                {
                    CORE::push( @aliases, "${prefix}.${f} AS \"" . $alias->{ $f } . "\"" );
                }
                elsif( $f =~ /\b(?:$ok_list)\b/ ||
                       $f =~ /\w\([^\)]*\)/ )
                {
                    $f =~ s{
                        (?<![\.\"])\b($ok_list)\b(\s*)?(?!\.)
                    }
                    {
                        my( $ok, $spc ) = ( $1, $2 );
                        "${prefix}.${ok}${spc}";
                    }gex if( $prefix );
                    $f =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
                    CORE::push( @aliases, "$f AS " . "\"" . $alias->{ $f } . "\"" );
                }
                else
                {
                    CORE::push( @aliases, "$f AS " . "\"" . $alias->{ $f } . "\"" );
                }
            }
            $fields = length( $fields )
                ? join( ', ', $fields, @aliases )
                : join( ', ', @aliases );
        }
    }
    else
    {
        $self->getdefault( table => $table ) || return( $self->pass_error );
        my $elems = $self->format_statement || return( $self->pass_error );
        $fields = $elems->fields->join( ', ' );
    }
    
    my $tie   = $self->tie();
    my $clauses = $self->_query_components( 'select' ) || return( $self->pass_error );
    my $vars  = $self->local();
    # You may not sort if there is no order clause
    my $sort  = $self->reverse() ? 'DESC' : $self->sort() ? 'ASC' : '';
    # my @query = $multi_db ? ( "SELECT $fields FROM $db.$table" ) : ( "SELECT $fields FROM $table" );
    # $table comes from $tbl->qualified_name which automatically sets itself with the right prefixes based on the prefixed() settings
    my $table_alias = '';
    if( length( $table_alias = $self->table_alias ) )
    {
        $table_alias = " AS $table_alias";
    }
    my @query = ( "SELECT $fields FROM ${table}${table_alias}" );
    my $prev_fields = $self->selected_fields;
    my $last_sth    = '';
    my $queries = $self->_cache_queries;
    # A simple check to avoid to do this test on each query, but rather only on those who deserve it.
    if( $fields eq $prev_fields && @$queries )
    {
        my @last_query = grep
        {
            $_->selected_fields ||= '';
            $_->selected_fields eq $fields 
        } @$queries;
        $last_sth = $last_query[ 0 ] || {};
    }
    # If the selected fields in the last query performed were the same than those ones and
    # that the last query object has the flag 'as_string' set to true, this would mean that
    # user has made a statement as string and is now really executing it
    # Now, if the special flag 'query_reset' is true, this means that the user has accessed the methods
    # where(), group(), order() or limit() and hence this is a brain new query for which we need
    # to get the clause conditions
    #if( $fields eq $$prev_fields && $last_sth->{ 'as_string' } )
    #{
        # unshift( @query, "${vars};" ) if( $vars );
        push( @query, @$clauses ) if( @$clauses );
    #}
    # used by join()
    $self->selected_fields( $fields );
    my $query = $self->{query} = CORE::join( ' ', @query );
    my @tie_order = ();
    if( $tie && %$tie )
    {
        my $copy = $fields;
        # According to bind_col() specifications, we need to bind perl variable 
        # in the right column order.
        # We make it easy for our user, to only provide the column name and its corresponding variable
        # We will do the job of matching
        while( $copy =~ s/^.*?\b([a-zA-Z0-9\_]+)\s*(?:\,|\Z)// )
        {
            push( @tie_order, $1 );
        }
        $self->{tie_order} = \@tie_order;
    }
    # Everything meaningfull lies within the object
    # If no bind should be done _save_bind does nothing
    $self->_save_bind();
    
    # Predeclare variables if any.
    $tbl_o->set();
    
    # Query string should lie within the object
    # _cache_this sends back an object no matter what or undef() if an error occurs
    my $sth = $tbl_o->_cache_this( $self );
    # STOP! No need to go further
    if( !defined( $sth ) )
    {
        return( $self->error( "Error while preparing query to select on table '$self->{ 'table' }':\n$query", $self->errstr() ) );
    }
    # Routines such as as_string() expect an array on pupose so we do not have to commit the action
    # but rather get the statement string. At the end, we write:
    # $obj->select() to really select
    # $obj->select->as_string() to ONLY get the formatted statement
    # wantarray() returns the undefined value in void context, which is typical use of a real select command
    # i.e. $obj->select();
    # Straight forward declaration: $obj->select(); or $obj->select->execute() || die( $obj->error() );
    if( !defined( wantarray() ) )
    {
        $sth->execute ||
            return( $self->error( "Error while executing query to select:\n", $self->as_string(), $sth->errstr() ) );
    }
    return( $sth );
}

sub selected_fields { return( shift->_set_get( 'selected_fields', @_ ) ); }

sub sort
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{reverse} = 0;
    }
    return( $self->{reverse} );
}

# The fields in their order of appearance in insert and update
# so that following ->exec( $hash ) would be able to allocate the bind values in the right order
sub sorted { return( shift->_set_get_array_as_object( 'sorted', @_ ) ); }

sub table_alias { return( shift->_set_get_scalar( 'table_alias', @_ ) ); }

sub table_object { return( shift->_set_get_object_without_init( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub tie
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $ref  = '';
        $ref = shift( @_ ) if( @_ && @_ % 2 );
        my %hash = ( @_ );
        $ref ||= \%hash;
        $self->{tie} = $ref;
    }
    return( wantarray() ? %{$self->{tie}} : $self->{tie} );
}

sub unix_timestamp { return( shift->_set_get_array_as_object( 'unix_timestamp', @_ ) ); }

sub update
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    if( !@arg && $data )
    {
        if( $self->_is_hash( $data => 'strict' ) )
        {
            @arg = %$data;
        }
        elsif( $self->_is_array( $data ) )
        {
            @arg = @$data;
        }
    }
    my $constant = $self->constant;
    if( scalar( keys( %$constant ) ) )
    {
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table = $tbl_o->name ||
    return( $self->error( "No table to update was provided." ) );
    if( !scalar( @arg ) )
    {
        return( $self->error( "No data to update was provided." ) );
    }
    my $el = $self->elements;
    my $elems = $self->format_update( \@arg ) || return( $self->pass_error );
    $el->merge( $elems ) || return( $self->pass_error );
    my $values = $elems->formats->join( ', ' );
    my $clauses = $self->_query_components( 'update' );
    my @query  = ( "UPDATE $table SET $values" );
    push( @query, @$clauses ) if( scalar( @$clauses ) );
    my $query = $self->{query} = CORE::join( ' ', @query );
    if( !$self->where && !$self->database_object->allow_bulk_update )
    {
        my( $p, $f, $l ) = caller();
        my $call_sub = ( caller(1) )[3];
        return( $self->error( "Refusing to do a bulk update. Called from package $p in file $f at line $l from sub $call_sub. Enable the allow_bulk_update database object property if you want to do so. Original query was: $query" ) );
    }
    $self->query_values( $values );
    $self->_save_bind();
    my $sth = $tbl_o->_cache_this( $self ) ||
    return( $self->error( "Error while preparing query to update table '$table':\n$query" ) );
    # $obj->update() to really delete
    # $obj->update->as_string() to ONLY get the formatted statement
    # wantarray() returns the undefined value in void context, which is typical use of a real update command
    # i.e. $obj->update();
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to update table '$table':\n$query" ) );
        # $sth->finish();
    }
    # wantarray returns false but not undefined when $obj->update->as_string();
    return( $sth );
}

sub where { return( shift->_where_having( 'where', 'where', @_ ) ); }

sub _group_order
{
    my $self  = shift( @_ );
    # This is the type, ie 'group', 'order' and used to initiate the DB::Object::Query::Clause
    my $type  = shift( @_ ) || return( $self->error( "No clause type was provided." ) );
    # This is used to store the data in $self such as $self->{ $prop } = $clause;
    my $prop  = shift( @_ ) || return( $self->error( "No object data property name was provided for clause type '$type'." ) );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $bind  = $tbl_o->use_bind;
    my $table = $tbl_o->name;
    # $self->{ $prop } = $self->new_clause if( !CORE::length( $self->{ $prop } ) && !ref( $self->{ $prop } ) );
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    my $clause;
    if( @_ )
    {
        $self->messagec( 6, "Received arguments -> {green}", join( "{/}, {green}", map( overload::StrVal( $_ ), @_ ) ), "{/}" );
        my $fields_ref = $tbl_o->fields;
        my $fields     = join( '|', keys( %$fields_ref ) );
        my $prefix     = $tbl_o->prefix;
        my $db         = $tbl_o->database;
        my $tables     = CORE::join( '|', @{$tbl_o->database_object->tables} );
        my $multi_db   = $tbl_o->prefix_database;
        my $data   = ( @_ == 1 && ( !$self->_is_object( $_[0] ) || $self->_is_array( $_[0] ) ) && !exists( $fields_ref->{ "$_[0]" } ) )
            ? shift( @_ )
            : [ @_ ];
        if( $self->_is_array( $data ) )
        {
            $clause = $self->new_clause(
                type    => $type,
                debug   => $self->debug,
            );
            
            foreach my $field ( @$data )
            {
                # Some garbage reached us
                next if( !CORE::length( $field // '' ) );
                
                # Special treatment if we are being provided multiple clause to merge with ours
                if( $self->_is_a( $field => 'DB::Object::Query::Clause' ) )
                {
                    if( !$self->{ $prop } )
                    {
                        $self->{ $prop } = $clause;
                    }
                    else
                    {
                        $clause = $self->{ $prop };
                    }
                    $clause->merge( $field );
                    next;
                }
                
                # Transform a simple 'field' into a field object
                $field = $tbl_o->fo->$field if( CORE::exists( $fields_ref->{ $field } ) );
                # my $elem = $self->new_element( field => $field );
                my $elem;
                if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) )
                {
                    $elem = $self->new_element(
                        field => $field,
                        # Not necessary; this is already the default value
                        # generic => '?',
                        type => '',
                        value => $field,
                    );
                }
                elsif( $self->_is_a( $field => 'DB::Object::Fields::Unknown' ) )
                {
                    $self->messagec( 2, "{red}Unknown field provided ", $field->field, " !{/}" );
                    # warn( "Unnown field provided with field object for field ", $field->field ) if( $self->_is_warnings_enabled( 'DB::Object' ) );
                    # next;
                    return( $self->error( "Unnown field provided with field object for field '", $field->field, "'" ) );
                }
                # i.e. GROUP BY width => GROUP BY table.width
                elsif( ref( $field ) eq 'SCALAR' )
                {
                    $elem = $self->new_element(
                        field => $field,
                        type => '',
                        value => $$field,
                    );
                }
                elsif( $field =~ /^($placeholder_re)$/ )
                {
                    $elem = $self->new_element(
                        field => $field,
                        placeholder => $1,
                        type => '',
                        value => $field,
                    );
                }
                elsif( $field =~ /\b(?:$fields)\b/ ||
                       $field =~ /\w\([^\)]*\)/ ||
                       !$bind )
                {
                    $field =~ s{
                        (?<![\.\"])\b($fields)\b(\s*)?(?!\.)
                    }
                    {
                        my( $ok, $spc ) = ( $1, $2 );
                        "${prefix}.${ok}${spc}";
                    }gex if( $prefix );
                    $field =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
                    $elem = $self->new_element(
                        field => $field,
                        type => '',
                        value => $field,
                    );
                }
                else
                {
                    $elem = $self->new_element(
                        field => $field,
                        # Not necessary; this is already the default value
                        # generic => '?',
                        type => '',
                        value => $field,
                    );
                }
                $clause->push( $elem );
            }
            $clause->value( $clause->values->join( ', ' ) );
            $clause->generic( $clause->generics->join( ', ' ) );
        }
        # Merging our clause with a new one
        elsif( $self->_is_a( $data => 'DB::Object::Query::Clause' ) )
        {
            $clause = $self->{ $prop }
                ? $self->{ $prop }
                : $self->new_clause( type => $type );
            $clause->merge( $data );
        }
        else
        {
            $clause = $self->new_clause({
                value => $data,
                type => $type,
            });
            my $elem;
            if( ref( $data ) eq 'SCALAR' )
            {
                $elem = $self->new_element(
                    field => $data,
                    type => '',
                    value => $$data,
                );
                $clause->push( $elem );
            }
            elsif( $data =~ /^($placeholder_re)$/ )
            {
                $elem = $self->new_element(
                    field => $data,
                    placeholder => $1,
                    type => '',
                    value => $data,
                );
                $clause->push( $elem );
            }
            elsif( $data =~ /\b(?:$fields)\b/ ||
                   $data =~ /\w\([^\)]*\)/ ||
                   !$bind )
            {
                $data =~ s{
                    (?<![\.\"])\b($fields)\b(\s*)?(?!\.)
                }
                {
                    my( $ok, $spc ) = ( $1, $2 );
                    "${prefix}.${ok}${spc}";
                }gex if( $prefix );
                $data =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
                $elem = $self->new_element(
                    field => $data,
                    type => '',
                    value => $data,
                );
                $clause->push( $elem );
            }
            elsif( $bind )
            {
                # $self->_value2bind( \$data, $ref );
                my $elems = $self->_value2bind( \$data );
                # $clause->bind->values( $ref );
                # $clause->bind->types( ( '' ) x scalar( @$ref ) );
                $clause->push( $elems->elements->list ) if( $elems->elements->length );
            }
            else
            {
                $elem = $self->new_element(
                    field => $data,
                    # Not necessary; this is already the default value
                    # generic => '?',
                    type => '',
                    value => $data,
                );
                $clause->push( $elem );
            }
        }
        $self->{ $prop } = $clause if( $clause->elements->length );
    }
    else
    {
        $clause = $self->{ $prop };
    }
    
    if( !$clause && want( 'OBJECT' ) )
    {
        return( $self->new_null( type => 'object' ) );
    }
    return( $clause );
}

# Each driver can call on this private method like sub having { return( shift->_having( @_ ) ); }
# to avoid recreating it themselve
sub _having
{
    my $self  = shift( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $bind  = $tbl_o->use_bind;
    my $table = $tbl_o->name;
    my $prefix = $tbl_o->prefix;
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    my $clause;
    if( @_ )
    {
        my $data = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
        if( $self->_is_array( $data ) )
        {
            my $fields_ref = $tbl_o->fields;
            my $fields     = join( '|', keys( %$fields_ref ) );
            my $db         = $tbl_o->database;
            my $tables     = CORE::join( '|', @{$self->{tables}->{ $db }} );
            my $multi_db   = $tbl_o->prefix_database;
            my @values     = ();
            my @clause     = ();
            my @types      = ();
            foreach my $field ( @$data )
            {
                # In case we received some garbage
                next if( !CORE::length( $field ) );
                
                # Special treatment if we are being provided multiple clause to merge with ours
                if( $self->_is_a( $field => 'DB::Object::Query::Clause' ) )
                {
                    if( !$self->{having} )
                    {
                        $self->{having} = $self->new_clause( type => 'having' );
                    }
                    else
                    {
                        $clause = $self->{having};
                    }
                    $clause->merge( $field );
                    next;
                }

                # i.e. HAVING width => HAVING table.width
                if( ref( $field ) eq 'SCALAR' )
                {
                    push( @clause, $self->new_clause({
                        value   => $$field,
                        type    => 'having',
                    }) );
                }
                elsif( $field =~ /^($placeholder_re)$/ )
                {
                    my $plh = $1;
                    my $cl = $self->new_clause(
                        value   => $field,
                        type    => 'having',
                    );
                    
                    my $elem = $self->new_element(
                        placeholder => $plh,
                    );
                    $cl->push( $elem );
                    CORE::push( @clause, $cl );
                }
                elsif( $field =~ /\b(?:$fields)\b/ ||
                       $field =~ /\w\([^\)]*\)/ ||
                       !$bind )
                {
                    $field =~ s{
                        (?<![\.\"])\b($fields)\b(\s*)?(?!\.)
                    }
                    {
                        my( $ok, $spc ) = ( $1, $2 );
                        "${prefix}.${ok}${spc}";
                    }gex if( $prefix );
                    $field =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
                    push( @clause, $self->new_clause({
                        value   => $field,
                        type    => 'having',
                    }) );
                }
                elsif( $bind )
                {
                    my $elem = $self->new_element(
                        placeholder => '?',
                        value       => $field,
                    );
                    my $cl = $self->new_clause(
                        value   => '?',
                        type    => 'having',
                    );
                    $cl->push( $elem );
                    CORE::push( @clause, $cl );
                }
                else
                {
                    push( @clause, $self->new_clause({
                        value => $field,
                        type => 'having',
                    }) );
                }
            }
            $clause = $self->new_clause( type => 'having' )->merge( $self->database_object->AND( @clause ) );
            # $clause->bind->values( @values ) if( $bind );
            # $clause->bind->types( @types ) if( $bind );
        }
        else
        {
#             my $ref = [];
#             if( $bind )
#             {
#                 $self->_value2bind( \$clause, $ref );
#                 $clause->bind->values( @$ref ) if( $bind && scalar( @$ref ) );
#                 $clause->bind->types( ( '' ) x scalar( @$ref ) ) if( $bind );
#             }
            my $elems = $self->_value2bind( \$data );
            $clause = $self->new_clause(
                value => $data,
                type => 'having',
            );
            $clause->push( $elems->elements->list ) if( $elems->elements->length );
        }
        $self->{having} = $clause;
    }
    else
    {
        $clause = $self->{having};
    }
    
    if( !$clause && want( 'OBJECT' ) )
    {
        return( $self->new_null( type => 'object' ) );
    }
    return( $clause );
}

sub _initiate_clause_object
{
    my $self = shift( @_ );
    return( DB::Object::Query::Clause->new( @_ ) );
}

sub _limit { return( shift->_set_get_object( 'limit', 'DB::Object::Query::Clause', @_ ) ); }

sub _process_limit
{
    my $self  = shift( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $bind  = $tbl_o->use_bind;
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    my $limit;
    
    # $self->limit can be used to set the offset and limit, but can also be used to 
    # pass limit clause object to be merged, so here we check it, and if found, we do not go further.
    if( @_ )
    {
        # First check if what we are being provided is not clause objects
        my @clauses = ();
        for( my $i = 0; $i < scalar( @_ ); $i++ )
        {
            # Special treatment if we are being provided multiple clause to merge with ours
            if( $self->_is_a( $_[$i] => 'DB::Object::Query::Clause' ) )
            {
                push( @clauses, $_[$i] );
                splice( @_, $i, 1 );
                $i--;
            }
        }
        
        if( scalar( @clauses ) )
        {
            if( !$self->{limit} )
            {
                $self->{limit} = $limit = $self->new_clause( type => 'limit' );
            }
            else
            {
                $limit = $self->{limit};
            }
            $limit->merge( @clauses );
            return( $limit );
        }
        
        my( $start, $end );
        if( @_ == 1 )
        {
            $end = shift( @_ );
        }
        else
        {
            ( $start, $end ) = splice( @_, 0, 2 );
        }
        my @binded = ();
        my @list   = ();
        my @types  = ();
        my @generic = ();
        $limit = $self->new_clause( type => 'limit' );
        foreach my $value ( $start, $end )
        {
            next if( !CORE::length( $value // '' ) );
            my $elem = $self->new_element;
            # This is a raw parameter - being a ref to a SCALAR means we must not modify it
            if( ref( $value ) eq 'SCALAR' )
            {
                push( @list, $$value );
            }
            # A value to be a place holder - forward it
            # elsif( $value eq '?' )
            elsif( $value =~ /^($placeholder_re)$/ )
            {
                # Maybe ? or $1, or ?1
                push( @list, $1 );
                push( @generic, $1 );
                $elem->placeholder( $1 );
                # push( @binded, $value );
                # push( @types, '' );
                $elem->value( $value );
            }
            # Normal processing
            else
            {
                push( @list, $value );
                push( @generic, '?' );
                # push( @binded, $value );
                # push( @types, '' );
                $elem->placeholder( '?' );
                $elem->value( $value );
            }
            $limit->push( $elem );
        }
        # $limit = $self->{limit} = [ @list ];
        $limit->value( CORE::join( ', ', @list ) ) if( scalar( @list ) );
        $limit->generic( CORE::join( ', ', @generic ) ) if( scalar( @generic ) );
        # $limit->bind->values( \@binded );
        # $limit->bind->types( \@types );
        if( scalar( @list ) )
        {
            if( scalar( @list ) > 1 )
            {
                $limit->metadata->offset( $list[0] ) if( CORE::length( $list[0] // '' ) );
                $limit->metadata->limit( $list[1] ) if( CORE::length( $list[1] // '' ) );
            }
            else
            {
                $limit->metadata->offset( '' );
                $limit->metadata->limit( $list[0] ) if( CORE::length( $list[0] // '' ) );
            }
        }
        $self->{limit} = $limit;
    }
    else
    {
        $limit = $self->{limit};
    }
    
    if( !$limit && want( 'OBJECT' ) )
    {
        return( $self->new_null( type => 'object' ) );
    }
    return( $limit );
}

sub _query_components
{
    my $self = shift( @_ );
    my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my( $where, $group, $sort, $order, $limit );
    $where = $self->where;
    if( $type eq 'select' )
    {
        $group = $self->group;
        $sort  = $self->reverse ? 'DESC' : $self->sort ? 'ASC' : '';
        $order = $self->order;
    }
    $limit = $self->limit;
    my @query = ();
    push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
    push( @query, "GROUP BY $group" ) if( $group && $type eq 'select' );
    push( @query, "ORDER BY $order" ) if( $order && $type eq 'select' );
    push( @query, $sort ) if( $sort && $order && $type eq 'select' );
    push( @query, "LIMIT $limit" ) if( $limit && $type ne 'insert' );
    return( \@query );
}

sub _query_type
{
    my $self = shift( @_ );
    if( $self->{query} && length( $self->{query} ) )
    {
        return( lc( ( $self->{query} =~ /^[[:blank:]]*(ALTER|CREATE|DROP|GRANT|LISTEN|NOTIFY|INSERT|UPDATE|DELETE|SELECT|TRUNCATE)\b/i )[0] ) )
    }
    return;
}

sub _save_bind
{
    my $self  = shift( @_ );
    my $type  = shift( @_ );
    if( !$type )
    {
        my( $pkg, $file, $line, $sub ) = caller( 1 );
        $sub =~ s/(.*):://;
        $type = $sub;
    }
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $bind  = $tbl_o->use_bind;
    my $where = $self->where;
    my $group = $self->group;
    my $order = $self->order;
    my $limit = $self->limit;
    # This is used so upon execute, the saved binded parameters get sent to the DBI::execute method
    if( $bind )
    {
        # Replace binded()
        my $elems = $self->elements;
        $elems->push( $where->elements ) if( $where->length && !$where->elements->is_empty );
        $elems->push( $group->elements ) if( $group->length && !$group->elements->is_empty );
        $elems->push( $order->elements ) if( $order->length && !$order->elements->is_empty );
        $elems->push( $limit->elements ) if( $limit->length && !$limit->elements->is_empty );
    }
    return( $self );
}

sub _value2bind
{
    my $self   = shift( @_ );
    # If we are not suppose to bind any values, there is no point to go on.
    # return(1) if( !$self->{ 'bind' } );
    my $str    = shift( @_ );
    my $ref    = shift( @_ );
    my $tbl_o  = $self->{table_object} || return( $self->error( "No table object is set." ) );
    my $table  = $tbl_o->name;
    my $bind   = $tbl_o->use_bind;
    my $db     = $tbl_o->database;
    my $prefix = $tbl_o->prefix;
    my $fields_ref = $tbl_o->fields;
    my $fields = CORE::join( '|', keys( %$fields_ref ) );
    my $tables = CORE::join( '|', @{$tbl_o->database_object->tables} );
    my $multi_db = $tbl_o->param( 'multi_db' );
    my @binded = ();
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    my $elems = $self->new_elements;
    $$str =~ s
    {
        (([\w\_]+)(?:\.))?\b([a-zA-Z\_]+)\b\s*(=|\!=|LIKE)\s*['"]([^'"]+)['"]
    }
    {
        do
        {
            my( $this_table, $field, $equity, $value ) = ( $2, $3, $4, $5 );
            # Add to the list of value to bind on execute() only if this is not already a place holder
            # push( @binded, $value ) if( $bind && $value ne '?' );
            $this_table ||= $table;
            $this_table .= '.';
            # $bind ? "${this_table}${field}=?" : "${this_table}${field}='$value'";
            my $elem = $self->new_element( field => "${this_table}${field}" );
            my $result;
            if( $value !~ /[\r\n]+/ &&
                ( $value =~ /\b(?:$fields)\b/ ||
                  $value =~ /\w\([^\)]*\)/ ||
                  $value =~ /^$placeholder_re$/ ) )
            {
                if( $value =~ /^($placeholder_re)$/ )
                {
                    $elem->placeholder( $1 );
                }
                $result = "${this_table}${field} $equity $value";
                $elems->push( $elem );
            }
            elsif( $bind )
            {
                # push( @binded, $value );
                $result = "${this_table}${field} $equity ?";
                $elem->placeholder( '?' );
                $elem->value( $value );
                $elems->push( $elem );
            }
            else
            {
                $result = "${this_table}${field} $equity '$value'";
            }
            $result;
        };
    }geix;
    $$str =~ s
    {
        (?<![\.\"])\b($fields)\b(\s*)?(?!\.)
    }
    {
        my( $ok, $spc ) = ( $1, $2 );
        "$prefix.$ok$spc";
    }gex if( $prefix );
    $$str =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
    # push( @$ref, @binded ) if( @binded );
    # return(1);
    return( $elems );
}

sub _where_having
{
    my $self  = shift( @_ );
    # This is the type, ie 'group', 'order' and used to initiate the DB::Object::Query::Clause
    my $type  = shift( @_ ) || return( $self->error( "No clause type was provided." ) );
    # This is used to store the data in $self such as $self->{ $prop } = $clause;
    my $prop  = shift( @_ ) || return( $self->error( "No object data property name was provided for clause type '$type'." ) );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $base_class = $tbl_o->base_class;
    my $bind = $tbl_o->use_bind;
    # $self->{ $prop } = $self->new_clause if( !CORE::length( $self->{ $prop } ) || !$self->_is_object( $self->{ $prop } ) );
    # my $where = $self->{ $prop };
    my $where;
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    if( @_ )
    {
        my @params = @_;
        # This will change the belonging of the object $self to the class DB::Object::Prepare so method
        # such as select, insert, update, delete know there are some conditionning clause to be added
        my $table      = $tbl_o->name;
        my $db         = $tbl_o->database;
        my $multi_db   = $tbl_o->prefix_database;
        my $prefix     = $tbl_o->prefix;
        my $fields_ref = $tbl_o->fields;
        my $fields     = CORE::join( '|', keys( %$fields_ref ) );
        my $fields_type = $tbl_o->types;
        
        my $process_where_condition;
        $process_where_condition = sub
        {
            # my @parameters = @_;
            # my $data = shift( @_ ) if( @_ % 2 && !( scalar( @_ ) == 1 && $self->_is_object( $_[0] ) ) );
            my $data;
            unless( scalar( @_ ) == 1 && $self->_is_object( $_[0] ) )
            {
                $data = shift( @_ ) if( ( @_ % 2 ) && !$self->_is_object( $_[0] ) );
            }
            # Implicit AND operator by default to join multiple fields
            my $agg_op = 'AND';
            my @arg = ();
            if( $self->_is_a( $_[0], 'DB::Object::Operator' ) )
            {
                return( $self->error( "I was expecting an operator object, but got \"", $_[0], "\" instead." ) ) if( !$_[0]->isa( 'DB::Object::Operator' ) );
                $agg_op = $_[0]->operator || return( $self->error( "Unknown operator for \"", $_[0], "\"." ) );
                # We filter out any unknown field
                ( @arg ) = grep( !$self->_is_a( $_ => 'DB::Object::Fields::Unknown' ), $_[0]->value );
            }
            else
            {
                @arg = @_;
            }
            $data      = \@arg if( @arg );
            my $str    = '';
            my @binded = ();
            my @types  = ();
            my $clause;
            # A simple scalar
            if( ref( $data ) eq 'SCALAR' )
            {
                $str = $$data;
            }
            elsif( ref( $data ) )
            {
                $self->messagec( 5, "[process_where_condition] Processing {green}", scalar( @arg ), "{/} arguments: '{green}", join( "{/}', '{green}", map( overload::StrVal( $_ ), @arg ) ), "{/}'" );
                my @list = ();
                my( $field, $value );
                while( @arg )
                {
                    if( $self->_is_object( $arg[0] ) && $arg[0]->isa( 'DB::Object::Operator' ) )
                    {
                        my $op_object = shift( @arg );
                        $self->messagec( 5, "[process_where_condition] Argument is a {green}DB::Object::Operator{/} object, calling sub \$process_where_condition->( $op_object )" );
                        $clause = $process_where_condition->( $op_object );
                        push( @list, $clause );
                        next;
                    }
                    # This is an already formulated clause
                    elsif( $self->_is_object( $arg[0] ) && $arg[0]->isa( 'DB::Object::Query::Clause' ) )
                    {
                        $self->messagec( 5, "[process_where_condition] Argument is a {green}DB::Object::Query::Clause{/} object, adding it to the list" );
                        push( @list, shift( @arg ) );
                        next;
                    }
                    # An expression
                    elsif( $self->_is_a( $arg[0] => 'DB::Object::Expression' ) )
                    {
                        $self->messagec( 5, "[process_where_condition] Argument is a {green}DB::Object::Expression{/} object, adding it to the list" );
                        push( @list, shift( @arg ) );
                        next;
                    }
                    elsif( $self->_is_object( $arg[0] ) && $arg[0]->isa( 'DB::Object::Fields::Overloaded' ) )
                    {
                        $self->messagec( 5, "[process_where_condition] Argument is a {green}DB::Object::Fields::Overloaded{/} object." );
                        my $f = shift( @arg );
                        $self->messagec( 5, "[process_where_condition] Making new clause with field object '{green}${f}{/}'" );
                        my $cl = $self->new_clause(
                            value => $f,
                            type => 'where',
                        );
                        # $cl->bind->types->push( '' ) if( $f->binded );
                        if( $f->placeholder )
                        {
                            my $const = $f->field->datatype->constant;
                            my $offset = $f->index;
#                             $cl->push({
#                                 field   => $f->field,
#                                 # Use the offset expressly provided (e.g. $1 (PostgreSQL) or ?1 (SQLite), or the last position in the array
#                                 ( defined( $offset ) ? ( index => $offset ) : () ),
#                                 ( $const ? ( type => $const ) : () ),
#                             }) || return( $self->pass_error( $cl->error ) );
                            # Even better than instantiating a new DB::Object::Element object, we just use as-is the DB::Object::Fields::Overloaded object, which inherits from DB::Object::Element :)
                            $cl->push( $f );
                            
#                             if( $const )
#                             {
#                                 $cl->bind->types->push( $const );
#                             }
#                             else
#                             {
#                                 $cl->bind->types->push( '' );
#                             }
                        }
                        push( @list, $cl );
                        
                        # If this field value assignment is followed (as a pair) by just a regular field, this is likely a typo.
                        # Catching some typical typo errors for the benefit of the coder (from experience)
                        if( scalar( @arg ) && 
                            $self->_is_a( $arg[0], 'DB::Object::Fields::Field' ) )
                        {
                            warn( "Warning only: found a (proper) field value assignment ($f) followed by a field object '$arg[0]' (never mind the surrounding quotes) (", overload::StrVal( $arg[0] ), "). Did you forget to assign a value such as \$tbl->fo->$arg[0] == 'something' ?\n" );
                        }
                        next;
                    }
                    # Ignore it
                    elsif( $self->_is_a( $arg[0] => 'DB::Object::Fields::Unknown' ) )
                    {
                        $self->messagec( 5, "{red}[process_where_condition] Found an unknown field object DB::Object::Fields::Unknown '", $arg[0]->field, "' of table '", $arg[0]->table, "'{/}, ignoring: ", $arg[0]->error );
                        # warn( "Found an unknown field object DB::Object::Fields::Unknown '", $arg[0]->field, "' of table '", $arg[0]->table, "' in WHERE or HAVING clause: ", $arg[0]->error ) if( $self->_is_warnings_enabled( 'DB::Object' ) );
                        # shift( @arg );
                        # next;
                        return( $self->error( "Found an unknown field object DB::Object::Fields::Unknown '", $arg[0]->field, "' of table '", $arg[0]->table, "' in WHERE or HAVING clause: ", $arg[0]->error ) );
                    }
                    # Case where there is a litteral query component, e.g. "LENGTH(lang) = 2" and the number of arguments is odd which means there is no second argument such as: ->where( "LENGTH(lang) = 2", $tbl->fo->user_id => "something );
                    elsif( ( scalar( @arg ) % 2 ) && !ref( $arg[0] ) )
                    {
                        $self->messagec( 5, "[process_where_condition] Found a litteral query component {green}", $arg[0], "{/}" );
                        push( @list, $self->new_clause( value => shift( @arg ), type => 'where' ) );
                        next;
                    }
                    elsif( ( scalar( @arg ) % 2 ) && ref( $arg[0] ) eq 'SCALAR' )
                    {
                        my $scalar = shift( @arg );
                        push( @list, $self->new_clause( value => $$scalar, type => 'where' ) );
                        next;
                    }
                    # Catching some typical typo errors for the benefit of the coder (from experience)
                    # The coder provided a field object without associated value and there are no other argument passed to the where clause. He/she probably forget the assignment like $tbl->fo->field == 'something'
                    elsif( $self->_is_a( $arg[0], 'DB::Object::Fields::Field' ) && scalar( @arg ) == 1 )
                    {
                        warn( "Warning only: found a field object '$arg[0]' (never mind the surrounding quotes) (", overload::StrVal( $arg[0] ), ") followed by no other argument. Did you forget to assign a value such as \$tbl->fo->$arg[0] == 'something' ?\n" );
                    }
                    
                    my( $field, $value ) = splice( @arg, 0, 2 );
                    $self->messagec( 5, "[process_where_condition] Now processing field {green}${field}{/} and value {green}${value}{/}" );
                    # Catching some typical typo errors for the benefit of the coder (from experience)
                    if( $self->_is_a( $field, 'DB::Object::Fields::Field' ) && 
                        $self->_is_a( $value, 'DB::Object::Fields::Overloaded' ) )
                    {
                        warn( "Warning only: found a field object '$field' (never mind the surrounding quotes) (", overload::StrVal( $field ), ") followed by an another (proper) field value assignment ($value). Did you forget to assign a value such as \$tbl->fo->$field == 'something' ?\n" );
                    }
                    
                    unless( $self->_is_a( $field => 'DB::Object::Fields::Field' ) )
                    {
                        $field =~ s/\b(?<![\.\"])($fields)\b/$prefix.$1/gs if( $prefix );
                    }
                    my $i_am_negative = 0;
                    if( $self->_is_a( $value, 'DB::Object::NOT' ) )
                    {
                        $self->messagec( 5, "[process_where_condition] Value is a {green}DB::Object::NOT{/} object, negating the field -> value relationship" );
                        ( $value ) = $value->value;
                        $value = $self->database_object->NULL if( !defined( $value ) );
                        # https://www.postgresql.org/docs/8.3/functions-comparison.html
                        if( lc( $value ) eq 'null' )
                        {
                            # If e do not first copy the value to a separate variable, we would end up with a circular reference (type REF)
                            push( @list, $self->new_clause({
                                value => "$field IS NOT NULL",
                                type => 'where',
                                })
                            );
                            next;
                        }
                        $i_am_negative++;
                    }
                    # When value is undef() or explicitly set to NULL, we need to write this as IS NULL to be sql compliant
                    elsif( !defined( $value ) || lc( $value ) eq 'null' )
                    {
                        $self->messagec( 5, "[process_where_condition] Value is undefined or 'null', setting clause value to {green}IS NULL{/}" );
                        push( @list, $self->new_clause({
                            value => "$field IS NULL",
                            type => 'where',
                            })
                        );
                        next;
                    }
                    
                    my $f;
                    if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) )
                    {
                        $self->messagec( 5, "[process_where_condition] Field is a {green}DB::Object::Fields::Field{/} object, setting \$f to '%s'" );
                        $f = '%s';
                    }
                    else
                    {
                        $f = $prefix ? "$prefix.$field" : $field;
                        $self->messagec( 5, "[process_where_condition] Setting field \$f to {green}${f}{/}" );
                    }
                    
                    if( ref( $value ) eq 'SCALAR' )
                    {
                        $self->messagec( 5, "[process_where_condition] Value is a scalar reference, using it as is -> {green}", $$value, "{/}" );
                        push( @list, $self->new_clause({
                            value => $i_am_negative ? "$field != $$value" : "$field = $$value",
                            type => 'where' })
                        );
                    }
                    # If this is a sub-select - i.e.
                    # SELECT article, dealer, price
                    # FROM   shop
                    # WHERE  price=(SELECT MAX(price) FROM shop)
                    # By default we get the value and use it in our clause, but sub classes like DB::Object::Postgres::Query would use the statement as is to form a native sub-query
                    elsif( ref( $value ) eq "${base_class}::Statement" )
                    {
                        $self->messagec( 5, "[process_where_condition] Value is a {green}", "${base_class}::Statement", "{/} object, fetching its row value and creating a new clause." );
                        my $res = $value->fetchrow();
                        my $cl = $self->new_clause({
                            value => $i_am_negative ? "$f != '$res'" : "$f = '$res'",
                            generic => $i_am_negative ? "$f != ?" : "$f = ?",
                            type => 'where',
                        });
                        # $cl->bind->values( $res );
                        # $cl->bind->types( '' );
                        # $cl->fields( $field ) if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) );
                        $self->messagec( 5, "[process_where_condition] {green}", $value->query_object->elements->length, "{/} elements pushed from this statement object associated with this field {green}${field}{/} in WHERE clause." );
                        $cl->push( $value->query_object->elements );
                        push( @list, $cl );
                    }
                    elsif( ref( $value ) eq 'Regexp' )
                    {
                        $self->messagec( 5, "[process_where_condition] Value is a {green}Regexp{/}" );
                        # (?^:^want-(.*?)) => ^want-(.*?)
                        if( $value =~ s/^\(\?\^\:// )
                        {
                            $value =~ s/\)$//;
                        }
                        $self->messagec( 5, "[process_where_condition] Creating a new clause for {green}", $self->database_object->driver, "{/} as a regular expression." );
                        my $cl;
                        if( $self->database_object->driver eq 'Pg' )
                        {
                            $cl = $self->new_clause({
                                value => $i_am_negative ? "$f !~ '$value'" : "$f ~ '$value'",
                                generic => $i_am_negative ? "$f !~ ?" : "$f ~ ?",
                                type => 'where',
                            });
                        }
                        elsif( $self->database_object->driver eq 'SQLite' ||
                               $self->database_object->driver eq 'mysql' )
                        {
                            $cl = $self->new_clause({
                                value => $i_am_negative ? "$f NOT REGEXP('$value')" : "$f REGEXP('$value')",
                                generic => $i_am_negative ? "$f NOT REGEXP(?)" : "$f REGEXP(?)",
                                type => 'where',
                            });
                        }
                        # $cl->bind->values( $value );
                        # $cl->bind->types( '' );
                        $cl->push({
                            ( $self->_is_a( $field => 'DB::Object::Fields::Field' ) ? ( field => $field ) : () ),
                            value => $value,
                        });
                        # $cl->fields( $field ) if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) );
                        push( @list, $cl );
                    }
                    elsif( $value =~ /^($placeholder_re)$/ )
                    {
                        $self->messagec( 5, "[process_where_condition] Value is a placeholder {green}${1}{/}" );
                        my $plh = $1;
                        my $cl = $self->new_clause(
                            value => $i_am_negative ? "$f != $value" : "$f = $value",
                            type => 'where',
                        );
                        my $el = $self->new_element(
                            field       => $field, 
                            placeholder => $plh,
                        );
                        $cl->push( $el );
                        push( @list, $cl );
                    }
                    elsif( $value =~ /[\s\(\)\.\'\"]+(?:$fields)[\s\(\)\.\'\"]+/ ||
                           $value =~ /\w\([^\)]*\)/ )
                    {
                        $self->messagec( 5, "[process_where_condition] Value looks like a field name for this table." );
                        # Nothing fancy, as is. Even with binding option on, it will still return the clause without placeholder, because we don't know what $value is
                        my $cl = $self->new_clause(
                            value => $i_am_negative ? "$f != $value" : "$f = $value",
                            type => 'where',
                        );
                        # $cl->bind->types( '' ) if( $value =~ /^$placeholder_re$/ );
                        # $cl->fields( $field ) if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) );
                        if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) )
                        {
                            my $el = $self->new_element(
                                field => $field, 
                            );
                            $cl->push( $el );
                        }
                        push( @list, $cl );
                    }
                    else
                    {
                        my( $cl, $const, $el );
                        if( lc( $fields_type->{ $field } ) eq 'bytea' && ( $const = $self->database_object->get_sql_type( 'bytea' ) ) )
                        {
                            $self->messagec( 5, "[process_where_condition] Field {green}${field}{/} is of type 'bytea'" );
                            $cl = $self->new_clause(
                                value => "$f" . ( $i_am_negative ? '!=' : '=' ) . $tbl_o->database_object->quote( $value, $const ),
                                type => 'where',
                            );
                            $el = $self->new_element;
                        }
                        else
                        {
                            $self->messagec( 5, "[process_where_condition] Creating a new ", ( $i_am_negative ? 'negative ' : '' ), "clause for field {green}${field}{/}" );
                            $cl = $self->new_clause(
                                value => "$f" . ( $i_am_negative ? '!=' : '=' ) . $tbl_o->database_object->quote( $value ),
                                generic => $i_am_negative ? "$f != ?" : "$f = ?",
                                type => 'where',
                            );
                            # $cl->bind->values( $value );
                            $cl->push({
                                value => $value,
                            });
                            $el = $self->new_element( value => $value );
                        }
                        
                        $el->field( $field ) if( $self->_is_a( $field => 'DB::Object::Fields::Field' ) );
                        if( lc( $fields_type->{ $field } ) eq 'bytea' && 
                            ( $const = $self->database_object->get_sql_type( 'bytea' ) ) )
                        {
                            $el->type( $const );
                        }
                        # else
                        # {
                        #     $cl->bind->types( '' ) if( $value =~ /^$placeholder_re$/ );
                        # }
                        $cl->push( $el ) if( defined( $el ) );
                        CORE::push( @list, $cl );
                    }
                }
                $self->messagec( 5, "[process_where_condition] Setting the \$clause value to a merge of list {green}", join( "{/}, {green}", @list ), "{/}" );
                # End while @arg loop
                if( scalar( @list ) )
                {
                    $clause = $self->new_clause->merge( $tbl_o->database_object->$agg_op( @list ) );
                }
            }
            elsif( $data )
            {
#                 $self->_value2bind( \$data, \@binded ) if( $bind );
#                 $str = $data;
#                 @types = ( '' ) x scalar( @binded );
#                 $clause = $self->new_clause({
#                     value => $str,
#                     bind =>
#                     {
#                         values => \@binded,
#                         types => \@types,
#                     }
#                 });
                $self->messagec( 5, "[process_where_condition] Processing value {green}${data}{/}" );
                my $elems = $self->_value2bind( \$data );
                $clause = $self->new_clause(
                    value => $data,
                    type  => 'where',
                );
                $clause->push( $elems ) if( $elems->elements->length );
            }
            $self->messagec( 5, "[process_where_condition] Returning clause \$clause" );
            return( $clause );
        };
        $self->messagec( 4, "Calling private sub \$process_where_condition with {green}", scalar( @params ), "{/} arguments: '{green}", join( "{/}', '{green}", map( overload::StrVal( $_ ), @params ) ), "{/}'" );
        $where = $self->{ $prop } = $process_where_condition->( @params ) ||
            return( $self->pass_error );
        $self->messagec( 5, "A total of {green}", $where->length, "{/} elements found for this WHERE clause." );
        return( $where );
    }
    else
    {
        $where = $self->{ $prop };
    }
    
    if( !$where && want( 'OBJECT' ) )
    {
        return( $self->new_null( type => 'object' ) );
    }
    return( $where );
}

1;

# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Query - Query Object

=head1 SYNOPSIS

    my $q = DB::Object::Query->new;

=head1 VERSION

    v0.7.1

=head1 DESCRIPTION

This is the base class for this L<DB::Object> query formatter.

=head1 METHODS

=head2 alias

Sets or gets an hash of column name to alias.

=head2 as_string

Returns the formatted query as a string.

=head2 avoid

Takes a list or array reference of column to avoid in the next query. This returns a L<Module::Generic::Array> object.

=head2 binded

Takes a list or array reference of values to bind in the next query in L<DB::Object::Statement/execute>. This returns a L<Module::Generic::Array> object.

=head2 binded_group

This returns the values to bind for the C<group> clause of the query. This returns a L<Module::Generic::Array> object.

=head2 binded_limit

This returns the values to bind for the C<limit> clause of the query. This returns a L<Module::Generic::Array> object.

=head2 binded_order

This returns the values to bind for the C<order> clause of the query. This returns a L<Module::Generic::Array> object.

=head2 binded_types

Takes a list or array reference of value types to bind in the next query in L<DB::Object::Statement/execute>. This returns a L<Module::Generic::Array> object.

=head2 binded_types_as_param

This does nothing and must be implemented by the driver package. So, see L<DB::Object::Mysql::Query/binded_types_as_param>, L<DB::Object::Postgres::Query/binded_types_as_param>, and L<DB::Object::SQLite::Query/binded_types_as_param>

=head2 binded_values

Takes a list or array reference of values to bind in the next query in L<DB::Object::Statement/execute>. This returns a L<Module::Generic::Array> object.

=head2 binded_where

This returns the values to bind for the C<where> clause of the query. This returns a L<Module::Generic::Array> object.

=head2 constant

If any argument is provided, this expects an hash reference of constants to value pairs.

It returns the currently set constants as a hash reference.

=head2 database_object

Returns the current database object, which should be driver specific like L<DB::Object::Postgres>

=head2 delete

Takes some optional arguments used to define the C<where> clause, and this will prepare a C<DELETE> query.

It will refuse to prepare the query if no C<where> clause has been defined, as this would be a very unsafe query. You would need to execute such query yourself using L<DB::Object/do>.

If this method is called in void, this will execute the query.

It returns the newly created statement handler as a L<DB::Object::Statement>

=head2 elements

Sets or gets an L<DB::Object::Query::Elements> object. This object serves to contain all the elements used in creating SQL queries, keeping track of their order, value, dta types, placeholders used, etc.

=head2 enhance

Enable or disable enhancement mode.

=head2 final

Enables to know the query reached the end, so that when constant is used, all the processing can be skipped.

=head2 from_table

The table used, if any, in a C<FROM> clause.

=head2 format_statement

Provided with an hash or hash reference of parameters and this will format the sql statement for queries of types C<select>, C<delete> and C<insert>

In list context, it returns 2 strings: one comma-separated list of fields and one comma-separated list of values. In scalar context, it only returns a comma-separated string of fields.

Accepted parameters are:

=over 4

=item I<data>

=item I<order>

If not provided, this will use the default column order for this table.

=item I<table>

The table name to use, or, if not specified, this will be set to a value set with L<DB::Object::Tables/qualified_name>

=back

If any values were set by L</from_unixtime> or L</unix_timestamp>, the associated columns will be formatted accordingly in the sql statement.

It will go through each of the parameter passed to the original C<insert>, C<delete>, or C<select> query and if a column is one set earlier by L</from_unixtime> or L</unix_timestamp>, it will format it.

If a parameter provided is a L<DB::Object::Statement> it will stringify the query and add it surrounded by parenthesis.

If a parameter is actually a scalar reference, this means to us to use the underlying string as is.

If a parameter is C<?>, this will be treated as a placeholder.

If a parameter is a blob, it will be transformed into a parameter as a placeholder with its value saved to be bound in L<DB::Object::Statement/execute>

If L<DB::Object/bind> is not enabled, then the value provided with this parameter will be added after being possibly surrounded by quotes using L<DB::Object::Tables/quote>.

If the column type for this parameter is C<ENUM> and the query is of type C<INSERT> or C<UPDATE>, then the parameter value is surrounded with single quote.

If L<DB::Object/bind> is enabled, then a placeholder C<?> will be added and the parameter value will be saed to be passed during L<DB::Object::Statement/execute>

If nothing else matches it will add the value, possible quoted, using L<DB::Object::Tables/quote>, whose implementation can be driver specific.

If column prefix is required, then the necessary prefix will be prepended to columns.

In list context, this returns the formatted columns and their values, and in scalar context it will returns only the formatted columns.

=head2 format_update

Provided with a list of parameters either as a key-value pairs, as an hash reference or even as an array reference and this will format update query based on the following arguments provided:

=over 4

=item I<data>

An array of key-value pairs to be used in the update query. This array can be provided as the prime argument as a reference to an array, an array, or as the I<data> element of a hash or a reference to a hash provided.

Why an array if eventually we build a list of key-value pair? Because the order of the fields may be important, and if the key-value pair list is provided, B<format_update> honors the order in which the fields are provided.

=back

If no data is provided, this will return an error.

L</format_update> will then iterate through each field-value pair, and perform some work:

If the field being reviewed was provided to L</from_unixtime>, then L</format_update> will enclose it in the function suitable for the driver to convert it into a database datetime. For example, for Mysql, this would be:

    FROM_UNIXTIME(field_name)
  
If the the given value is a reference to a scalar, it will be used as-is, ie. it will not be enclosed in quotes or anything. This is useful if you want to control which function to use around that field.

If the value is C<?> it will be used as a placeholder and the value will be saved to be bound later in L<DB::Object::Statement/execute>. Its associated type will be added as blank, so it can be guessed later. However, if the column data type is C<bytea>, the the PostgreSQL data type C<DBD::Pg::PG_BYTEA> will be used when binding the value.

If the column type is C<jsonb>, and the value is an hash reference, it will be json encoded and used instead.

If the given value is another field or looks like a function having parenthesis, or if the value is a question mark, the value will be used as-is.

If L<DB::Object/bind> is off, the value will be escaped and the pair field='value' created.

If the field is a SET data type and the value is a number, the value will be used as-is without surrounding single quote.

If L<DB::Object/bind> is enabled, a question mark will be used as the value and the original value will be saved as value to bind upon executing the query.

Finally, otherwise the value is escaped and surrounded by single quotes.

L</format_update> returns a regular string representing the comma-separated list of columns with their value assigment that will be used.

=head2 from_unixtime

Takes a list or array reference of columns that needs to be treated as unix timestamp and will be converted into a database timestamp.

It returns that list as a L<Module::Generic::Array>

=head2 format_from_epoch

This is the driver specific implementation to convert unix timestamp to the database timestamp.

This is superseded in driver specific implementation, so see L<DB::Object::Mysql::Query/format_from_epoch>, L<DB::Object::Postgres::Query/format_from_epoch> and L<DB::Object::SQLite:::Query/format_from_epoch>

=head2 format_to_epoch

This is the driver specific implementation to convert the database timestamp to unix timestamp.

This is superseded in driver specific implementation, so see L<DB::Object::Mysql::Query/format_from_epoch>, L<DB::Object::Postgres::Query/format_from_epoch> and L<DB::Object::SQLite:::Query/format_from_epoch>

=head2 getdefault

Provided with an hash or hash reference of parameters and this will do some preparation work.

Possible parameters are:

=over 4

=item I<arg>

An array reference of data which should be a key-value pairs.

=item I<as>

An hash reference of column to alias pairs. Alternatively, if this is not provided, the value set with L</alias> will be used.

=item I<avoid>

An array reference of column to avoid using. Alternatively, if this is not provided, the value set with L</avoid> will be used.

=item I<from_unixtime>

An array reference of columns to be converted from unix timestamp to the database timestamp.

=item I<query_type>

The type of query, such as C<delete>, C<insert>, C<replace>, C<select>, C<update>

=item I<table>

The table name.

=item I<time>

A unix timestamp. Alternatively, I<unixtime> can be used.

=item I<unix_timestamp>

An array reference of columns to be converted into unix timestamp.

=back

Does some preparation work such as :

=over 4

=item 1

the date/time field to use the FROM_UNIXTIME and UNIX_TIMESTAMP functions

=item 2

removing from the query the fields to avoid, ie the ones set with the B<avoid> method.

=item 3

set the fields alias based on the information provided with the B<alias> method.

=item 4

if a field last_name and first_name exist, it will also create an alias I<name> based on the concatenation of the 2.

=item 5

it will set the default values provided. This is used for UPDATE queries.

=back

It sets the following properties of the current object:

=over 4

=item I<bind>

A boolean value whether the use of placeholder is enabled.

=item I<query_type>

The type of query, such as C<select>, C<insert>, etc...

=item I<_args>

The arguments provided as an array reference.

=item I<_default>

The default value as an hash reference.

=item I<_extra>

Extra parameters as an array reference.

=item I<_fields>

The columns as an hash reference.

=item I<_from_unix>

An hash reference

=item I<_structure>

The table structure which is an hash reference of column name to definition pairs.

=item I<_to_unix>

An hash reference

=back

It returns a new L<DB::Object::Tables> object with all the data prepared within.

=head2 group

Format the C<group by> portion of the query by calling L</_group_order>

It returns a new L<DB::Object::Query::Clause> object.

=head2 having

This must be superseded by driver specific implementation of this class. Check out L<DB::Object::Mysql::Query/having>, L<DB::Object::Postgres::Query/having>, L<DB::Object::SQLite::Query/having>

=head2 insert

    $tbl->insert( col1 => $val1, col2 => $val 2 );
    # or
    $other_tbl->where( user => 'joe' );
    my $sth = $other_tbl->select;
    $tbl->insert( $sth );
    # will become INSERT INTO some_table SELECT col1, col2 FROM other_table WHERE user = 'joe'

Provided with an array reference or an hash reference or a statement object (L<DB::Object::Statement>) or a list of parameters and this will prepares an C<insert> query using the field-value pairs provided.

If a L<DB::Object::Statement> object is provided as first argument, it will be considered as a SELECT query to be used in the INSERT query, as in: INSERT INTO my table SELECT FROM another_table

Otherwise, L</insert> will build the query based on the fields provided.

In void context, it will execute the query by calling of L<DB::Object::Statement/execute>.

It returns the statement object.

=head2 is_upsert

Sets or gets the boolean value if the query is an C<upsert>, which means a C<insert> or C<update> query that uses an C<ON CONFLICT> clause. See L<DB::Object::Postgres::Query/on_conflict>

=head2 join_fields

Sets or gets the join fields. This is a regular string.

=head2 join_tables

Sets or gets the table joined. This returns a L<Module::Generic::Array>

=head2 left_join

Sets or gets an hash reference of column joint column pairs

=head2 limit

Set or get the limit for the future statement, by calling L</_process_limit>

It returns a L<DB::Object::Query::Clause> representing the C<limit> clause.

=head2 local

Provided with a variable name and value pairs and this will set them.

It returns the formated declaration as a string.

=head2 new_clause

This returns a new L<DB::Object::Query::Clause> object.

=head2 new_element

Instantiate a new L<DB::Object::Query::Element> object, passing it whatever arguments were provided and sharing wit it the value of the L</debug> flag.

=head2 new_elements

Instantiate a new L<DB::Object::Query::Elements> object, passing it whatever arguments were provided and sharing wit it the value of the L</debug> flag.

=head2 order

Provided with a list of parameter and this will format the C<order> clause by calling L</_group_order>

It returns a new L<DB::Object::Query::Clause> object.

=head2 prepare_options

Sets or gets the options that will be used in L<DB::Object/_cache_this>, which is taked with preparing statement when they are not already cached.

This method basically handles an hash reference of properties set by L<DB::Object::Query> and their inheriting packages. Currently only PostgreSQL makes use of this with L<DB::Object::Postgres::Query/dollar_placeholder> and L<DB::Object::Postgres::Query/server_prepare>

=head2 query

Sets or gets the query string. It returns whatever is set as a regular string.

=head2 query_reset

Reset the query object to its nominal value so it can be re-used.

=head2 query_reset_core_keys

Returns an L<Module::Generic::Array> object of core object properties shared with inheriting package.

Those are used to know what properties to reset.

=head2 query_reset_keys

Returns an L<Module::Generic::Array> object of object properties shared with inheriting package.

This contains driver specific properties and together with the ones provided with L</query_reset_core_keys>, they form a whole.

=head2 query_type

Sets or gets the query type, such as C<delete>, C<insert>, C<select>, C<update>, etc.

=head2 query_values

Sets or gets the query values.

Returns a L<scalar object|Module::Generic::Scalar>

=head2 replace

This is unsupported by default and its implementation is driver specific.

=head2 reset

Reset the query object.

What it does is remove the following object properties: alias local binded binded_group binded_limit binded_order binded_types binded_values binded_where where limit group_by order_by reverse from_unixtime unix_timestamp sorted

=head2 reset_bind

Reset the bind values by setting the following object property to an empty anonymous array: binded binded_group binded_limit binded_order binded_types binded_where

=head2 returning

This is unsupported by default and its implementation is driver specific.

=head2 reverse

Mark the query to use reverse order. This is used by L</order>.

=head2 select

Provided with a list or an array reference of columns, and this will format the C<select> statement.

If the parameters provided is actually a scalar reference, it will be used as is.

If the parameters provided is an array or array reference, it will be joined using comma to get the list of columns to get, or, if the array is empty, the special C<*> will be used to get all the columns.

Otherwise, it will use the data parameter provided as is.

If any alias have been set using L</alias>, they will be added to the list of columns to get.

if a table alias was set using L</table_alias> it will be set here.

If the method was called in void context, it will execute immediately the statement object prepared.

It returns the statement object (DB::Object::Statement).

=head2 selected_fields

Sets or gets the string representing the list of columns used in previous C<select> statement.

Returns a regular string.

=head2 sort

Set the query to use normal sorting order.

=head2 sorted

Sets or gets the list of sorted columns used in statements. This returns a L<Module::Generic::Array> object.

=head2 table_alias

Sets an optional alias for this table to be used in statement.

This method should be called by L<DB::Object::Tables/as>. If you change this directly, you risk facing some discrepancies between the actual table alias and the one set here.

Returns the current value.

=head2 table_object

Sets or gets the table object. This will return a L<DB::Object::Tables> object

=head2 tie

If provided a hash or a hash ref, it sets the list of fields and their corresponding perl variable to bind their values to.

In list context, it returns the list of those field-variable pair, or a reference to it in scalar context.

=head2 unix_timestamp

Provided a list or an array reference of columns, and this sets the columns to be treated for seamless conversion from and to unix time.

It returns a L<Module::Generic::Array> object.

=head2 update

Provided with a list, an array reference, or an hash or hash reference of key-value pairs and this will format the update statement.

If no parameter is provided, this will return an error.

This will call L</format_update> to format the parameter provided and use the resulting string in the C<update> statement.

If any clauses have been defined such as C<where>, C<limit>, etc, they will be properly formatted and added to the statement.

The resulting formatted query will be saved as the object property L</query>.

The formatted update columns and values will be saved in the current object property L</query_values>

If L</update> is called in void context, this will execute the query immediately.

It returns the statement object (L<DB::Object::Statement>).

=head2 where

Build the where clause based on the field-value hash provided by calling L</_where_having>.

It returns a clause object (L<DB::Object::Query::Clause>).

=head2 _group_order

This support method is called by L</group> and L</order> to format those clauses.

Provided with an object, or a list or an array reference of parameters and this will format the relevant clause.

it will go through each parameter and if the parameter provided is an L<DB::Object::Fields::Field> object, it will collect its various attribute.

If the parameter is a scalar reference, it will be used as is.

If the parameter looks like it contains some field, it will be prepended by an appropriate prefix of table and possible database and schema name, if necessary.

Otherwise, it will use whatever value was provided as a column and use it.

It returns a L<DB::Object::Query::Clause> object.

=head2 _having

This is called by L</where> and L</having>

Provided with some data as a list or an array reference and this will format the C<where> or C<having> clause.

Walking through each parameter provided, if a parameter is a scalar reference, it will be used as is.

If the parameter looks like it contains some field, it will be prepended by an appropriate prefix of table and possible database and schema name, if necessary.

If L<DB::Object/bind> is enabled, it will save the value used and use a placeholder.

It returns a L<DB::Object::Query::Clause> object.

=head2 _initiate_clause_object

This instantiate a new L<DB::Object::Query::Clause> object passing it whatever parameters were provided.

=head2 _limit

Sets or gets the limit clause object and returns a L<DB::Object::Query::Clause> object.

=head2 _process_limit

Provided with some parameters and this will format the C<limit> clause of the query.

If one parameter was provided, then this will only define the ending limit. The start will be set as L<perlfunc/undef>

If two parameters are provided, then this will set the start offset and the limit.

It check each of the start offset and end limit thus set, and if it is a scalar reference, it will be used as is. However, if the parameter is a C<?> it will be used as a placeholder.

Otherwise, if L<DB::Object/bind> is enabled, this will save the parameter value as a binded value to be passed to L<DN::Object::Statement/execute>

It returns the C<limit> clause object (DB::Object::Query::Clause)

=head2 _query_components

This returns an array reference of formatted clause, in their proper order to be added to query.

This method is called by L</delete>, L</insert>, L</replace>, L</select> and L</update>

This method is overriden by driver packages, so check L<DB::Object::Mysql::Query/_query_components>, L<DB::Object::Postgres::Query/_query_components> and L<DB::Object::SQLite::Query/_query_components>

=head2 _query_type

Based on the latest formatted query and the object property L</query>, this will return the type of query this is. This can be possibly one of the following: C<alter>, C<create>, C<drop>, C<grant>, C<listen>, C<notify>, C<insert>, C<update>, C<delete>, C<select>, C<truncate>

=head2 _save_bind

Provided with a query type and this will collect binded values from various clauses.

It returns the current object.

=head2 _value2bind

If L<DB::Object/use_bind> is enabled, and this will modify the query passed to replace value with placeholders.

Actually this method is not used anymore and really qui dangerous because parsing sql is quite challenging.

=head2 _where_having

This is used to format C<WHERE> and C<HAVING> clause.

Provided with a query type and clause property name such as C<having> or C<where> and other parameters and this will format the C<where> or C<having> clause and return a new L<DB::Object::Query::Clause> object.

It checks each parameter passed.

if the first parameter is a L<DB::Object::Operator> object, it will take it embedded values by calling L<DB::Object::Query::Clause/value>. However, if there are any unknown fields, they will be ignored.

If the parameter is a scalar reference, it will use it as is.

If the parameter is a L<DB::Object::Operator> object like L<DB::Object::AND>, L<DB::Object::OR> or L<DB::Object::NOT>, it will recursively process its embedded elements.

If the parameter is a L<DB::Object::Query::Clause> object, it will be added to the stack of elements.

If the parameter is a L<DB::Object::Expression> object, it will be added to the stack of elements.

If the parameter is a L<DB::Object::Fields::Overloaded> object, it will be added as a new L<DB::Object::Query::Clause> to the stack.

If the parameter is a litteral represented as a string or a scalar reference, then it will be added to the list as-is. For example:

    $tbl->where(
        $tbl->fo->status eq 'active',
        "LENGTH(?) > 12"
    );

or

    $tbl->where(
        $tbl->fo->status eq 'active',
        \"LENGTH(?) > 12"
    );

However, make sure to put this expression at the end.

It then checks parameters two by two, the first one being the column and the second being its value.

If the value is the operator object L<DB::Object::NOT>, it adds to the stack a new clause object of type C<column IS NOT something>, such as C<column IS NOT NULL>

if the value is undefined or that the value is equal to C<NULL>, then it adds to the stack a new clause object L<DB::Object::Query::Clause> of type C<column IS NULL>

If the value is a scalar reference, it will be added as is in a new clause object that is added to the stack.

If the value is a L<DB::Object::Statement>, L<DB::Object::Statement/fetchrow> will be called and the value fetched will be added as a new clause object to the stack.

If the value is a perl Regexp object, then it will be formatted in a way suitable to the driver and added to a new clause object and onto the stack.

If the value looks like some table field embedded inside some SQL function, then it will be added to a new clause object and onto the stack.

See L<Postgres documentation for more information|https://www.postgresql.org/docs/9.5/functions-matching.html>

See L<MySQL documentation for more information|https://dev.mysql.com/doc/refman/5.7/en/regexp.html>

See L<SQLite documentation for more information|https://sqlite.org/lang_expr.html>

If the column is of type C<bytea>, then a new clause object will be added to the stack with the column value being quoted properly using L<DB::Object/quote>

All the clause objects in the stack will be merged into one new clause object using L<DB::Object::Query::Clause/merge>

The resulting final clause object (L<DB::Object::Query::Clause>) is returned.

=head1 AUTOLOAD

When the C<AUTOLOAD> is called, it will check if the value of the method used corresponds to an existing database table, and if it does, it returns the value returned by calling L</table> with the table name.

=head1 SEE ALSO

L<DBI>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
