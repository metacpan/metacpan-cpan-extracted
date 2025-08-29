# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres/Query.pm
## Version v0.3.1
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
package DB::Object::Postgres::Query;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Query );
    use vars qw( $VERSION $DEBUG );
    use Wanted;
    our $VERSION = 'v0.3.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{having} = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{binded_having} = [];
    $self->{query_reset_keys} = [qw( alias binded binded_values binded_where binded_limit binded_group binded_having binded_order from_unixtime group_by limit local _on_conflict on_conflict order_by reverse sorted unix_timestamp where )];
    return( $self );
}

sub binded_having { return( shift->_set_get_array_as_object( 'binded_having', @_ ) ); }

# sub binded_types_as_param
# {
#     my $self = shift( @_ );
#     my $types = $self->binded_types;
#     my $params = $self->new_array;
#     foreach my $t ( @$types )
#     {
#         if( CORE::length( $t ) )
#         {
#             $params->push( { pg_type => $t } );
#         }
#         else
#         {
#             $params->push( '' );
#         }
#     }
#     return( $params );
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
            $params->push( { pg_type => $type } );
        }
        else
        {
            $params->push( '' );
        }
    });
    return( $params );
}

sub dollar_placeholder
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->prepare_options->set( 'pg_placeholder_dollaronly' => shift( @_ ) );
    }
    return( $self->prepare_options->get( 'pg_placeholder_dollaronly' ) );
}

sub format_from_epoch
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( $opts->{bind} )
    {
        return( "TO_TIMESTAMP(?)" );
    }
    else
    {
        return( sprintf( "TO_TIMESTAMP(%s)", $opts->{value} ) );
    }
}

sub format_to_epoch
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( $opts->{bind} )
    {
        # 2020-10-11: ABSTIME is deprecated in PostgreSQL 12
        # https://www.postgresql.org/docs/12/release-12.html
        # return( "'?'::ABSTIME::INTEGER" );
        # We use instead the more standard way which works back from PostgreSQL 7.1
        return( "EXTRACT( EPOCH FROM '?'::TIMESTAMP )::INTEGER" );
    }
    else
    {
        # return( sprintf( "%s::ABSTIME::INTEGER", $opts->{quote} ? "'" . $opts->{value} . "'" : $opts->{value} ) );
        return( sprintf( "EXTRACT( EPOCH FROM %s::TIMESTAMP )::INTEGER", $opts->{quote} ? "'" . $opts->{value} . "'" : $opts->{value} ) );
    }
}

