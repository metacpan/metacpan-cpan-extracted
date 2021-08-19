# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres/Query.pm
## Version v0.1.5
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2021/08/18
## All rights reserved
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
    use Devel::Confess;
    our( $VERSION, $DEBUG, $VERBOSE );
    $VERSION = 'v0.1.5';
};

{
    $DEBUG   = 0;
    $VERBOSE = 0;
}

sub init
{
    my $self = shift( @_ );
    $self->{having} = '';
    $self->SUPER::init( @_ );
    $self->{binded_having} = [];
    return( $self );
}

sub binded_having { return( shift->_set_get_array_as_object( 'binded_having', @_ ) ); }

sub binded_types_as_param
{
    my $self = shift( @_ );
    my $types = $self->binded_types;
    my $params = $self->new_array;
    foreach my $t ( @$types )
    {
        if( CORE::length( $t ) )
        {
            # CORE::push( @$params, { pg_type => $t } );
            $params->push( { pg_type => $t } );
        }
        else
        {
            # CORE::push( @$params, '' );
            $params->push( '' );
        }
    }
    return( $params );
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
    my $opts = {};
    $opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) );
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

sub format_statement
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    # Should we use bind statement?
    my $bind   = $tbl_o->use_bind;
    $self->message( 3, "Formatting statement with table '", $tbl_o->name, "' object '$tbl_o', alias '", $tbl_o->query_object->table_alias, "' and bind value '$bind'." );
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
    $self->message( 3, "Saved arguments (never mind the surrounding quotes) are: '", join( "', '", @$args ), "'." );
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
    # $self->message( 3, "Fields found are: ", sub{ $self->printer( $order ) } );
    my @format_fields = ();
    my @format_values = ();
    my $binded   = $self->{binded_values} = [];
    # my $multi_db = $tbl_o->param( 'multi_db' );
    my $multi_db = $tbl_o->prefix_database;
    my $prefix   = $tbl_o->prefix;
    my $db       = $tbl_o->database;
    my $field_prefix = $tbl_o->query_object->table_alias ? $tbl_o->query_object->table_alias : $prefix;
    my $fields_ref = $tbl_o->fields();
    # $self->message( 3, "Other fields found are: ", sub{ $self->printer( $fields_ref ) } );
    my $ok_list  = CORE::join( '|', keys( %$fields_ref ) );
    my $tables   = CORE::join( '|', @{$tbl_o->database_object->tables} );
    my $struct   = $tbl_o->structure();
    my $types    = $tbl_o->types;
    my $query_type = $self->{query_type};
    # $self->message( 3, "Fields order is: ", sub{ $self->dumper( $order ) } );
    my @sorted   = ();
    my @types    = ();
    if( @$args && !( @$args % 2 ) )
    {
        for( my $i = 0; $i < @$args; $i++ )
        {
            push( @sorted, $args->[ $i ] ) if( exists( $order->{ $args->[ $i ] } ) );
            $i++;
        }
    }
    @sorted = sort{ $order->{ $a } <=> $order->{ $b } } keys( %$order ) if( !@sorted );
    # $self->message( 3, "Sorted fields are: '", join( "', '", @sorted ), "'." );
    # Used for insert or update so that execute can take a hash of key => value pair and we would bind the values in the right order
    # But or that we need to know the order of the fields.
    $self->{sorted} = \@sorted;
    
    foreach( @sorted )
    {
        next if( $struct->{ $_ } =~ /\bSERIAL\b/i );
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
                # push( @format_values, sprintf( "FROM_UNIXTIME('%s') AS $_", $data->{ $_ } ) );
                if( $bind )
                {
                    push( @$binded, $value );
                    # push( @format_values, "FROM_UNIXTIME( ? )" );
                    push( @format_values, $self->format_from_epoch({ value => $value, bind => 1 }) );
                }
                else
                {
                    # push( @format_values, "FROM_UNIXTIME($value)" );
                    push( @format_values, $self->format_from_epoch({ value => $value, bind => 0 }) );
                }
            }
            elsif( ref( $value ) eq 'SCALAR' )
            {
                push( @format_values, $$value );
            }
            elsif( $value eq '?' )
            {
                push( @format_values, '?' );
                CORE::push( @types, '' );
            }
            elsif( $struct->{ $_ } =~ /^\s*\bBLOB\b/i )
            {
                push( @format_values, '?' );
                push( @$binded, $value );
                if( lc( $types->{ $_ } ) eq 'bytea' )
                {
                    CORE::push( @types, DBD::Pg::PG_BYTEA );
                }
                else
                {
                    CORE::push( @types, '' );
                }
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
                if( lc( $types->{ $_ } ) eq 'bytea' )
                {
                    push( @format_values, $tbl_o->quote( $value, DBD::Pg::PG_BYTEA ) );
                }
                # Value is a hash and the data type is json, so we transform this value into a json data
                elsif( $self->_is_hash( $value ) && ( lc( $types->{ $_ } ) eq 'jsonb' || lc( $types->{ $_ } ) eq 'json' ) )
                {
                    my $this_json = $self->_encode_json( $value );
                    push( @format_values, $tbl_o->quote( $this_json, ( lc( $types->{ $_ } ) eq 'jsonb' ? DBD::Pg::PG_JSONB : DBD::Pg::PG_JSON ) ) );
                }
                else
                {
                    # push( @format_values, sprintf( "'%s'", quotemeta( $value ) ) );
                    push( @format_values, sprintf( "%s", $tbl_o->quote( $value ) ) );
                }
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
                if( lc( $types->{ $_ } ) eq 'bytea' )
                {
                    CORE::push( @types, DBD::Pg::PG_BYTEA );
                }
                else
                {
                    CORE::push( @types, '' );
                }
            }
            # In last resort, we handle the formatting ourself
            else
            {
                # push( @format_values, "'" . quotemeta( $value ) . "'" );
                if( lc( $types->{ $_ } ) eq 'bytea' )
                {
                    push( @format_values, $tbl_o->quote( $value, DBD::Pg::PG_BYTEA ) );
                }
                else
                {
                    push( @format_values, $tbl_o->quote( $value ) );
                }
            }
        }
    
        if( $field_prefix ) 
        {
            # $self->message_colour( 3, "Prefix to be used is '<green>$field_prefix</>'." );
            s{
                (?<!\.)\b($ok_list)\b(\s*)?(?!\.)
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
            s/(?<!\.)($tables)(?:\.)/$db\.$1\./g if( $multi_db );
            push( @format_fields, $_ );
        }
        else
        {
            push( @format_fields, $_ );
        }
    }
    $self->messagef( 3, "Adding initial %d types to the existing %d binded types.", scalar( @types ), $self->binded_types->length );
    $self->binded_types->push( @types ) if( scalar( @types ) );
    # $self->message( 3, "Binded types are: ", sub{ $self->dumper( $self->{binded_types} ) } );
    if( !wantarray() && scalar( @{$self->{_extra}} ) )
    {
        push( @format_fields, @{$self->{_extra}} );
    }
    # $self->message( 3, "Formatted fields are: ", sub{ $self->dump( @format_fields ) });
    $values = CORE::join( ', ', @format_values );
    $fields = CORE::join( ', ', @format_fields );
    wantarray ? return( $fields, $values ) : return( $fields );
}

