# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Query.pm
## Version v0.4.6
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2021/08/20
## All rights reserved
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
    use Scalar::Util ();
    use Devel::Confess;
    our( $VERSION, $DEBUG, $VERBOSE );
    $VERSION = 'v0.4.6';
    $DEBUG = 0;
    $VERBOSE = 0;
};

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
    $self->{enhance}        = 0 unless( CORE::exists( $self->{enhance} ) );
    $self->{from_table}     = [] unless( CORE::exists( $self->{from_table} ) );
    $self->{from_unixtime}  = [] unless( CORE::exists( $self->{from_unixtime} ) );
    $self->{group_by}       = '' unless( CORE::exists( $self->{group_by} ) );
    $self->{join_fields}    = '' unless( CORE::exists( $self->{join_fields} ) );
    $self->{left_join}      = {} unless( CORE::exists( $self->{left_join} ) );
    $self->{limit}          = [] unless( CORE::exists( $self->{limit} ) );
    $self->{local}          = {} unless( CORE::exists( $self->{local} ) );
    $self->{order_by}       = '' unless( CORE::exists( $self->{order_by} ) );
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
    return( $self );
}

sub alias { return( shift->_set_get_hash( 'alias', @_ ) ); }

sub as_string { return( shift->{query} ); }

sub avoid { return( shift->_set_get_array_as_object( 'avoid', @_ ) ); }

sub binded { return( shift->_set_get_array_as_object( 'binded', @_ ) ); }

sub binded_group { return( shift->group->bind->values ); }

sub binded_limit { return( shift->limit->bind->values ); }

sub binded_order { return( shift->order->bind->values ); }

sub binded_types { return( shift->_set_get_array_as_object( 'binded_types', @_ ) ); }

sub binded_types_as_param
{
    my $self = shift( @_ );
    return( $self->error( "The driver has not implemented th emethod binded_types_as_param." ) );
}

sub binded_values { return( shift->_set_get_array_as_object( 'binded_values', @_ ) ); }

sub binded_where { return( shift->_set_get_array_as_object( 'binded_where', @_ ) ); }

sub constant
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $def = shift( @_ );
        ## $self->message( 3, "Called with hash reference: ", sub{ $self->dumper( $def, { depth => 1 } ) } );
        return( $self->error( "I was expecting a hash reference, but got '$def' instead." ) ) if( !$self->_is_hash( $def ) );
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

sub database_object { return( shift->table_object->database_object ) }

sub delete
{
    my $self  = shift( @_ );
    my $constant = $self->constant;
    if( scalar( keys( %$constant ) ) )
    {
        ## $self->message( 3, "Found constant data: ", sub{ $self->dumper( $constant, { depth => 1 } ) } );
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table = $tbl_o->name ||
    return( $self->error( "No table to delete entries from was set." ) );
    my $where = '';
    $self->where( @_ ) if( @_ );
    ## if( !$where && $self->{ 'query_reset' } )
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
    ## 'query_reset' condition to avoid catching parameters from pervious queries.
    push( @query, @$clauses ) if( scalar( @$clauses ) );
    my $query = $self->{ 'query' } = CORE::join( ' ', @query );
    return( $self->error( "Refusing to do a bulk delete. Enable the allow_bulk_delete database object property if you want to do so. Original query was: $query" ) ) if( !$self->where && !$self->database_object->allow_bulk_delete );
    $self->_save_bind();
    my $sth = $tbl_o->_cache_this( $self ) ||
    return( $self->error( "Error while preparing query to delete from table '$table':\n$query" ) );
    ## Routines such as as_string() expect an array on pupose so we do not have to commit the action
    ## but rather get the statement string. At the end, we write:
    ## $obj->delete() to really delete
    ## $obj->delete->as_string() to ONLY get the formatted statement
    ## wantarray returns undef in void context, i.e. $obj->delete()
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to delete from table '$table':\n$query" ) );
        ## Will be destroyed anyway and permits the end user to manipulate the object if needed
        ## $sth->finish();
    }
    ## wantarray returns false but not undef() otherwise, i.e.
    ## $obj->delete->as_string();
    return( $sth );
}

sub enhance { return( shift->_set_get_boolean( 'enhance', @_ ) ); }

## Used in conjonction with constant(), allows internally to know if the query has reached the end of the chain
## Such as $tbl->select->join( $tbl_object, $conditions )->join( $other_tbl_object, $other_conditions );
## final() enables to know the query reached the end, so that when constant is used, all the processing can be skipped
sub final { return( shift->_set_get_scalar( 'final', @_ ) ); }

sub format_from_epoch
{
    warn( "This method \"format_from_epoch\" was not superseded.\n" );
}

sub format_to_epoch
{
    warn( "This method \"format_to_epoch\" was not superseded.\n" );
}