# NOTE: For select or insert queries
sub format_statement
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    # Should we use bind statement?
    my $bind   = $tbl_o->use_bind;
    $opts->{data} = $self->{_default} if( !$opts->{data} );
    $opts->{order} = $self->{_fields} if( !$opts->{order} );
    $opts->{table} = $tbl_o->name if( !$opts->{table} );
    local $_;
    my $data  = $opts->{data};
    my $order = $opts->{order};
    my $table = $opts->{table};
    my $from_unix = {};
    my $unixtime  = {};
    my $args = $self->{_args};
    my $fields = '';
    my $values = '';
    my $base_class = $self->base_class;
    $from_unix = $self->{_from_unix};
    if( !%$from_unix )
    {
        my $times = $self->from_unixtime();
        map{ $from_unix->{ $_ }++ } @$times;
    }

    if( $self->_is_array( $unixtime ) )
    {
        my %hash = map{ $_ => 1 } @$unixtime;
        $unixtime = \%hash;
    }
    my @format_fields = ();
    my @format_values = ();
    my $binded   = $self->{binded_values} = [];
    # my $multi_db = $tbl_o->param( 'multi_db' );
    my $multi_db = $tbl_o->prefix_database;
    my $prefix   = $tbl_o->prefix;
    my $db       = $tbl_o->database;
    my $field_prefix = $tbl_o->query_object->table_alias ? $tbl_o->query_object->table_alias : $prefix;
    my $fields_ref = $tbl_o->fields;
    my $ok_list  = CORE::join( '|', keys( %$fields_ref ) );
    my $tables   = CORE::join( '|', @{$tbl_o->database_object->tables} );
    my $struct   = $tbl_o->structure || return( $self->pass_error( $tbl_o->error ) );
    my $types    = $tbl_o->types;
    my $types_const = $tbl_o->types_const;
    my $query_type = $self->{query_type};
    my @sorted   = ();
    my @types    = ();
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
    # Used for insert or update so that execute can take a hash of key => value pair and we would bind the values in the right order
    # But or that we need to know the order of the fields.
    $self->{sorted} = \@sorted;
    my $placeholder_re = $tbl_o->database_object->_placeholder_regexp;
    my $elems = $self->new_elements( debug => $self->debug );

    foreach my $field ( @sorted )
    {
        next if( defined( $struct->{ $field } ) && $struct->{ $field } =~ /\bSERIAL\b/i );
        my $elem = $self->new_element;
        if( exists( $data->{ $field } ) )
        {
            my $value = $data->{ $field };
            if( $self->_is_a( $value, "${base_class}::Statement" ) )
            {
                $elem->value( '(' . $value->as_string . ')' );
                # push( @format_values, '(' . $value->as_string . ')' );
                # push( @$binded, $value->query_object->binded_values->list ) if( $value->query_object->binded_values->length );
                # # $self->binded_types->push( $value->query_object->binded_types_as_param );
                # push( @types, $value->query_object->binded_types->list ) if( $value->query_object->binded_types->length );
                $elem->elements( $value->query_object->elements );
            }
            # This is for insert or update statement types
            elsif( exists( $from_unix->{ $field } ) )
            {
                # push( @format_values, sprintf( "FROM_UNIXTIME('%s') AS $field", $data->{ $field } ) );
                if( $bind )
                {
                    # push( @$binded, $value );
                    # push( @format_values, $self->format_from_epoch({ value => $value, bind => 1 }) );
                    if( CORE::exists( $types_const->{ $field } ) )
                    {
                        # CORE::push( @types, $types_const->{ $field }->{constant} );
                        # PG_INT4
                        # CORE::push( @types, $self->database_object->get_sql_type( 'int4' ) );
                        $elem->type( $self->database_object->get_sql_type( 'int4' ) );
                    }
                    # else
                    # {
                    #     CORE::push( @types, '' );
                    # }
                    if( $value =~ /^($placeholder_re)$/ )
                    {
                        $elem->placeholder( $1 );
                        if( defined( $+{index} ) )
                        {
                            $elem->index( $+{index} );
                        }
                    }
                    else
                    {
                        $elem->value( $value );
                    }
                    $elem->format( $self->format_from_epoch({ value => $value, bind => 1 }) );
                }
                else
                {
                    # push( @format_values, $self->format_from_epoch({ value => $value, bind => 0 }) );
                    if( $value =~ /^$placeholder_re$/ )
                    {
                        $elem->format( $self->format_from_epoch({ value => $value, bind => 1 }) );
                        if( CORE::exists( $types_const->{ $field } ) )
                        {
                            # CORE::push( @types, $types_const->{ $field }->{constant} );
                            # PG_INT4
                            # CORE::push( @types, $self->database_object->get_sql_type( 'int4' ) );
                            $elem->type( $self->database_object->get_sql_type( 'int4' ) );
                        }
                        # else
                        # {
                        #     CORE::push( @types, '' );
                        # }
                    }
                    else
                    {
                        $elem->format( $self->format_from_epoch({ value => $value, bind => 0 }) );
                    }
                }
            }
            elsif( ref( $value ) eq 'SCALAR' )
            {
                push( @format_values, $$value );
            }
            elsif( $value =~ /^($placeholder_re)$/ )
            {
                $elem->placeholder( $1 );
                $elem->format( $1 );
                if( defined( $+{index} ) )
                {
                    $elem->index( $+{index} );
                }
                # push( @format_values, $1 );
                # CORE::push( @types, $types_const->{ $field } ? $types_const->{ $field }->{constant} : '' );
                if( CORE::exists( $types_const->{ $field } ) )
                {
                    # CORE::push( @types, $types_const->{ $field }->{constant} );
                    $elem->type( $types_const->{ $field }->{constant} );
                }
                # else
                # {
                #     CORE::push( @types, '' );
                # }
            }
            elsif( $struct->{ $field } =~ /^\s*\bBLOB\b/i )
            {
                # push( @format_values, '?' );
                # push( @$binded, $value );
                $elem->placeholder( '?' );
                $elem->format( '?' );
                $elem->value( $value );
                my $const;
                if( lc( $types->{ $field } ) eq 'bytea' && ( $const = $self->database_object->get_sql_type( 'bytea' ) ) )
                {
                    # CORE::push( @types, DBD::Pg::PG_BYTEA );
                    # CORE::push( @types, $const );
                    $elem->type( $const );
                }
                # else
                # {
                #     CORE::push( @types, '' );
                # }
            }
            # If the value itself looks like a field name or like a SQL function
            # or simply if bind option is inactive
            # This stinks too much. It is way too complex to parse or guess a sql query
            # use a scalar reference instead to pass value as is
#             elsif( $value =~ /(?:\.|\A)(?:$ok_list)\b/ ||
#                    $value =~ /[a-zA-Z_]{3,}\([^\)]*\)/ ||
#                       $value eq '?' )
#             {
#                 push( @format_values, $value );
#             }
            elsif( !$bind )
            {
                my $const;
                $elem->value( $value );
                if( lc( $types->{ $field } ) eq 'bytea' && ( $const = $self->database_object->get_sql_type( 'bytea' ) ) )
                {
                    # push( @format_values, $tbl_o->database_object->quote( $value, DBD::Pg::PG_BYTEA ) );
                    # push( @format_values, $tbl_o->database_object->quote( $value, { pg_type => $const } ) );
                    $elem->format( $tbl_o->database_object->quote( $value, { pg_type => $const } ) );
                }
                # Value is a hash and the data type is json, so we transform this value into a json data
                elsif( $self->_is_hash( $value => 'strict' ) && ( lc( $types->{ $field } ) eq 'jsonb' || lc( $types->{ $field } ) eq 'json' ) )
                {
                    my $this_json = $self->_encode_json( $value );
                    # push( @format_values, $tbl_o->database_object->quote( $this_json, ( lc( $types->{ $field } ) eq 'jsonb' ? DBD::Pg::PG_JSONB : DBD::Pg::PG_JSON ) ) );
                    # push( @format_values, $tbl_o->database_object->quote( $this_json, { pg_type => $self->database_object->get_sql_type( $types->{ $field } ) } ) );
                    $elem->format( $tbl_o->database_object->quote( $this_json, { pg_type => $self->database_object->get_sql_type( $types->{ $field } ) } ) );
                }
                else
                {
                    # push( @format_values, sprintf( "'%s'", quotemeta( $value ) ) );
                    # push( @format_values, sprintf( "%s", $tbl_o->database_object->quote( $value ) ) );
                    $elem->format( sprintf( "%s", $tbl_o->database_object->quote( $value ) ) );
                }
            }
            # We do this before testing for param binding because DBI puts quotes around SET number :-(
            elsif( $value =~ /^\d+$/ && $struct->{ $field } =~ /\bSET\(/i )
            {
                # push( @format_values, $value );
                $elem->format( $value );
            }
            elsif( $value =~ /^\d+$/ && 
                   $struct->{ $field } =~ /\bENUM\(/i && 
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
                $elem->placeholder( '?' );
                $elem->format( '?' );
                $elem->value( $value );
                my $const;
                if( lc( $types->{ $field } ) eq 'bytea' && ( $const = $self->database_object->get_sql_type( 'bytea' ) ) )
                {
                    # CORE::push( @types, $const );
                    $elem->type( $const );
                }
                # else
                # {
                #     CORE::push( @types, '' );
                # }
            }
            # In last resort, we handle the formatting ourself
            else
            {
                # push( @format_values, "'" . quotemeta( $value ) . "'" );
                my $const;
                if( lc( $types->{ $field } ) eq 'bytea' && ( $const = $self->database_object->get_sql_type( 'bytea' ) ) )
                {
                    # push( @format_values, $tbl_o->database_object->quote( $value, DBD::Pg::PG_BYTEA ) );
                    # push( @format_values, $tbl_o->database_object->quote( $value, { pg_type => $const } ) );
                    $elem->format( $tbl_o->database_object->quote( $value, { pg_type => $const } ) );
                }
                else
                {
                    # push( @format_values, $tbl_o->database_object->quote( $value ) );
                    $elem->format( $tbl_o->database_object->quote( $value ) );
                }
            }
        }

        if( $field_prefix ) 
        {
            # $self->message_colour( 3, "Prefix to be used is '<green>$field_prefix</>'." );
            $field =~ s{
                (?<![\.\"])\b($ok_list)\b(\s*)?(?!\.)
            }
            {
                my( $field, $spc ) = ( $1, $2 );
                if( $` =~ /\s+(?:AS|FROM)\s+$/i )
                {
                    "${field}${spc}";
                }
                elsif( $query_type eq 'select' && $prefix )
                {
                    "${field_prefix}.${field}${spc}";
                }
                else
                {
                    "${field}${spc}";
                }
            }gex;
            $field =~ s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
            # push( @format_fields, $field );
        }
        # else
        # {
        #     push( @format_fields, $field );
        # }
        $elem->field( $field );
        $elems->push( $elem );
    }
    # TODO: Remove the following line as it is obsolete as of 2023-07-23
    $self->binded_types->push( @types ) if( scalar( @types ) );
    if( !wantarray() && scalar( @{$self->{_extra}} ) )
    {
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

# _having is in DB::Object::Query
# sub having { return( shift->_having( @_ ) ); }
sub having { return( shift->_where_having( 'having', 'having', @_ ) ); }

# http://www.postgresql.org/docs/9.3/interactive/queries-limit.html
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
            $limit->generic( CORE::length( $limit->metadata->offset // '' ) ? 'OFFSET ? LIMIT ?' : 'LIMIT ?' );
            # %s works for integer, and also for numbered placeholders like $1 or ?1, or regular placeholder like ?
            $limit->value(
                CORE::length( $limit->metadata->offset // '' )
                    ?  sprintf( "OFFSET %s LIMIT %s", $limit->metadata->offset, $limit->metadata->limit )
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

# https://www.postgresql.org/docs/10/sql-insert.html
# $q->on_conflict({
#     target => 'id',
#     action => 'nothing',
#     action => 'update',
#     fields => { a => 'some value', b => 'some other' },
# });
sub on_conflict
{
    my $self = shift( @_ );
    my $opts = {};
    $self->{_on_conflict} = {} if( ref( $self->{_on_conflict} ) ne 'HASH' );
    if( @_ )
    {
        my $tbl_o = $self->{table_object} || return( $self->error( "No table object is set." ) );
        my $ver = $tbl_o->database_object->version;
        if( version->parse( $ver ) < version->parse( '9.4' ) )
        {
            return( $self->error( "PostgreSQL version is $ver, but version 9.5 or higher is required to use this on conflict clause." ) );
        }
        $opts = $self->_get_args_as_hash( @_ );
        my $hash = {};
        my @comp = ( 'ON CONFLICT' );
        if( $opts->{target} )
        {
            $hash->{target} = $opts->{target};
            # Example: ON CONFLICT ON CONSTRAINT customers_name_key DO NOTHING;
            if( $hash->{target} =~ /^(on[[:blank:]]+constraint)(.*?)$/i )
            {
                $hash->{target} = "\U$1\E$2";
                push( @comp, $hash->{target} );
            }
            # a reference to a scalar was provided, so we set the value as is
            elsif( ref( $hash->{target} ) eq 'SCALAR' )
            {
                push( @comp, $$hash->{target} );
            }
            elsif( $self->_is_array( $hash->{target} ) )
            {
                push( @comp, sprintf( '(%s)', join( ',', @{$hash->{target}} ) ) );
            }
            else
            {
                push( @comp, sprintf( '(%s)', $hash->{target} ) );
            }
        }
        # https://www.postgresql.org/docs/10/sql-insert.html#SQL-ON-CONFLICT
        elsif( $opts->{action} ne 'nothing' )
        {
            return( $self->error( "No target was specified for the on conflict clause." ) );
        }

        if( $opts->{where} )
        {
            $hash->{where} = $opts->{where};
            push( @comp, 'WHERE ' . $opts->{where} );
        }

        # action => update
        if( $opts->{action} )
        {
            if( $opts->{action} eq 'update' )
            {
                $hash->{action} = $opts->{action};
                # return( $self->error( "No fields to update was provided for on conflict do update" ) ) if( !$opts->{fields} );
                # No fields provided, so we take it from the initial insert and build the update list instead
                if( !$opts->{fields} )
                {
                    $self->{_on_conflict_callback} = sub
                    {
                        my $f_ref = $self->{_args};
                        # Need to account for placeholders
                        # Let's check values only
                        $self->is_upsert(1);
                        my $elems = $self->format_update( $f_ref );
                        my $inherited_fields = $elems->formats->join( ', ' );
                        push( @comp, 'DO UPDATE SET' );
                        push( @comp, $inherited_fields );
                        $hash->{query} = join( ' ', @comp );
                        $self->{_on_conflict} = $hash;
                        $self->{on_conflict} = join( ' ', @comp );
                        $self->elements->push( $elems->elements->list );
                        $self->messagec( 5, "There are now {green}", $elems->length, "{/} elements for this UPSERT query." );
                        # Usable only once
                        CORE::delete( $self->{_on_conflict_callback} );
                    };
                    # Return empty, not undef; undef is error
                    return( '' );
                }
                return( $self->error( "Fields property to update for on conflict do update clause is not a hash reference nor an array of fields." ) ) if( !$self->_is_hash( $opts->{fields} => 'strict' ) && !$self->_is_array( $opts->{fields} ) && !$self->{_on_conflict_callback} );
                if( $self->_is_hash( $opts->{fields} => 'strict' ) )
                {
                    return( $self->error( "Fields property to update for on conflict do update clause contains no fields!" ) ) if( !scalar( keys( %{$opts->{fields}} ) ) );
                }
                elsif( $self->_is_array( $opts->{fields} ) )
                {
                    return( $self->error( "Fields property to update for on conflict do update clause contains no fields!" ) ) if( !scalar( @{$opts->{fields}} ) );
                }

                if( $self->_is_array( $opts->{fields} ) )
                {
                    my $this = $opts->{fields};
                    my $new = {};
                    foreach my $f ( @$this )
                    {
                        $new->{ $f } = \( 'EXCLUDED.' . $f );
                    }
                    $opts->{fields} = $new;
                }
                # Here the user will use the special table 'excluded'
                $hash->{fields} = $opts->{fields};

                my $q = [];

                foreach my $k ( sort( keys( %{$opts->{fields}} ) ) )
                {
                    push( @$q, sprintf( '%s = %s', $k, ref( $opts->{fields}->{ $k } ) eq 'SCALAR' ? ${$opts->{fields}->{ $k }} : $tbl_o->database_object->quote( $opts->{fields}->{ $k } ) ) );
                }
                if( scalar( @$q ) )
                {
                    push( @comp, 'DO UPDATE SET' );
                    push( @comp, join( ", ", @$q ) );
                }
                else
                {
                    return( $self->error( "An on conflict do update clause was specified, but I could not get a list of fields to update." ) );
                }
            }
            elsif( $opts->{action} eq 'nothing' || $opts->{action} eq 'ignore' )
            {
                $hash->{action} = $opts->{action};
                push( @comp, 'DO NOTHING' );
            }
            else
            {
                return( $self->error( "Unknown action '$opts->{action}' for on conflict clause." ) );
            }
        }
        else
        {
            return( $self->error( "No action was specified for the on conflict clause." ) );
        }
        $hash->{query} = join( ' ', @comp );
        $self->{_on_conflict} = $hash;
        $self->{on_conflict} = $self->new_clause({ value => join( ' ', @comp ) });
    }
    # We are being called possibly by _query_components
    # If we have a callback, we execute it
    if( $self->{_on_conflict_callback} && !scalar( @_ ) )
    {
        # This will use the insert components set up to format our on conflict clause properly
        # The callback is needed, because the query formatting occurs after the calling of our method on_conflict()
        $self->{_on_conflict_callback}->();
    }
    return( $self->{on_conflict} );
}

sub reset
{
    my $self = shift( @_ );
    if( !$self->{query_reset} )
    {
        my $keys = [qw( alias binded binded_values binded_where binded_limit binded_group binded_having binded_order  from_unixtime group_by limit local _on_conflict on_conflict order_by reverse sorted unix_timestamp where )];
        CORE::delete( @$self{ @$keys } );
        $self->{query_reset}++;
        $self->{enhance} = 1;
    }
    return( $self );
}

sub reset_bind
{
    my $self = shift( @_ );
    my @f = qw( binded binded_where binded_group binded_having binded_order binded_limit );
    foreach my $field ( @f )
    {
        $self->{ $field } = [];
    }
    return( $self );
}

sub returning
{
    my $self = shift( @_ );
    my $tbl_o = $self->{table_object} || return( $self->error( "No table object is set." ) );
    if( @_ )
    {
        my $pg_version = $self->database_object->version;
        return( $self->error( "Cannot use returning for PostgreSQL version lower than 8.2. This server version is: $pg_version" ) ) if( $pg_version < '8.2' );
        # It could be a field name or a wildcard
        return( $self->error( "A reference was provided (", ref( $_[0] ), "), but I was expecting a string, which could be a field name or even a star (*) indicating all fields." ) ) if( ref( $_[0] ) );
        $self->{returning} = $self->new_clause( value => shift( @_ ) );
    }
    return( $self->{returning} );
}

sub server_prepare
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->prepare_options->set( 'pg_server_prepare' => shift( @_ ) );
    }
    return( $self->prepare_options->get( 'pg_server_prepare' ) );
}

sub _query_components
{
    my $self = shift( @_ );
    my $type = ( @_ > 0 && lc( shift( @_ ) ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my $opts = $self->_get_args_as_hash( @_ );
    # ok options:
    # no_bind_copy: because join for example does it already and this would duplicate the binded types, so we use this option to tell this method to set an exception. Kind of a hack that needs clean-up in the future from a design point of view.
    $opts->{no_bind_copy} //= 0;
    my( $where, $group, $having, $sort, $order, $limit, $returning, $on_conflict );

    $where = $self->where();
    if( $type eq 'select' )
    {
        $group  = $self->group;
        $having = $self->having;
        $sort   = $self->reverse ? 'DESC' : $self->sort ? 'ASC' : '';
        $order  = $self->order;
    }
    $limit = $self->limit;
    $returning = $self->returning;
    $on_conflict = $self->on_conflict;
    my @query = ();
    push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
    if( $where && $where->types->length )
    {
        # $self->binded_types->push( $where->bind->types->list ) unless( $opts->{no_bind_copy} );
        $self->elements->push( $where ) unless( $opts->{no_bind_copy} );
    }
    push( @query, "GROUP BY $group" ) if( $group && $type eq 'select'  );
    push( @query, "HAVING $having" ) if( $having && $type eq 'select'  );
    push( @query, "ORDER BY $order" ) if( $order && $type eq 'select'  );
    push( @query, $sort ) if( $sort && $order && $type eq 'select'  );
    if( $limit && $type eq 'select' )
    {
        push( @query, "$limit" );
        # if( $limit->bind->types->length )
        if( $limit->elements->length )
        {
            # $self->binded_types->push( $limit->bind->types->list ) unless( $opts->{no_bind_copy} );
            $self->elements->push( $limit ) unless( $opts->{no_bind_copy} );
        }
    }
    if( $on_conflict )
    {
        if( $type eq 'insert' )
        {
            push( @query, $on_conflict );
        }
        else
        {
            warn( "Warning only: the PostgreSQL ON CONFLICT clause is only supported for INSERT queries. Your query was of type \"$type\".\n" );
        }
    }
    push( @query, "RETURNING $returning" ) if( $returning && ( $type eq 'insert' || $type eq 'update' || $type eq 'delete' ) );
    return( \@query );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Postgres::Query - Query Object for PostgreSQL

=head1 SYNOPSIS

    use DB::Object::Postgres::Query;
    my $this = DB::Object::Postgres::Query->new || die( DB::Object::Postgres::Query->error, "\n" );

=head1 VERSION

    v0.3.1

=head1 DESCRIPTION

This is a Postgres specific query object.

=head1 METHODS

=head2 binded_having

Sets or gets the array object (L<Module::Generic::Array>) for the binded value in C<HAVING> clauses.

=head2 binded_types_as_param

Returns an array object (L<Module::Generic::Array>) of binded params types.

=head2 dollar_placeholder

Provided with a true value, and this will set the placeholder to be a dollar, such as C<$1>, C<$2>, etc for this query only.

It returns the current boolean value.

=head2 format_from_epoch

This takes the parameters I<bind> and I<value> and returns a formatted C<TO_TIMESTAMP> expression.

=head2 format_statement

This method is called to format C<select>, C<delete> and C<insert> query.

It takes the following parameters

=over 4

=item I<data>

=item I<order>

=item I<table>

=back

It uses the parameters passed to L<DB::Object::Query/select>, L<DB::Object::Query/delete> and L<DB::Object::Query/insert> and format them properly.

If no arguments were passed to those query methods, it will use a default sorted columns instead.

In list context, this returns the fields and values formatted as string, and in scalar context it returns the fields formatted.

=head2 format_to_epoch

This takes the parameters I<bind>, I<value> and I<quote>  and returns a formatted expression to returns the epoch value out of the given field.

=head2 having

Calls L<DB::Object::Query/_where_having> to build a C<having> clause.

=head2 limit

Build a new L<DB::Object::Query::Clause> clause object by calling L</_process_limit> and return it.

=head2 on_conflict

Provided with some options and this will build a C<ON CONFLICT> clause (L<DB::Object::Query::Clause>). This is only available for PostgreSQL version 9.5 or above.

=over 4

=item C<action>

Valid value can be C<nothing> and in which case, nothing will be done by the database upon conflict.

    INSERT INTO distributors (did, dname) VALUES (7, 'Redline GmbH')
        ON CONFLICT (did) DO NOTHING;

or

    INSERT INTO distributors (did, dname) VALUES (9, 'Antwerp Design')
        ON CONFLICT ON CONSTRAINT distributors_pkey DO NOTHING;

Value can also be C<ignore> instructing the database to simply ignore conflict.

If the value is C<update>, then this will set a callback routine to format an update statement using L<DB::Object::Query/format_update>

If the original C<insert> or C<update> uses placeholders, then the C<DO UPDATE> will also use the same placeholders and the L<DB::Object::Statement> object will act accordingly when being provided the binded values. That is, it will double them to allocate those binded value also for the C<DO UPDATE> part of the query.

The callback will be called by L<DB::Object::Query/insert> or L<DB::Object::Query/update>, because the L</on_conflict> relies on query columns being previously set.

=item C<fields>

An array (or array object) of fields to use with I<action> set to C<update>

    $q->on_conflict({
        target  => 'name',
        action  => 'update,
        fields  => [qw( first_name last_name )],
    });

This will turn the C<DO UPDATE> prepending each field with the special keyword C<EXCLUDED>

    INSERT INTO distributors (did, dname)
        VALUES (5, 'Gizmo Transglobal'), (6, 'Associated Computing, Inc')
        ON CONFLICT (did) DO UPDATE SET dname = EXCLUDED.dname;

=item C<target>

Target can be a table column.

    $q->on_conflict({
        target  => 'name',
        action  => 'ignore',
    });

or it can also be a constraint name:

    $q->on_conflict({
        target  => 'on constraint my_table_idx_name',
        action  => 'ignore',
    });

Value for I<target> can also be a scalar reference and it will be used as-is

    $q->on_conflict({
        target  => \'on constraint my_table_idx_name',
        action  => 'ignore',
    });

Value for I<target> can also be an array or array object (like L<Module::Generic::Array>) and the array will be joined using a comma.

If no I<target> argument was provided, then I<action> must be set to C<nothing> or this will return an error.

=item C<where>

You can also provide a C<WHERE> expression in the conflict and it will be added literally.

    $q->on_conflict({
        target  => 'did',
        action  => 'ignore',
        where   => 'is_active',
    });

    INSERT INTO distributors (did, dname) VALUES (10, 'Conrad International')
        ON CONFLICT (did) WHERE is_active DO NOTHING;

=back

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/sql-insert.html>.

=head2 reset

If the object property C<query_reset> is not already set, this will remove the following properties from the current query object, set L<DB::Object::Query/enhance> to true and return the query object.

Properties removed are: alias local binded binded_values binded_where binded_limit binded_group binded_having binded_order where limit group_by on_conflict _on_conflict order_by reverse from_unixtime unix_timestamp sorted

=head2 reset_bind

Reset all the following object properties to an anonymous array: binded binded_where binded_group binded_having binded_order binded_limit

=head2 returning

This feature is available with PostgreSQL version 8.2 or above, otherwise an error is returned.

It expects a string that is used to build the C<RETURNING> clause.

    # will instruct the database to return all the table columns
    $q->returning( '*' );

or

    $q->returning( 'id' );

But don't pass a reference:

    $q->returning( [qw( id name age )] );

It returns a new L<DB::Object::Postgres::Query::Clause> object.

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/dml-returning.html>

=head2 server_prepare

Sets or gets the boolean value for whether you want the sql statement to be prepared server-side or not.

Please see the warnings about this breaking change implemented since version 9.40 L<DBD::Pg/prepare>.

Since PostgreSQL does not see the parameters that are passed at statement execution, it is possible it misinterpret. Consider this:

    my $ip = '192.168.2.12';
    my $ip_tbl = $dbh->ip_registry;
    # Check if the ip match an ip block
    my $P = $dbh->placeholder( type => 'inet' );
    $ip_tbl->where( $dbh->OR( $ip_tbl->fo->ip_addr == "INET $P", "INET $P" << $ip_tbl->fo->ip_addr ) );
    $sth = $ip_tbl->select || die( "An error occurred while trying to format query to check if ip is in the registry." );
    $sth->exec( $ip, $ip ) || die( "An error occurred while trying to execute query to check if ip is in the registry: ", $sth->error );

This would yield the server error: C<syntax error at or near "$1">

The solution would be to de-activate server prepare for this query only:

    $ip_tbl->query_object->server_prepare(0);

=head2 _query_components

This is called by the various query methods like L<DB::Object::Query/select>, L<DB::Object::Query/insert>, L<DB::Object::Query/update>, L<DB::Object::Query/delete>

It will get the various query components (group, having, sort, order, limit) that have been set and add them formatted to an array that is returned.

This version of L</_query_components> exists here to provide PostgreSQL specific implementation. See also the generic one in L<DB::Object::Query/_query_components>

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