# _having is in DB::Object::Query
# sub having { return( shift->_having( @_ ) ); }
sub having { return( shift->_where_having( 'having', 'having', @_ ) ); }

# http://www.postgresql.org/docs/9.3/interactive/queries-limit.html
sub limit
{
    my $self  = shift( @_ );
    my $limit = $self->_process_limit( @_ );
    if( CORE::length( $limit->metadata->limit ) )
    {
        $limit->generic( CORE::length( $limit->metadata->offset ) ? 'OFFSET ? LIMIT ?' : 'LIMIT ?' );
        $limit->value( CORE::length( $limit->metadata->offset ) ? CORE::sprintf( 'OFFSET %d LIMIT %d', $limit->metadata->offset, $limit->metadata->limit ) : CORE::sprintf( 'LIMIT %d', $limit->metadata->limit ) );
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
#         $self->message( 3, "Option are: ", sub{ $self->dump( $opts ) } );
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
                    # The insert will have triggered a getdefault() which stores the parameters into a _args object fields
#                     my $f_ref = $self->{ '_args' };
#                     $self->message( 3, "Re-using the insert query parameters: ", join( ', ', @$f_ref ) );
#                     $opts->{inherited_fields} = $self->format_update( $f_ref );
#                     $self->message( 3, "Update query fields are: ", $opts->{inherited_fields} );
                    $self->{_on_conflict_callback} = sub
                    {
                        my $f_ref = $self->{_args};
                        $self->message( 3, "Re-using the insert query parameters: ", join( ', ', @$f_ref ) );
                        # Need to account for placeholders
                        # Let's check values only
                        # XXX The format_update call already does add the binded types
#                         my $binded_types = [];
#                         for( my $i = 1; $i < scalar( @$f_ref ); $i += 2 )
#                         {
#                             if( $f_ref->[$i] eq '?' )
#                             {
#                                 # Setting a blank will force the DB::Object::Statement to figure out the type
#                                 CORE::push( @$binded_types, '' );
#                             }
#                         }
#                         $self->binded_types->push( @$binded_types ) if( scalar( @$binded_types ) );
                        $self->messagef( 3, "So far, there are %d binded types.", $self->binded_types->length );
                        $self->is_upsert(1);
                        my $inherited_fields = $self->format_update( $f_ref );
                        $self->message( 3, "Update query fields are: ", $inherited_fields );
                        push( @comp, 'DO UPDATE SET' );
                        push( @comp, $inherited_fields );
                        # $self->message( 3, "Components are: ", sub{ $self->dump( @comp ) } );
                        $hash->{query} = join( ' ', @comp );
                        $self->{_on_conflict} = $hash;
                        $self->{on_conflict} = join( ' ', @comp );
                        # Usable only once
                        CORE::delete( $self->{_on_conflict_callback} );
                    };
                    # Return empty, not undef; undef is error
                    return( '' );
                }
                return( $self->error( "Fields property to update for on conflict do update clause is not a hash reference nor an array of fields." ) ) if( !$self->_is_hash( $opts->{fields} ) && !$self->_is_array( $opts->{fields} ) && !$self->{_on_conflict_callback} );
                if( $self->_is_hash( $opts->{fields} ) )
                {
                    return( $self->error( "Fields property to update for on conflict do update clause contains no fields!" ) ) if( !scalar( keys( %{$opts->{fields}} ) ) );
                }
                elsif( $self->_is_array( $opts->{fields} ) )
                {
                    return( $self->error( "Fields property to update for on conflict do update clause contains no fields!" ) ) if( !scalar( @{$opts->{fields}} ) );
                }
                
                if( $self->_is_array( $opts->{fields} ) )
                {
                    $self->message( 3, "Provided fields as array, generating the hash." );
                    my $this = $opts->{fields};
                    my $new = {};
                    foreach my $f ( @$this )
                    {
                        $new->{ $f } = \( 'EXCLUDED.' . $f );
                    }
                    $opts->{fields} = $new;
                    $self->message( 3, "fields property is now: ", sub{ $self->dump( $new ) } );
                }
                # Here the user will use the special table 'excluded'
                $hash->{fields} = $opts->{fields};
                
                my $q = [];
            
                foreach my $k ( sort( keys( %{$opts->{fields}} ) ) )
                {
                    push( @$q, sprintf( '%s = %s', $k, ref( $opts->{fields}->{ $k } ) eq 'SCALAR' ? ${$opts->{fields}->{ $k }} : $tbl_o->quote( $opts->{fields}->{ $k } ) ) );
                }
                if( scalar( @$q ) )
                {
                    push( @comp, 'DO UPDATE SET' );
                    push( @comp, join( ", ", @$q ) );
                }
                else
                {
                    return( $self->error( "A on conflict do update clause was specified, but I could not get a list of fields to update." ) );
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
        # $self->message( 3, "Components are: ", sub{ $self->dump( @comp ) } );
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
        $self->message( 3, "Calling the on_conflict callback." );
        $self->{_on_conflict_callback}->();
    }
    return( $self->{on_conflict} );
}