# For select or insert queries
sub format_statement
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    # Should we use bind statement?
    my $bind   = $tbl_o->database_object->use_bind;
    $self->message( 3, "Formatting statement with table '", $tbl_o->name, "' object '$tbl_o' and bind value '$bind'." );
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
    $self->message( 3, "Saved arguments are: '", sub{ join( "', '", @$args ) }, "'." );
    $from_unix = $self->{_from_unix};
    my $tmp_ref = $self->from_unixtime();
    map{ $from_unix->{ $_ }++ } @$tmp_ref;
    $tmp_ref = $self->unix_timestamp();
    map{ $unixtime->{ $_ }++ } @$tmp_ref;
    # $self->message( 3, "Fields found are: ", sub{ $self->printer( $order ) } );
    my @format_fields = ();
    my @format_values = ();
    my $binded   = $self->{binded_values} = [];
    my $multi_db = $tbl_o->prefix_database;
    my $db       = $tbl_o->database;
    my $fields_ref = $tbl_o->fields();
    ## $self->message( 3, "Other fields found are: ", sub{ $self->printer( $fields_ref ) } );
    my $ok_list  = CORE::join( '|', keys( %$fields_ref ) );
    my $tables   = CORE::join( '|', @{$tbl_o->database_object->tables} );
    my $struct   = $tbl_o->structure();
    my $query_type = $self->{query_type};
    # $self->message( 3, "Fields order is: ", sub{ $self->dumper( $order ) } );
    my @sorted   = ();
    if( @$args && !( @$args % 2 ) )
    {
        for( my $i = 0; $i < @$args; $i++ )
        {
            push( @sorted, $args->[ $i ] ) if( exists( $order->{ $args->[ $i ] } ) );
            $i++;
        }
    }
    @sorted = sort{ $order->{ $a } <=> $order->{ $b } } keys( %$order ) if( !@sorted );
    $self->message( 3, "Sorted fields are: '", sub{ join( "', '", @sorted ) }, "'." );
    # Used for insert or update so that execute can take a hash of key => value pair and we would bind the values in the right order
    # But or that we need to know the order of the fields.
    $self->{sorted} = \@sorted;
    
    foreach( @sorted )
    {
        # next if( $struct->{ $_ } =~ /\b(AUTO_INCREMENT|SERIAL)\b/i );
        if( exists( $data->{ $_ } ) )
        {
            my $value = $data->{ $_ };
            if( Scalar::Util::blessed( $value ) && $value->isa( "${base_class}::Statement" ) )
            {
                push( @format_values, '(' . $value->as_string . ')' );
            }
            # This is for insert or update statement types
            elsif( exists( $from_unix->{ $_ } ) )
            {
                if( $bind )
                {
                    push( @$binded, $value );
                    $self->binded_types->push( '' );
                    push( @format_values, $self->format_from_epoch({ value => $value, bind => 1 }) );
                }
                else
                {
                    push( @format_values, $self->format_from_epoch({ value => $value, bind => 0 }) );
                }
            }
            elsif( exists( $unixtime->{ $_ } ) )
            {
                if( $bind )
                {
                    push( @$binded, $value );
                    $self->binded_types->push( '' );
                    push( @format_values, $self->format_to_epoch({ value => $value, bind => 1 }) );
                }
                else
                {
                    push( @format_values, $self->format_to_epoch({ value => $value, bind => 0 }) );
                }
            }
            elsif( ref( $value ) eq 'SCALAR' )
            {
                push( @format_values, $$value );
            }
            elsif( $value eq '?' )
            {
                push( @format_values, '?' );
                $self->binded_types->push( '' );
            }
            elsif( $struct->{ $_ } =~ /^\s*\bBLOB\b/i )
            {
                push( @format_values, '?' );
                push( @$binded, $value );
                $self->binded_types->push( '' );
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
                ## push( @format_values, sprintf( "'%s'", quotemeta( $value ) ) );
                push( @format_values, sprintf( "%s", $tbl_o->database_object->quote( $value ) ) );
            }
            # We do this before testing for param binding because DBI puts quotes around SET number :-(
            elsif( $value =~ /^\d+$/ && $struct->{ $_ } =~ /\bSET\(/i )
            {
                push( @format_values, $value );
            }
            elsif( $value =~ /^\d+$/ && 
                   $struct->{ $_ } =~ /\bENUM\(/i && 
                      ( $query_type eq 'insert' || $query_type eq 'update' ) )
            {
                push( @format_values, "'$value'" );
            }
            # Otherwise, bind option is enabled, we bind parameter
            elsif( $bind )
            {
                push( @format_values, '?' );
                push( @$binded, $value );
                $self->binded_types->push( '' );
            }
            # In last resort, we handle the formatting ourself
            else
            {
                # push( @format_values, "'" . quotemeta( $value ) . "'" );
                push( @format_values, $tbl_o->database_object->quote( $value ) );
            }
        }
    
        if( $prefix ) 
        {
            s{
                (?<!\.)\b($ok_list)\b(\s*)?(?!\.)
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
            push( @format_fields, $_ );
        }
        else
        {
            push( @format_fields, $_ );
        }
    }
    if( !wantarray() && scalar( @{$self->{ '_extra' }} ) )
    {
        push( @format_fields, @{$self->{ '_extra' }} );
    }
    $values = CORE::join( ', ', @format_values );
    $fields = CORE::join( ', ', @format_fields );
    wantarray ? return( $fields, $values ) : return( $fields );
}

sub format_update($;%)
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( $self->_is_array( $_[0] ) || $self->_is_hash( $_[0] ) || @_ % 2 );
    my @arg  = @_;
    if( !@arg && $data )
    {
        if( $self->_is_hash( $data ) )
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
    $arg{ 'default' } ||= $self->{ '_default' };
    if( $arg{data} && !$data )
    {
        my $hash = $arg{data};
        my @vals = %$hash;
        $data    = \@vals;
    }
    elsif( $self->_is_hash( $data ) )
    {
        my @vals = %$data;
        $data    = \@vals;
    }
    my $info = $data || \@arg;
    ## if( !%$info || !scalar( keys( %$info ) ) )
    if( !$info || !scalar( @$info ) )
    {
        return( $self->error( "No data to update was provided to format update." ) );
    }
    my $bind   = $tbl_o->database_object->use_bind;
    my $def    = $arg{default} || $self->{ '_default' };
    my $fields_ref = $tbl_o->fields();
    my $fields_list = CORE::join( '|', keys( %$fields_ref ) );
    my $struct = $tbl_o->structure();
    my $types  = $tbl_o->types;
    my $from_unix = $self->from_unixtime();
    my $from_unixtime = { map{ $_ => 1 } @$from_unix };
    my @fields = ();
    my @binded = ();
    my @types  = ();
    ## Before we used to call getdefault supplying it our new values and the
    ## format_statement() that would take the default supplied values
    ## Now, this works differently since we use update() method and supply 
    ## directly our value to update to it
    ## In this context, getting the default values is dangerous, since resetting
    ## the values to their default ones is not was we want, is it?
    #foreach my $field ( keys( %$def ) )
    #{
    #    if( exists( $info->{ $field } ) )
    #{
    #    $def->{ $field } = $info->{ $field };
    #}
    #}
    my( $field, $value );
    while( @$info )
    {
        my( $field, $value ) = ( shift( @$info ), shift( @$info ) );
        ## $self->message( 3, "Checking field '$field' with type '", $types->{ $field }, "'." );
        ## Do not update a field that does not belong in this table
        next if( !exists( $fields_ref->{ $field } ) );
        ## Make it a FROM_UNIXTIME field if this is what we need.
        ## $value = "FROM_UNIXTIME($value)" if( exists( $from_unixtime->{ $field } ) );
        # $value = \"TO_TIMESTAMP($value)" if( exists( $from_unixtime->{ $field } ) );
        ## This is for insert or update statement types
        if( exists( $from_unixtime->{ $field } ) )
        {
            ## push( @format_values, sprintf( "FROM_UNIXTIME('%s') AS $_", $data->{ $_ } ) );
            if( $bind )
            {
                push( @$binded, $value );
                # push( @format_values, "FROM_UNIXTIME( ? )" );
                push( @fields, "$field=" . $self->format_from_epoch({ value => $value, bind => 1 }) );
            }
            else
            {
                ## push( @format_values, "FROM_UNIXTIME($value)" );
                push( @fields, "$field=" . $self->format_from_epoch({ value => $value, bind => 0 }) );
            }
        }
        elsif( ref( $value ) eq 'SCALAR' )
        {
            push( @fields, "$field=$$value" );
        }
        ## Maybe $bind is not enabled, but the user may have manually provided a placeholder, i.e. '?'
        elsif( !$bind )
        {
            ## push( @fields, sprintf( "$field='%s'", quotemeta( $value ) ) );
            if( $value eq '?' )
            {
                push( @fields, "$field = ?" );
                if( lc( $types->{ $field } ) eq 'bytea' )
                {
                    ## $self->message( 3, "Field '$field' is of type bytea, adding special type '", DBD::Pg::PG_BYTEA, "'." );
                    CORE::push( @types, DBD::Pg::PG_BYTEA );
                }
                else
                {
                    ## $self->message( 3, "Field '$field' has a regular type. No special type attribute is required." );
                    CORE::push( @types, '' );
                }
            }
            elsif( lc( $types->{ $field } ) eq 'bytea' )
            {
                ## $self->message( 3, "Field '$field' is of type bytea, adding special type '", DBD::Pg::PG_BYTEA, "'." );
                push( @fields, sprintf( "$field=%s", $tbl_o->database_object->quote( $value, DBD::Pg::PG_BYTEA ) ) );
            }
            elsif( $self->_is_hash( $value ) && ( lc( $types->{ $field } ) eq 'jsonb' || lc( $types->{ $field } ) eq 'json' ) )
            {
                my $this_json = $self->_encode_json( $value );
                push( @fields, sprintf( "$field=%s", $tbl_o->database_object->quote( $this_json, ( lc( $types->{ $field } ) eq 'jsonb' ? DBD::Pg::PG_JSONB : BDD::Pg::PG_JSON ) ) ) );
            }
            else
            {
                ## $self->message( 3, "Field '$field' has a regular type. No special type attribute is required." );
                push( @fields, sprintf( "$field=%s", $tbl_o->database_object->quote( $value ) ) );
            }
        }
        ## if this is a SET field type and value is a number, treat it as a number and not as a string
        ## We do this before testing for param binding because DBI puts quotes around SET number :-(
        elsif( $value =~ /^\d+$/ && $struct->{ $field } =~ /\bSET\(/i )
        {
            push( @fields, "$field=$value" );
        }
        elsif( $bind )
        {
            ## $self->message( 3, "Bind is required for field '$field'." );
            push( @fields, "$field=?" );
            push( @binded, $value );
            if( lc( $types->{ $field } ) eq 'bytea' )
            {
                ## $self->message( 3, "Field '$field' is of type bytea, adding special type '", DBD::Pg::PG_BYTEA, "'." );
                CORE::push( @types, DBD::Pg::PG_BYTEA );
            }
            else
            {
                ## $self->message( 3, "Field '$field' has a regular type. No special type attribute is required." );
                CORE::push( @types, '' );
            }
        }
        else
        {
            ## $value = "'" . quotemeta( $value ) . "'";
            ## push( @fields, "$field='" . quotemeta( $value ) . "'" );
            if( lc( $types->{ $field } ) eq 'bytea' )
            {
                ## $self->message( 3, "Field '$field' is of type bytea, adding special type '", DBD::Pg::PG_BYTEA, "'." );
                push( @fields, "$field=" . $tbl_o->database_object->quote( $value, DBD::Pg::PG_BYTEA ) );
            }
            else
            {
                ## $self->message( 3, "Field '$field' has a regular type. No special type attribute is required." );
                push( @fields, "$field=" . $tbl_o->database_object->quote( $value ) );
            }
        }
    }
    $self->{binded_values} = [ @binded ];
    # $self->messagef( 3, "%d field types set: %s", scalar( @types ), sub{ $self->dumper( \@types ) } );
    $self->messagef( 3, "Adding %d types to the overall %d binded types.", scalar( @types ), $self->binded_types->length );
    $self->binded_types->push( @types ) if( scalar( @types ) );
    ## $self->message( 3, "Binded types are: ", sub{ $self->dumper( $self->{binded_types} ) } );
    return( CORE::join( ', ', @fields ) );
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
    my %default   = ();
    my %fields    = ();
    my %structure = ();
    my $base_class = $self->base_class;
    ## Contains some extra parameters for SELECT queries only
    ## Right now a concatenation of 'last_name' and 'first_name' fields into field named 'name'
    my @extra      = ();
    %arg = @$arg if( scalar( @$arg ) );
    $opts->{table} = lc( $opts->{table} );
    $opts->{time} = time() if( !defined( $opts->{time} ) );
    my $time        = '';
    $time           = $opts->{time} if( $opts->{time} =~ /^\d+$/ );
    $time         ||= $opts->{unixtime} || time();
    my $query_type  = $opts->{query_type};
    if( !$query_type )
    {
        my( $pkg, $file, $line, $sub ) = caller( 1 );
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
    my $unix_time   = $opts->{unix_timestamp} || $self->unix_timestamp();
    my $from_unix   = $opts->{from_unixtime} || $self->from_unixtime();
    ## $self->message( 3, "\$avoid contains: ", sub{ $self->dumper( $avoid ) } );

    my $enhance     = $tbl_o->enhance;
    ## my $table_name  = $table;
    ## $self->message( 3, "Using table '$table'." );
    ## Need to do hard copy of hashes
    %default   = $tbl_o->default();
    %fields    = $tbl_o->fields();
    %structure = $tbl_o->structure();
    ## $self->message( 3, "Fields found for table '$table' is:\n", $self->printer( \%fields ) );
    
    if( !%default || !%fields )
    {
        return( $self->error( "No proper configuration file found for table \"$table\"." ) );
    }
    
    if( $query_type eq 'select' && $enhance )
    {
        ## $self->message( 3, "Enhancing the select query with fields data: ", $self->dumper( \%fields ) );
        my @sorted = sort{ $fields{ $a } <=> $fields{ $b } } keys( %fields );
        ## foreach my $field ( keys( %structure ) )
        foreach my $field ( @sorted )
        {
            if( $structure{ $field } =~ /^\s*(?:DATE(?:TIME)?|TIMESTAMP)\s*/i )
            {
                ## $fields{ "UNIX_TIMESTAMP( $field ) AS ${field}_unixtime" } = scalar( keys( %fields ) ) + 1;
                ## $fields{ "${field}::ABSTIME::INTEGER AS ${field}_unixtime" } = scalar( keys( %fields ) ) + 1;
                my $f = $self->format_to_epoch({
                    value => ( $prefix ? "${prefix}.${field}" : $field ),
                    bind => 0,
                    quote => 0,
                });
                ## $fields{ "EXTRACT( EPOCH FROM $f ) AS ${field}_unixtime" } = scalar( keys( %fields ) ) + 1;
                $fields{ "$f AS ${field}_unixtime" } = scalar( keys( %fields ) ) + 1;
            }
        }
    }
    
    my %to_unixtime = ();
    if( $self->_is_array( $unix_time ) )
    {
        %to_unixtime = map{ $_ => 1 } @$unix_time;
    }
    elsif( $self->_is_hash( $unix_time ) )
    {
        %to_unixtime = %$unix_time;
    }
    
    if( %to_unixtime && scalar( keys( %to_unixtime ) ) )
    {
        foreach my $field ( keys( %to_unixtime ) )
        {
            if( exists( $fields{ $field } ) )
            {
                ## $fields{ 'UNIX_TIMESTAMP(' . $field . ') AS ' . $field } = $fields{ $field };
                my $func = $self->format_to_epoch({
                    value => ( $prefix ? "${prefix}.${field}" : $field ),
                    bind => 0,
                    quote => 0,
                });
                $fields{ $func . ' AS ' . $field } = $fields{ $field };
                delete( $fields{ $field } );
            }
        }
    }
    
    ## $self->message( 3, "\$avoid contains: ", sub{ $self->printer( $avoid ) } );
    my %avoid = ();
    if( $self->_is_array( $avoid ) )
    {
        %avoid = map{ $_ => 1 } @$avoid;
    }
    elsif( $self->_is_hash( $avoid ) )
    {
        %avoid = %$avoid;
    }
    ## $self->message( 3, "Fields to avoid contains:\n", sub{ $self->printer( \%avoid ) } );
    
    if( %avoid && scalar( keys( %avoid ) ) )
    {
        foreach my $field ( keys( %avoid ) )
        {
            if( exists( $fields{ $field } ) )
            {
                delete( $fields{ $field } );
                delete( $default{ $field } );
            }
        }
    }
    
    my %as = ();
    if( $self->_is_hash( $alias ) )
    {
        %as = %$alias;
        foreach my $field ( keys( %as ) )
        {
            if( exists( $fields{ $field } ) )
            {
                my $f = $prefix 
                        ? "${prefix}.${field}" 
                        : $field;
                $fields{ "$f AS \"$as{ $field }\"" } = $fields{ $field };
                # delete( $fields{ $field } );
            }
            else
            {
                $fields{ "$field AS \"$as{ $field }\"" } = scalar( keys( %fields ) ) + 1;
            }
        }
    }
    ## map{ printf( "%s%s: %s\n", $_, '.' x ( 35 - length( $_ ) ), $FIELDS{ $_ } ) } sort( keys( %FIELDS ) );
    if( exists( $fields{ 'last_name' } ) && 
        exists( $fields{ 'first_name' } ) && 
        !exists( $fields{ 'name' } ) )
    {
    
        my $f = $prefix 
                ? "CONCAT(${prefix}.first_name, ' ', ${prefix}.last_name)" 
                : "CONCAT(first_name, ' ', last_name)";
        push( @extra, "$f AS name" );
    }
    
    if( ( exists( $default{ 'auth' } ) && !defined( $arg{ 'auth' } ) ) || 
        defined( $arg{ 'auth' } ) )
    {
        $default{ 'auth' } = defined( $arg{ 'auth' } ) 
            ? $arg{ 'auth' }
            : 0;
    }
    if( ( exists( $default{ 'status' } ) && !defined( $default{ 'status' } ) ) || 
        defined( $arg{ 'status' } ) )
    {
        $default{ 'status' } = defined( $arg{ 'status' } ) 
            ? $arg{ 'status' }
            : 1;
    }
    foreach my $data ( keys( %arg ) )
    {
        if( exists( $default{ $data } ) )
        {
            $default{ $data } = $arg{ $data };
        }
    }
    my %from_unixtime = ();
    if( $self->_is_array( $from_unix ) )
    {
        %from_unixtime = map{ $_ => 1 } @$from_unix;
    }
    elsif( $self->_is_hash( $from_unix ) )
    {
        %from_unixtime = %$from_unix;
    }
    
    $self->{_args} = $arg;
    # $self->{ '_args' } = $opts->{arg};
    $self->{_default} = \%default;
    $self->{_fields} = \%fields;
    $self->{_extra} = \@extra;
    $self->{_structure} = \%structure;
    $self->{_from_unix} = \%from_unixtime;
    $self->{_to_unix} = \%to_unixtime;
    $self->{query_type} = $query_type;
    $self->{bind} = $tbl_o->database_object->use_bind;
    return( $self );
}

sub group { return( shift->_group_order( 'group', 'group_by', @_ ) ); }

sub having { return( shift->error( "Having clause is not supported by this driver." ) ); }

sub insert
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    my $constant = $self->constant;
    if( scalar( keys( %$constant ) ) )
    {
        ## $self->message( 3, "Found constant data: ", sub{ $self->dumper( $constant, { depth => 1 } ) } );
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my %arg  = ();
    my $select = '';
    my $base_class = $self->base_class;
    if( !@arg && $data && $self->_is_hash( $data ) )
    {
        @arg = %$data;
    }
    ## insert into (field1, field2, field3) select field1, field2, field3 from some_table where some_id=12
    elsif( $data && ref( $data ) eq "${base_class}::Statement" )
    {
        $select = $data->as_string();
    }
    %arg = @arg if( @arg );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table   = $tbl_o->name ||
    return( $self->error( "No table was provided to insert data." ) );
    ## We do not decide of the value of AUTO_INCREMENT fields, so we do not use them in
    ## our INSERT statement.
    my $structure = $tbl_o->structure();
    my $null      = $tbl_o->null();
    my @avoid     = ();
    my( $fields, $values ) = ( '', '' );
    ## $self->message( 3, "Checking structure for table $table: ", sub{ $self->dumper( $structure ) } );
    unless( $select )
    {
        foreach my $field ( keys( %$structure ) )
        {
            push( @avoid, $field ) if( $structure->{ $field } =~ /\b(AUTO_INCREMENT|SERIAL|nextval)\b/i && !$arg{ $field } );
            ## It is useless to insert a blank data in a field whose default value is NULL.
            ## Especially since a test on a NULL field may be made specifically.
            push( @avoid, $field ) if( scalar( @arg ) && !exists( $arg{ $field } ) && $null->{ $field } );
        }
        $self->getdefault({
            table => $table,
            arg => \@arg,
            avoid => \@avoid,
        }) || return;
        ( $fields, $values ) = $self->format_statement();
        $self->message( 3, "Fields formatted are: '$fields' and values are '$values'." );
        ## $self->{binded_values} = $db_data->{binded_values};
    }
    $self->messagef( 3, "%d binded types set in insert.", $self->binded_types->length );
    my $clauses = $self->_query_components( 'insert' );
    my @query = ( $select ? "INSERT INTO $table $select" : "INSERT INTO $table ($fields) VALUES($values)" );
    push( @query, @$clauses ) if( scalar( @$clauses ) );
    my $query = $self->{query} = CORE::join( ' ', @query );
    ## Everything meaningfull lies within the object
    ## If no bind should be done _save_bind does nothing
    $self->_save_bind();
    ## Query string should lie within the object
    ## _cache_this sends back an object no matter what or unde() if an error occurs
    my $sth = $tbl_o->_cache_this( $self );
    ## STOP! No need to go further
    if( !defined( $sth ) )
    {
        return( $self->error( "Error '", $tbl_o->error, "' while preparing query to insert data into table '$table':\n$query" ) );
    }
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
    my $limit = $self->_process_limit( @_ );
#     return( wantarray() ? () : undef() ) if( !@$limit );
#     return( wantarray() ? ( $limit->[ 0 ], $limit->[ 1 ] ) : "LIMIT $limit->[ 0 ], $limit->[ 1 ]" );
    if( CORE::length( $limit->metadata->limit ) )
    {
        $limit->generic( CORE::length( $limit->metadata->offset ) ? 'LIMIT ?, ?' : 'LIMIT ?' );
        $limit->value( CORE::length( $limit->metadata->offset ) ? CORE::sprintf( 'OFFSET %d LIMIT %d', $limit->metadata->offset, $limit->metadata->limit ) : CORE::sprintf( 'LIMIT %d', $limit->metadata->limit ) );
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
    ## return( "SET $str" );
    return( $str );
}

sub new_clause
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug;
    my $o = DB::Object::Query::Clause->new( $opts );
    defined( $o ) || return( $self->error( "Unable to create a DB::Object::Query::Clause object: ", DB::Object::Query::Clause->error ) );
    $o->query_object( $self ) || return( $self->error( "Error: ", $o->error ) );
    # $o->debug( $self->debug );
    return( $o );
}

sub order { return( shift->_group_order( 'order', 'order_by', @_ ) ); }

sub query { return( shift->_set_get_scalar( 'query', @_ ) ); }

sub query_reset { return( shift->_set_get_boolean( 'query_reset', @_ ) ); }

sub query_reset_core_keys { return( shift->_set_get_array_as_object( 'query_reset_core_keys', @_ ) ); }

sub query_reset_keys { return( shift->_set_get_array_as_object( 'query_reset_keys', @_ ) ); }

sub query_type { return( shift->_set_get_scalar( 'query_type', @_ ) ); }

sub query_values { return( shift->_set_get( 'query_values', @_ ) ); }

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
        $self->message( 3, "Removing keys '@$keys'. Call stack: ", $self->_get_stack_trace->as_string );
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
        # $self->message( 3, "Found constant data: ", sub{ $self->dumper( $constant, { depth => 1 } ) } );
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my $tbl_o    = $self->table_object || return( $self->error( "No table object is set." ) );
    my $prefix   = $tbl_o->query_object->table_alias ? $tbl_o->query_object->table_alias : $tbl_o->prefix;
    my $table    = $tbl_o->qualified_name ||
    return( $self->error( "No table name provided to perform select statement." ) );
    my $bind     = $tbl_o->use_bind;
    # $self->message( 3, "Bind mode set to '$bind'." );
    my $cache    = $tbl_o->use_cache;
    # my $multi_db = $tbl_o->param( 'multi_db' );
    my $multi_db = $tbl_o->prefix_database;
    my $db       = $tbl_o->database();
    my $fields   = '';
    my $ok_ref   = $tbl_o->fields();
#     $self->messagef( 3, "%d fields found for our select statement", scalar( keys( %$ok_ref ) ) );
    my $ok_list  = CORE::join( '|', keys( %$ok_ref ) );
    my $tables   = CORE::join( '|', @{$tbl_o->database_object->tables} );
    if( @_ )
    {
        my $data = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
        if( ref( $data ) eq 'SCALAR' )
        {
            $fields = $$data;
        }
        elsif( $self->_is_array( $data ) )
        {
            # No fields provided after all? We fallback to use the magic '*' optimizer
            $fields = @$data ? CORE::join( ', ', @$data ) : '*';
        }
        else
        {
            $fields = $data;
        }
        # Now, we eventually add the table and database specification to the fields
        $fields =~ s{
            (?<!\.)\b($ok_list)\b(\s*)?(?!\.)
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
        
        # Get aliases
        my $alias = $self->alias();
        $self->messagef_colour( 3, "<green>%d</> aliases were provided: <red>%s</>", scalar( keys( %$alias ) ), join( ', ', keys( %$alias ) ) );
        if( $alias && %$alias )
        {
            my @aliases = ();
            foreach my $f ( keys( %$alias ) )
            {
                $self->message( 3, "Does field '$f' exists among the fields for the table '", $self->table_object->name, "' with prefix '$prefix' ? ", CORE::exists( $ok_ref->{ $f } ) ? 'yes' : 'no' );
                if( CORE::exists( $ok_ref->{ $f } ) && $prefix )
                {
                    CORE::push( @aliases, "${prefix}.${f} AS \"" . $alias->{ $f } . "\"" );
                }
                else
                {
                    CORE::push( @aliases, "$f AS " . "\"" . $alias->{ $f } . "\"" );
                }
            }
            $self->message( 3, "Formatted field aliases are: ", sub{ $self->dump( @aliases ) });
            $fields = join( ', ', $fields, @aliases );
        }
    }
    else
    {
        $self->getdefault({ table => $table });
        $fields = $self->format_statement();
    }
    
#     $self->message( 3, "Will use the fields '$fields'" );
    my $tie   = $self->tie();
    $self->message( 3, "Getting the clauses." );
    my $clauses = $self->_query_components( 'select' );
    $self->message( 3, "Clauses contains: '", sub{ join( ', ', @$clauses ) }, "'." );
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
    my $prev_fields = $self->{selected_fields};
    my $last_sth    = '';
    my $queries = $self->_cache_queries;
    # A simple check to avoid to do this test on each query, but rather only on those who deserve it.
    if( $fields eq $prev_fields && @$queries )
    {
        my @last_query = grep
        {
            $_->{selected_fields} ||= '';
            $_->{selected_fields} eq $fields 
        } @$queries;
        $last_sth   = $last_query[ 0 ] || {};
    }
    # If the selected fields in the last query performed were the same than those ones and
    # that the last query object has the flag 'as_string' set to true, this would mean that
    # user has made a statement as string and is now really executing it
    # Now, if the special flag 'query_reset' is true, this means that the user has accessed the methods
    # where(), group(), order() or limit() and hence this is a brain new query for which we need
    # to get the clause conditions
    #if( $fields eq $$prev_fields && $last_sth->{ 'as_string' } )
    #{
        ## unshift( @query, "${vars};" ) if( $vars );
        push( @query, @$clauses ) if( @$clauses );
    #}
    # used by join()
    $self->{selected_fields} = $fields;
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
    ## STOP! No need to go further
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
        $sth->execute() ||
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

# sub unix_timestamp
# {
#     my $self = shift( @_ );
#     if( @_ )
#     {
#         my $ref = ( @_ == 1 && $self->_is_array( $_[0] ) ) ? shift( @_ ) : [ @_ ];
#         $self->{ 'unix_timestamp' } ||= [];
#         push( @{$self->{unix_timestamp}}, ref( $ref ) ? @$ref : $ref );
#     }
#     return( wantarray() ? @{ $self->{ 'unix_timestamp' } } : $self->{ 'unix_timestamp' } );
# }
sub unix_timestamp { return( shift->_set_get_array_as_object( 'unix_timestamp', @_ ) ); }

sub update
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    if( !@arg && $data )
    {
        if( $self->_is_hash( $data ) )
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
        # $self->message( 3, "Found constant data: ", sub{ $self->dumper( $constant, { depth => 1 } ) } );
        return( $constant->{sth} ) if( $constant->{sth} && $self->_is_object( $constant->{sth} ) && $constant->{sth}->isa( 'DB::Object::Statement' ) );
    }
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table = $tbl_o->name ||
    return( $self->error( "No table to update was provided." ) );
    if( !scalar( @arg ) )
    {
        return( $self->error( "No data to update was provided." ) );
    }
    my $values = $self->format_update( \@arg ) ||
    return( $self->error( "No data to update was provided." ) );
    $self->message( 3, "format update returned the formated values: '$values'." );
    my $clauses = $self->_query_components( 'update' );
    my @query  = ( "UPDATE $table SET $values" );
    push( @query, @$clauses ) if( scalar( @$clauses ) );
    my $query = $self->{query} = CORE::join( ' ', @query );
    my( $p, $f, $l ) = caller();
    my $call_sub = ( caller( 1 ) )[3];
    return( $self->error( "Refusing to do a bulk update. Called from package $p in file $f at line $l from sub $call_sub. Enable the allow_bulk_update database object property if you want to do so. Original query was: $query" ) ) if( !$self->where && !$self->database_object->allow_bulk_update );
    $self->{query_values} = \$values;
    $self->_save_bind();
    # my $sth = $self->prepare( $self->{ 'query' } ) ||
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
        ## $sth->finish();
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
    $self->{ $prop } = $self->new_clause if( !CORE::length( $self->{ $prop } ) && !ref( $self->{ $prop } ) );
    if( @_ )
    {
        my $clause = '';
        my $data   = ( @_ == 1 && !Scalar::Util::blessed( $_[0] ) ) ? shift( @_ ) : [ @_ ];
        # $self->message( 3, "Called with parameters: ", sub{ $self->dump( $data ) } );
        if( $self->_is_array( $data ) )
        {
            my $fields_ref = $tbl_o->fields();
            my $prefix     = $tbl_o->prefix;
            my $fields     = join( '|', keys( %$fields_ref ) );
            my $db         = $tbl_o->database();
            my $tables     = CORE::join( '|', @{$tbl_o->database_object->tables} );
            my $multi_db   = $tbl_o->prefix_database;
            my $values     = Module::Generic::Array->new;
            my $components = Module::Generic::Array->new;
            my $types      = Module::Generic::Array->new;
            my $fobjects   = Module::Generic::Array->new;
            my $generic    = Module::Generic::Array->new;
            
            foreach my $field ( @$data )
            {
                # Some garbage reached us
                next if( !CORE::length( $field ) );
                ## Transform a simple 'field' into a field object
                $field = $tbl_o->fo->$field if( CORE::exists( $fields_ref->{ $field } ) );
                if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) )
                {
                    $components->push( '%s' );
                    $fobjects->push( $field );
                    $generic->push( '?' );
                    $types->push( '' );
                    $values->push( $field );
                }
                # i.e. GROUP BY width => GROUP BY table.width
                elsif( ref( $field ) eq 'SCALAR' )
                {
                    $components->push( $$field );
                }
                elsif( $field =~ /\b(?:$fields)\b/ ||
                       $field =~ /\w\([^\)]*\)/ ||
                       $field eq '?' || 
                       !$bind )
                {
                    $field =~ s{
                        (?<!\.)\b($fields)\b(\s*)?(?!\.)
                    }
                    {
                        my( $ok, $spc ) = ( $1, $2 );
                        "$table.$ok$spc";
                    }gex;
                    $field =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
                    $components->push( $field );
                }
                else
                {
                    $components->push( $field );
                    $values->push( $field );
                    $types->push( '' );
                    $generic->push( '?' );
                }
            }
            # $self->message( 3, "Building the $type clause from: ", sub{ $self->dump( $components ) });
            $clause = $self->new_clause({
                value => $components->join( ', ' ),
                type => $type,
                fields => $fobjects,
                generic => $generic->join( ', ' ),
            });
            $clause->bind->values( @$values ) if( $bind );
            $clause->bind->types( @$types ) if( $bind );
        }
        else
        {
            $clause = $self->new_clause({
                value => $data,
                type => $type,
            });
            my $ref = [];
            if( $bind )
            {
                $self->_value2bind( \$data, $ref );
                $clause->bind->values( $ref );
                $clause->bind->types( ( '' ) x scalar( @$ref ) );
            }
        }
        # $self->message( 3, "${type} clause is: '$clause'." );
        $self->{ $prop } = $clause;
    }
    else
    {
        $clause = $self->{ $prop };
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
    $self->{having} ||= '';
    if( @_ )
    {
        my $clause = '';
        my $data   = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
        if( $self->_is_array( $data ) )
        {
            my $fields_ref = $tbl_o->fields();
            my $fields     = join( '|', keys( %$fields_ref ) );
            my $db         = $tbl_o->database();
            my $tables     = CORE::join( '|', @{$self->{tables}->{ $db }} );
            my $multi_db   = $tbl_o->prefix_database;
            my @values     = ();
            my @clause     = ();
            my @types      = ();
            foreach my $field ( @$data )
            {
                ## In case we received some garbage
                next if( !CORE::length( $field ) );
                ## i.e. HAVING width => HAVING table.width
                if( ref( $field ) eq 'SCALAR' )
                {
                    push( @clause, $self->new_clause({
                        value => $$field,
                        type => 'having',
                    }) );
                }
                elsif( $field =~ /\b(?:$fields)\b/ ||
                       $field =~ /\w\([^\)]*\)/ ||
                       $field eq '?' || 
                       !$bind )
                {
                    $field =~ s{
                        (?<!\.)\b($fields)\b(\s*)?(?!\.)
                    }
                    {
                        my( $ok, $spc ) = ( $1, $2 );
                        "$prefix.$ok$spc";
                    }gex if( $prefix );
                    $field =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
                    push( @clause, $self->new_clause({
                        value => $field,
                        type => 'having',
                    }) );
                }
                elsif( $bind )
                {
                    CORE::push( @clause, $self->new_clause(
                    {
                        value => '?',
                        type => 'having',
                        bind => 
                        {
                            values => $field,
                            types => [ '' ],
                        }
                    }) );
                }
                else
                {
                    push( @clause, $self->new_clause({
                        value => $field,
                        type => 'having',
                    }) );
                }
            }
            $clause = $self->new_clause->merge( $self->database_object->AND( @clause ) );
            $clause->bind->values( @values ) if( $bind );
            $clause->bind->types( @types ) if( $bind );
        }
        else
        {
            $clause = $self->new_clause({
                value => $data,
                type => 'having',
            });
            my $ref = [];
            if( $bind )
            {
                $self->_value2bind( \$clause, $ref );
                $clause->bind->values( @$ref ) if( $bind && scalar( @$ref ) );
                $clause->bind->types( ( '' ) x scalar( @$ref ) ) if( $bind );
            }
        }
        $self->{having} = $clause;
    }
    else
    {
        $clause = $self->{having};
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
    my $limit;
    if( !$self->{limit} || !$self->_is_object( $self->{limit} ) )
    {
        ## $self->message( 3, "Missing limit clause object. Creating one." );
        $limit = $self->{limit} = $self->new_clause({ type => 'limit' });
    }
    else
    {
        $limit = $self->{limit};
        ## $self->message( 3, "Limit object is: '", overload::StrVal( $limit ), "' ($limit)." );
    }
    if( @_ )
    {
        my( $start, $end ) = ( '', '' );
        if( @_ == 1 )
        {
            ( $start, $end ) = ( undef(), shift( @_ ) );
        }
        else
        {
            ( $start, $end ) = ( shift( @_ ), shift( @_ ) );
        }
        my @binded = ();
        my @list   = ();
        my @types  = ();
        my @generic = ();
        foreach my $value ( $start, $end )
        {
            next if( !CORE::length( $value ) );
            ## This is a raw parameter - being a ref to a SCALAR means we must not modify it
            if( ref( $value ) eq 'SCALAR' )
            {
                push( @list, $$value );
            }
            ## A value to be a place holder - forward it
            elsif( $value eq '?' )
            {
                push( @list, $value );
                push( @types, '' );
            }
            ## Normal processing
            ## elsif( $bind )
            else
            {
                push( @list, $value );
                push( @generic, '?' );
                push( @binded, $value );
                push( @types, '' );
            }
        }
        ## $limit = $self->{limit} = [ @list ];
        $limit->value( CORE::join( ', ', @list ) ) if( scalar( @list ) );
        $limit->generic( CORE::join( ', ', @generic ) ) if( scalar( @generic ) );
        $limit->bind->values( \@binded );
        $limit->bind->types( \@types );
        if( scalar( @list ) )
        {
            if( scalar( @list ) > 1 )
            {
                $limit->metadata->offset( $list[0] ) if( CORE::length( $list[0] ) );
                $limit->metadata->limit( $list[1] ) if( CORE::length( $list[1] ) );
            }
            else
            {
                $limit->metadata->offset( '' );
                $limit->metadata->limit( $list[0] ) if( CORE::length( $list[0] ) );
            }
        }
    }
    else
    {
        $limit = $self->{limit};
    }
    ## $self->message( 3, "Returning limit object: '", overload::StrVal( $limit ), "'." );
    return( $limit );
}

sub _query_components
{
    my $self = shift( @_ );
    my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my( $where, $group, $sort, $order, $limit );
    $where  = $self->where();
    if( $type eq "select" )
    {
        $group  = $self->group();
        $sort  = $self->reverse() ? 'DESC' : $self->sort() ? 'ASC' : '';
        $order  = $self->order();
    }
    $limit  = $self->limit();
    ## $self->message( 3, "where is '$where', group is '$group', sort is '$sort', order is '$order' and limit is '$limit'." );
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
        ## $self->message( "sub is '$sub'" );
        $type = $sub;
    }
    $self->messagef( 3, "Saving binded values and types for query type '$type' and %d binded types so far.", $self->binded_types->length );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $bind  = $tbl_o->use_bind;
    my $where = $self->where();
    my $group = $self->group();
    my $order = $self->order();
    my $limit = $self->limit();
    ## This is used so upon execute, the saved binded parameters get sent to the DBI::execute method
    if( $bind )
    {
        my $binded = $self->binded;
        ## For update or insert
        my $binded_values = $self->binded_values;
        my $binded_where  = $self->where->bind->values;
        my $binded_group  = $self->group->bind->values;
        my $binded_order  = $self->order->bind->values;
        my $binded_limit  = $self->limit->bind->values;
        ## The order is important
        ## $self->message( $type eq 'select' ? 'Not binding' : 'Binding', " values" );
        $binded->push( @$binded_values ) if( $type !~ /^(?:select|delete)$/ && $binded_values->length );
        $binded->push( @$binded_where ) if( $where->length && $binded_where->length );
        $binded->push( @$binded_group ) if( $group->length && $binded_group->length );
        $binded->push( @$binded_order ) if( $order->length && $binded_order->length );
        $binded->push( @$binded_limit ) if( $limit->length && $binded_limit->length );
        ## $self->message( 3, "values to bind are: ", $binded->join( ', ' ) );
        
        my $binded_types = $self->binded_types;
        $binded_types->push( @{$where->bind->types} ) if( $where->bind->types->length );
        $binded_types->push( @{$group->bind->types} ) if( $group->bind->types->length );
        $binded_types->push( @{$order->bind->types} ) if( $order->bind->types->length );
        $binded_types->push( @{$limit->bind->types} ) if( $limit->bind->types->length );
        $self->messagef( 3, "Afer saving binded, it has %d binded type.", $self->binded_types->length );
    }
    return( $self );
}

sub _value2bind
{
    my $self   = shift( @_ );
    ## If we are not suppose to bind any values, there is no point to go on.
    ## return( 1 ) if( !$self->{ 'bind' } );
    my $str    = shift( @_ );
    my $ref    = shift( @_ );
    my $tbl_o  = $self->{table_object} || return( $self->error( "No table object is set." ) );
    my $table  = $tbl_o->name;
    my $bind   = $tbl_o->use_bind;
    my $db     = $tbl_o->database();
    my $prefix = $tbl_o->prefix;
    my $fields_ref = $tbl_o->fields();
    my $fields = CORE::join( '|', keys( %$fields_ref ) );
    my $tables = CORE::join( '|', @{$tbl_o->database_object->tables} );
    my $multi_db = $tbl_o->param( 'multi_db' );
    my @binded = ();
    $$str =~ s
    {
        (([\w\_]+)(?:\.))?\b([a-zA-Z\_]+)\b\s*(=|\!=|LIKE)\s*['"]([^'"]+)['"]
    }
    {
        do
        {
            my( $this_table, $field, $equity, $value ) = ( $2, $3, $4, $5 );
            ## Add to the list of value to bind on execute() only if this is not already a place holder
            ## push( @binded, $value ) if( $bind && $value ne '?' );
            $this_table ||= $table;
            $this_table .= '.';
            ## $bind ? "${this_table}${field}=?" : "${this_table}${field}='$value'";
            if( $value !~ /[\r\n]+/ &&
                ( $value =~ /\b(?:$fields)\b/ ||
                  $value =~ /\w\([^\)]*\)/ ||
                  $value eq '?' ) )
            {
                "${this_table}${field} $equity $value";
            }
            elsif( $bind )
            {
                push( @binded, $value );
                "${this_table}${field} $equity ?";
            }
            else
            {
                "${this_table}${field} $equity '$value'";
            }
        };
    }geix;
    $$str =~ s
    {
        (?<!\.)\b($fields)\b(\s*)?(?!\.)
    }
    {
        my( $ok, $spc ) = ( $1, $2 );
        "$table.$ok$spc";
    }gex;
    $$str =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
    push( @$ref, @binded ) if( @binded );
    return( 1 );
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
    $self->{ $prop } = $self->new_clause() if( !CORE::length( $self->{ $prop } ) || !$self->_is_object( $self->{ $prop } ) );
    my $where = $self->{ $prop };
    if( @_ )
    {
        my @params = @_;
        # $self->message( 3, "Parameters received are: ", sub{ $self->dump( @params ) } );
        # This will change the belonging of the object $self to the class DB::Object::Prepare so method
        # such as select, insert, update, delete know there are some conditionning clause to be added
        my $table      = $tbl_o->name;
        my $db         = $tbl_o->database();
        my $multi_db   = $tbl_o->prefix_database;
        my $prefix     = $tbl_o->prefix;
        my $fields_ref = $tbl_o->fields();
        my $fields     = CORE::join( '|', keys( %$fields_ref ) );
        my $fields_type = $tbl_o->types;
        # $self->messagef( 3, "%d field types found: %s", scalar( keys( %$fields_type ) ), sub{ $self->dumper( $fields_type ) } );
        # $self->message( 3, "Current arguments are: ", sub{ $self->dumper( \@params, { depth => 1 } ) } );
        
        local $process_where_condition = sub
        {
            # my @parameters = @_;
            # $self->message( 3, "Data to process is: ", sub{ $self->dump( [@_] ) } );
            # $self->message( 3, "Received arguments: ", sub{ $self->dumper( \@parameters, { depth => 1}) } );
            my $data = shift( @_ ) if( @_ % 2 && !( scalar( @_ ) == 1 && Scalar::Util::blessed( $_[0] ) ) );
            # $self->message( 3, "\$data is '$data'." );
            my $agg_op = 'AND';
            my @arg = ();
            if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'DB::Object::Operator' ) )
            {
                return( $self->error( "I was expecting an operator object, but got \"", $_[0], "\" instead." ) ) if( !$_[0]->isa( 'DB::Object::Operator' ) );
                $agg_op = $_[0]->operator || return( $self->error( "Unknown operator for \"", $_[0], "\"." ) );
                ( @arg ) = $_[0]->value;
                # $self->message( 3, "Where aggregator is $agg_op and values are: ", sub{ $self->dump( \@arg ) } );
                $self->message( 3, "Where aggregator is $agg_op and values are: '", sub{ join( "', '", @arg ) }, "'." );
            }
            else
            {
                @arg = @_;
            }
            $data      = \@arg if( @arg );
            # $self->message( 3, "Data to process is: ", sub{ $self->dump( $data ) } );
            my $str    = '';
            my @binded = ();
            my @types  = ();
            # XXX To be removed
            my @field_objects = ();
            my $clause;
            # A simple scalar
            if( ref( $data ) eq 'SCALAR' )
            {
                $str = $$data;
            }
            elsif( ref( $data ) )
            {
                my @list = ();
                my( $field, $value );
                while( @arg )
                {
                    # $self->message( 3, "Data remaining to processes are: ", sub{ $self->dump( \@arg, { depth => 1}) } );
                    $self->message( 3, "Processing '", overload::StrVal( $arg[0] ), "' ($arg[0])." );
                    if( $self->_is_object( $arg[0] ) && $arg[0]->isa( 'DB::Object::Operator' ) )
                    {
                        # $self->message( 3, "Next object is a DB::Object::Operator, let's call recursively $process_where_condition" );
                        my $op_object = shift( @arg );
                        $clause = $process_where_condition->( $op_object );
                        next;
                    }
                    # This is an already formulated clause
                    elsif( $self->_is_object( $arg[0] ) && $arg[0]->isa( 'DB::Object::Query::Clause' ) )
                    {
                        # $self->message( 3, "First element is an DB::Object::Query::Clause object." );
                        push( @list, shift( @arg ) );
                        next;
                    }
                    elsif( $self->_is_object( $arg[0] ) && $arg[0]->isa( 'DB::Object::Fields::Field::Overloaded' ) )
                    {
                        $self->message( 3, "First element is an DB::Object::Fields::Field::Overloaded object: '$arg[0]'" );
                        my $f = shift( @arg );
                        my $cl = $self->new_clause(
                            value => $f,
                            type => 'where',
                        );
                        $self->message( 3, "Is field binded? ", $f->binded ? 'yes' : 'no' );
                        $cl->bind->types( '' ) if( $f->binded );
                        push( @list, $cl );
                        
                        # If this field value assignment is followed (as a pair) by just a regular field, this is likely a typo.
                        # Catching some typical typo errors for the benefit of the coder (from experience)
                        if( scalar( @arg ) && 
                            $self->_is_a( $arg[0], 'DB::Object::Fields::Field' ) )
                        {
                            $self->message( 3, "The user has used a field without value. Maybe a typo? Let's issue warning, as this would result in undesirable where clause." );
                            warn( "Warning only: found a (proper) field value assignment ($f) followed by a field object '$arg[0]' (never mind the surrounding quotes) (", overload::StrVal( $arg[0] ), "). Did you forget to assign a value such as \$tbl->fo->$arg[0] == 'something' ?\n" );
                        }
                        next;
                    }
                    # Case where there is a litteral query component, e.g. "LENGTH(lang) = 2" and the number of arguments is odd which means there is no second argument such as: ->where( "LENGTH(lang) = 2", $tbl->fo->user_id => "something );
                    elsif( ( scalar( @arg ) % 2 ) && !ref( $arg[0] ) )
                    {
                        # $self->message( 3, "Number of element is odd and first one is not a reference." );
                        push( @list, $self->new_clause({ value => shift( @arg ), type => 'where' }) );
                        next;
                    }
                    # Catching some typical typo errors for the benefit of the coder (from experience)
                    # The coder provided a field object without associated value and there are no other argument passed to the where clause. He/she probably forget the assignment like $tbl->fo->field == 'something'
                    elsif( $self->_is_a( $arg[0], 'DB::Object::Fields::Field' ) && scalar( @arg ) == 1 )
                    {
                        $self->message( 3, "The user has used a field without value. Maybe a typo? Let's issue warning, as this would result in undesirable where clause." );
                        warn( "Warning only: found a field object '$arg[0]' (never mind the surrounding quotes) (", overload::StrVal( $arg[0] ), ") followed by no other argument. Did you forget to assign a value such as \$tbl->fo->$arg[0] == 'something' ?\n" );
                    }
                    
                    my( $field, $value ) = ( shift( @arg ), shift( @arg ) );
#                     if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) )
#                     {
#                         $self->message( 3, "$field is a DB::Object::Fields::Field object." );
#                     }
#                     else
#                     {
#                         $self->message( 3, "$field is not a DB::Object::Fields::Field object." );
#                     }
                    
                    # Catching some typical typo errors for the benefit of the coder (from experience)
                    if( $self->_is_a( $field, 'DB::Object::Fields::Field' ) && 
                        $self->_is_a( $value, 'DB::Object::Fields::Field::Overloaded' ) )
                    {
                        $self->message( 3, "The user has used a field without value. Maybe a typo? Let's issue warning, as this would result in undesirable where clause." );
                        warn( "Warning only: found a field object '$field' (never mind the surrounding quotes) (", overload::StrVal( $field ), ") followed by an another (proper) field value assignment ($value). Did you forget to assign a value such as \$tbl->fo->$field == 'something' ?\n" );
                    }
                    
                    unless( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) )
                    {
                        $field =~ s/\b(?<!\.)($fields)\b/$prefix.$1/gs if( $prefix );
                    }
                    my $i_am_negative = 0;
                    if( Scalar::Util::blessed( $value ) && $value->isa( 'DB::Object::NOT' ) )
                    {
                        ( $value ) = $value->value;
                        # $self->message( 3, "NOT value is '$value' (", \$value, ")." );
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
                            # $self->message( 3, "Value is NULL (", Scalar::Util::reftype( $value ), "), so we set this as a scalar reference: '$value'." );
                        }
                        $i_am_negative++;
                    }
                    # When value is undef() or explicitly set to NULL, we need to write this as IS NULL to be sql compliant
                    elsif( !defined( $value ) || lc( $value ) eq 'null' )
                    {
                        push( @list, $self->new_clause({
                            value => "$field IS NULL",
                            type => 'where',
                            })
                        );
                        next;
                    }
                    
                    my $f;
                    if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) )
                    {
                        $f = '%s';
                    }
                    else
                    {
                        $f = $prefix ? "$prefix.$field" : $field;
                    }
                    
                    if( ref( $value ) eq 'SCALAR' )
                    {
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
                        my $res = $value->fetchrow();
                        my $cl = $self->new_clause({
                            value => $i_am_negative ? "$f != '$res'" : "$f = '$res'",
                            generic => $i_am_negative ? "$f != ?" : "$f = ?",
                            type => 'where',
                        });
                        $cl->bind->values( $res );
                        $cl->bind->types( '' );
                        $cl->fields( $field ) if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) );
                        push( @list, $cl );
                    }
                    elsif( ref( $value ) eq 'Regexp' )
                    {
                        # $self->message( 3, "\$value '$value' is a regular expression object." );
                        # (?^:^want-(.*?)) => ^want-(.*?)
                        if( $value =~ s/^\(\?\^\:// )
                        {
                            $value =~ s/\)$//;
                        }
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
                        $cl->bind->values( $value );
                        $cl->bind->types( '' );
                        $cl->fields( $field ) if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) );
                        push( @list, $cl );
                    }
                    elsif( $value =~ /[\s\(\)\.\'\"]+(?:$fields)[\s\(\)\.\'\"]+/ ||
                           $value =~ /\w\([^\)]*\)/ ||
                           $value eq '?' )
                    {
                        # Nothing fancy, as is. Even with binding option on, it will still return the clause without placeholder, because we don't know what $value is
                        my $cl = $self->new_clause({
                            value => $i_am_negative ? "$f != $value" : "$f = $value",
                            type => 'where',
                        });
                        $cl->bind->types( '' ) if( $value eq '?' );
                        $cl->fields( $field ) if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) );
                        push( @list, $cl );
                    }
                    else
                    {
                        my $cl;
                        if( lc( $fields_type->{ $field } ) eq 'bytea' )
                        {
                            $cl = $self->new_clause({
                                value => "$f" . ( $i_am_negative ? '!=' : '=' ) . $tbl_o->database_object->quote( $value, DBD::Pg::PG_BYTEA ),
                                type => 'where',
                            });
                        }
                        else
                        {
                            $cl = $self->new_clause({
                                value => "$f" . ( $i_am_negative ? '!=' : '=' ) . $tbl_o->database_object->quote( $value ),
                                generic => $i_am_negative ? "$f != ?" : "$f = ?",
                                type => 'where',
                            });
                            $cl->bind->values( $value );
                        }
                        $cl->fields( $field ) if( $self->_is_object( $field ) && $field->isa( 'DB::Object::Fields::Field' ) );
                        if( lc( $fields_type->{ $field } ) eq 'bytea' )
                        {
                            # XXX Really need to fix this !!
                            $cl->bind->types( DBD::Pg::PG_BYTEA );
                        }
                        else
                        {
                            $cl->bind->types( '' );
                        }
                        CORE::push( @list, $cl );
                    }
                }
                # $self->message( 3, "Joining $type clause component using the '$agg_op' operator: ", sub{ $self->dump( @list ) } );
                $clause = $self->new_clause->merge( $tbl_o->database_object->$agg_op( @list ) );
                # $self->message( 3, "Clause is: '$clause'" );
            }
            elsif( $data )
            {
                $self->_value2bind( \$data, \@binded ) if( $bind );
                $str = $data;
                @types = ( '' ) x scalar( @binded );
                $clause = $self->new_clause({
                    value => $str,
                    bind =>
                    {
                        values => \@binded,
                        types => \@types,
                    }
                });
            }
            $self->message( 3, "Raw clause is: '$str' and using clause it is: '$clause'" );
            return( $clause );
        };
        $where = $self->{ $prop } = $process_where_condition->( @params );
        $self->message( 3, "Final clause is: '$where'.\nBinded values are: '", $where->bind->values->join( "', '" ), "', and binded types: '", $where->bind->types->join( "', '" ), "'." );
        return( $where );
    }
    else
    {
        $where = $self->{ $prop };
    }
    return( $where );
}

# XXX package DB::Object::Query::Clause
package DB::Object::Query::Clause;
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
    my @copy = @_;
    # $self->message( 3, "Arg provided: ", sub{ $self->dump( \@copy ) });
    $self->{value} = '';
    $self->{generic} = '';
    $self->{_init_strict_use_sub} = 1;
    $self->{fields} = [];
    defined( $self->SUPER::init( @copy ) ) || return;
    # $self->message( 3, "Value is set to '$self->{value}'" );
    # return( $self->error( "No sql clause was provided." ) ) if( !$self->{value} );
    return( $self );
}

sub as_string
{
    # no overloading;
    my $self = shift( @_ );
    # $self->message( 3, "Query object is '", $self->query_object, "'." );
    # $self->message( 3, "Use bind value for clause of type '", $self->type, "' is: '", $self->query_object->table_object->use_bind, "'." );
    my $fields = $self->fields;
    if( $self->generic->length && $self->query_object->table_object->use_bind )
    {
        return( $self->generic ) if( !$fields->length );
        return( Module::Generic::Scalar->new( CORE::sprintf( $self->generic, @$fields ) ) );
    }
    my $str  = $self->value;
    return( $str ) if( !$fields->length );
    # Stringification of the fields will automatically format them properly, ie with a table prefix, schema prefix, database prefix as necessary
    return( Module::Generic::Scalar->new( CORE::sprintf( $str, @$fields ) ) );
    # return( CORE::sprintf( $str, @$fields ) );
}