sub reset
{
    my $self = shift( @_ );
    if( !$self->{query_reset} )
    {
        my $keys = [qw( alias local binded binded_values binded_where binded_limit binded_group binded_having binded_order where limit group_by on_conflict _on_conflict order_by reverse from_unixtime unix_timestamp sorted )];
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
        $self->{returning} = $self->new_clause({ value => shift( @_ ) });
    }
    # return( wantarray() ? () : undef() ) if( !$self->{returning} );
    # return( wantarray() ? ( $self->{returning} ) : "RETURNING $self->{returning}" );
    return( $self->{returning} );
}

sub _query_components
{
    my $self = shift( @_ );
    my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my( $where, $group, $having, $sort, $order, $limit, $returning, $on_conflict );
    $where  = $self->where();
    if( $type eq "select" )
    {
        $group  = $self->group();
        $having = $self->having();
        $sort  = $self->reverse() ? 'DESC' : $self->sort() ? 'ASC' : '';
        $order  = $self->order();
    }
    $limit  = $self->limit();
    $returning = $self->returning;
    $on_conflict = $self->on_conflict;
    my @query = ();
    # $self->message( 3, "\$where is '$where', \$group = '$group', \$having = '$having', \$order = '$order', \$limit = '$limit', \$on_conflict = '$on_conflict'." );
    push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
    if( $where->bind->types->length )
    {
        $self->messagef( 3, "Adding binded type from the where clause to the overall %d binded types.", $where->bind->types->length, $self->binded_types->length );
        $self->binded_types->push( $where->bind->types->list );
    }
    push( @query, "GROUP BY $group" ) if( $group && $type eq 'select'  );
    push( @query, "HAVING $having" ) if( $having && $type eq 'select'  );
    push( @query, "ORDER BY $order" ) if( $order && $type eq 'select'  );
    push( @query, $sort ) if( $sort && $order && $type eq 'select'  );
    if( $limit && $type eq 'select' )
    {
        push( @query, "$limit" );
        if( $limit->bind->types->length )
        {
            $self->messagef( 3, "Adding binded type from the limit clause to the overall %d binded types.", $limit->bind->types->length, $self->binded_types->length );
            $self->binded_types->push( $limit->bind->types->list );
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
            warn( "The PostgreSQL ON CONFLICT clause is only supported for INSERT queries. Your query was of type \"$type\".\n" );
        }
    }
    push( @query, "RETURNING $returning" ) if( $returning && ( $type eq 'insert' || $type eq 'update' || $type eq 'delete' ) );
#     $self->message( 3, "Query components are:" );
#     foreach my $this ( @query )
#     {
#         $self->message( 3, "Query component: $this" );
#     }
#     $self->message( 3, "Returning query components: ", sub{ $self->dump( @query ) } );
    return( \@query );
}

1;

# XXX POD

__END__

=encoding utf-8

=head1 NAME

DB::Object::Postgres::Query - Query Object for PostgreSQL

=head1 SYNOPSIS

    use DB::Object::Postgres::Query;
    my $this = DB::Object::Postgres::Query->new || die( DB::Object::Postgres::Query->error, "\n" );

=head1 VERSION

    v0.1.5

=head1 DESCRIPTION

This is a Postgres specific query object.

=head1 METHODS

=head2 binded_having

Sets or gets the array object (L<Module::Generic::Array>) for the binded value in C<HAVING> clauses.

=head2 binded_types_as_param

Returns an array object (L<Module::Generic::Array>) of binded params types.

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

=item I<action>

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

=item I<fields>

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

=item I<target>

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

=item I<where>

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