sub bind
{
    return( shift->_set_get_class( 'bind', 
    {
        # The sql types of the value bound to the placeholders
        types => { type => 'array_as_object' },
        # The values bound to the placeholders in the sql clause
        values => { type => 'array_as_object' },
    }, @_ ) );
}

sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }

sub generic { return( shift->_set_get_scalar_as_object( 'generic', @_ ) ); }

sub length { return( shift->value->length ); }

sub metadata { return( shift->_set_get_hash_as_object( 'metadata', @_ ) ); }

sub merge
{
    my $self = shift( @_ );
    if( @_ )
    {
        # By default
        my $op = 'AND';
        my @params = ();
        # $clause->merge( $dbh->OR( $clause1, $clause2, $clause3 ) );
        # or just
        # $clause->merge( $clause1, $clause2, $clause3 );
        if( $self->_is_object( $_[0] ) && $_[0]->isa( 'DB::Object::Operator' ) )
        {
            $op_obj = shift( @_ );
            return( $self->error( "Database Object operator provided is invalid. It should be either an AND or OR." ) ) if( $op_obj->operator ne 'AND' and $op_obj->operator ne 'OR' and $op_obj->operator ne 'NOT' );
            $op = $op_obj->operator;
            @params = $op_obj->value;
            # $self->message( 3, "Found an operator '$op' with ", scalar( @params ), " data within." );
        }
        else
        {
            @params = @_;
        }
        # $self->messagef( 3, "Merging %d elements.", scalar( @params ) );
        
        my @clause = ();
        @clause = ( $self->value ) if( $self->value->length > 0 );
        my @generic = ();
        @generic = ( $self->generic ) if( $self->generic->length > 0 );
        foreach my $this ( @params )
        {
            # Safeguard against garbage
            # $self->message( 3, "Is this data '", $this, "' (", ref( $this ), ") a DB::Object::Query::Clause object." );
            # Special treatment for DB::Object::Fields::Field::Overloaded who are already formatted
            if( $self->_is_object( $this ) && $this->isa( 'DB::Object::Fields::Field::Overloaded' ) )
            {
                push( @clause, $this );
                next;
            }
            
            next if( !$self->_is_object( $this ) || ( $self->_is_object( $this ) && !$this->isa( 'DB::Object::Query::Clause' ) ) );
            # First check we even have a clause, otherwise skip
            if( !$this->value->length )
            {
                $self->message( 3, "Clause value for this object is empty: '$this'." );
                CORE::next;
            }
            if( $self->type->length && $this->type->length && $this->type ne $self->type )
            {
                $self->message( 3, "Found a type '", $this->type, "', but it does not match ours '", $self->type, "'." );
                return( $self->error( "This clause provided for merge is not of the same type \"", $this->type, "\" as ours \"", $self->type, "\"." ) );
            }
            # Possibly our type is empty and if so, we initiate it by using the type of the first object we find
            # This makes it convenient to merge without having to set the type beforehand like so:
            # $clause->type( 'where' );
            # $clause->merge( $w1, $w2, $e3 );
            # We can do instead
            # $clause->merge( $w1, $w2, $e3 );
            # And it will take the type from $w1
            $self->type( $this->type ) if( !$self->type->length );
            $self->message( 3, "Adding value '", $this->value, "' and possibly type '", $this->type, "' to the stack." );
            CORE::push( @clause, $this->value );
            CORE::push( @generic, $this->generic ) if( $this->generic->length );
            $self->fields->push( @{$this->fields} ) if( $this->fields->length );
            $self->messagef( 3, "This element has bind types length of %d", $this->bind->types->length );
            $self->bind->types->push( @{$this->bind->types} ) if( $this->bind->types->length );
            $self->bind->values->push( @{$this->bind->values} ) if( $this->bind->values->length );
            my $ref = $this->metadata;
            my $hash = $self->metadata;
            foreach my $k ( keys( %$ref ) )
            {
                $hash->{ $k } = $ref->{ $k } if( !CORE::exists( $hash->{ $k } ) );
            }
            $self->metadata( $hash );
        }
        $self->value( CORE::join( " $op ", @clause ) );
        $self->generic( CORE::join( " $op ", @generic ) );
        $self->message( 3, "Final merged value is now '", $self->value, "' and generic is '", $self->generic, "'." );
    }
    return( $self );
}

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::Query', @_ ) ); }

# The clause type e.g. where, order, group, having, limit, etc
sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

# The string value of the clause
sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

1;

# XXX POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Query - Query Object

=head1 SYNOPSIS

    my $q = DB::Object::Query->new;

=head1 VERSION

    v0.4.6

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

=head2 order

Provided with a list of parameter and this will format the C<order> clause by calling L</_group_order>

It returns a new L<DB::Object::Query::Clause> object.

=head2 query

Sets or gets the query string. It returns whatever is set as a regular string.

=head2 query_type

Sets or gets the query type, such as C<delete>, C<insert>, C<select>, C<update>, etc.

=head2 query_values

Sets or gets the query values.

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

=head2 sort

Set the query to use normal sorting order.

=head2 sorted

Sets or gets the list of sorted columns used in statements. This returns a L<Module::Generic::Array> object.

=head2 table_alias

Sets an optional alias for this table to be used in statement.

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

This is used to format C<where> and C<having> clause.

Provided with a query type and clause property name such as C<having> or C<where> and other parameters and this will format the C<where> or C<having> clause and return a new L<DB::Object::Query::Clause> object.

It checks each parameter passed.

if the first parameter is a L<DB::Object::Operator> object, it will take it embedded values by calling L<DB::Object::Query::Clause/value>

If the parameter is a scalar reference, it will use it as is.

If the parameter is a L<DB::Object::Operator> object like L<DB::Object::AND>, L<DB::Object::OR> or L<DB::Object::NOT>, it will recursively process its embedded elements.

If the parameter is a L<DB::Object::Query::Clause> object, it will be added to the stack of elements.

If the parameter is a L<DB::Object::Fields::Field::Overloaded> object, it will be added as a new L<DB::Object::Query::Clause> to the stack.

It then checks parameters two by two, the first one being the column and the second being its value.

If the value is the operator object L<DB::Object::NOT>, it adds to the stack a new clause object of type C<column IS NOT something>, such as C<column IS NOT NULL>

if the value is undefined or that the value is equal to C<NULL>, then it adds to the stack a new clause object L<DB::Object::Query::Clause> of type C<column IS NULL>

If the value is a scalar reference, it will be added as is in a new clause object that is added to the stack.

If the value is a L<DB::Object::Statement>, L<DB::Object::Statement/fetchrow> will be called and the value fetched will be added as a new clause object to the stack.

If the value is a perl Regexp object, then it will be formatted in a way suitable to the driver and added to a new clause object to the stack.

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
