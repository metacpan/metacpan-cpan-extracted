# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/SQLite/Query.pm
## Version v0.3.8
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/06/16
## Modified 2021/08/18
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::SQLite::Query;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Query );
    use vars qw( $VERSION $DEBUG $VERBOSE );
    $VERSION = 'v0.3.8';
    $DEBUG = 0;
    $VERBOSE = 0;
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

sub binded_having { return( shift->_set_get( 'binded_having', @_ ) ); }

sub format_from_epoch
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) );
    if( $opts->{bind} )
    {
        return( "DATETIME(?, 'unixepoch', 'localtime')" );
    }
    else
    {
        return( sprintf( "DATETIME(%s, 'unixepoch', 'localtime')", $opts->{value} ) );
    }
}

sub format_to_epoch
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) );
    if( $opts->{bind} )
    {
        return( "STRFTIME('%s',?)" );
    }
    else
    {
        return( sprintf( "STRFTIME('%%s','%s')", $opts->{quote} ? "'" . $opts->{value} . "'" : $opts->{value} ) );
    }
}

# _having is in DB::Object::Query
# sub having { return( shift->_having( @_ ) ); }
sub having { return( shift->_where_having( 'having', 'having', @_ ) ); }

# https://sqlite.org/limits.html
sub limit
{
    my $self  = shift( @_ );
    my $limit = $self->_process_limit( @_ );
    if( CORE::length( $limit->metadata->limit ) )
    {
        $limit->generic( CORE::length( $limit->metadata->offset ) ? ' LIMIT ? OFFSET ?' : 'LIMIT ?' );
        $limit->value( CORE::length( $limit->metadata->offset ) ? CORE::sprintf( 'LIMIT %d OFFSET %d', $limit->metadata->limit, $limit->metadata->offset ) : CORE::sprintf( 'LIMIT %d', $limit->metadata->limit ) );
                                                                                                                                                                                                                                                                                                                                                                            }
    return( $limit );
}

# This implementation in SQLite is essentially identical to PostgreSQL
# INSERT INTO vocabulary(word) VALUES('jovial')
#   ON CONFLICT(word) DO UPDATE SET count=count+1;
#
# INSERT INTO phonebook(name,phonenumber) VALUES('Alice','704-555-1212')
#   ON CONFLICT(name) DO UPDATE SET phonenumber=excluded.phonenumber;
#
#
# INSERT INTO phonebook2(name,phonenumber,validDate)
#   VALUES('Alice','704-555-1212','2018-05-08')
#   ON CONFLICT(name) DO UPDATE SET
#     phonenumber=excluded.phonenumber,
#     validDate=excluded.validDate
#   WHERE excluded.validDate>phonebook2.validDate;
# https://www.sqlite.org/lang_upsert.html
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
        if( version->parse( $ver ) < version->parse( '3.24.0' ) )
        {
            return( $self->error( "SQLite version is $ver, but version 3.24.0 of 2018-06-04 or higher is required to use this on conflict clause." ) );
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
                    # The insert will have triggered a getdefault() which stores the parameters into a _args object fields
#                     my $f_ref = $self->{ '_args' };
#                     $opts->{inherited_fields} = $self->format_update( $f_ref );
                    $self->{_on_conflict_callback} = sub
                    {
                        my $f_ref = $self->{_args};
                        $self->is_upsert(1);
                        my $inherited_fields = $self->format_update( $f_ref );
                        push( @comp, 'DO UPDATE SET' );
                        push( @comp, $inherited_fields );
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
        my $keys = [qw( alias binded binded_values binded_where binded_limit binded_group binded_having binded_order from_unixtime group_by limit local _on_conflict on_conflict order_by reverse sorted unix_timestamp where )];
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

# Supported by SQLite since 3.35.0 (2021-03-12)
# <https://www.sqlite.org/lang_returning.html>
sub returning
{
    my $self = shift( @_ );
    my $tbl_o = $self->{table_object} || return( $self->error( "No table object is set." ) );
    if( @_ )
    {
        my $pg_version = $self->database_object->version;
        return( $self->error( "Cannot use returning for PostgreSQL version lower than 3.35.0 (released on 2021-03-12). This server version is: $pg_version" ) ) if( $pg_version < '3.35.0' );
        # It could be a field name or a wildcard
        return( $self->error( "A reference was provided (", ref( $_[0] ), "), but I was expecting a string, which could be a field name or even a star (*) indicating all fields." ) ) if( ref( $_[0] ) );
        $self->{returning} = $self->new_clause({ value => shift( @_ ) });
    }
    # return( wantarray() ? () : undef() ) if( !$self->{returning} );
    # return( wantarray() ? ( $self->{returning} ) : "RETURNING $self->{returning}" );
    return( $self->{returning} );
}

# Inherited from DB::Object::Query
# sub update

sub _query_components
{
    my $self = shift( @_ );
    my $type = ( @_ > 0 && lc( shift( @_ ) ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tbl_o = $self->{table_object} || return( $self->error( "No table object is set." ) );
    my( $where, $group, $having, $sort, $order, $limit, $returning, $on_conflict );
    $where  = $self->where();
    $limit  = $self->limit();
    $returning = $self->returning;
    $on_conflict = $self->on_conflict;
    if( $type eq 'select' )
    {
        $group  = $self->group();
        $having = $self->having();
        $sort  = $self->reverse() ? 'DESC' : $self->sort() ? 'ASC' : '';
        $order  = $self->order();
        $limit  = $self->limit();
    }
    elsif( $type eq 'update' || $type eq 'delete' )
    {
        if( $tbl_o->can_update_delete_limit )
        {
            $limit = $self->limit();
        }
    }
    my @query = ();
    push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
    push( @query, "GROUP BY $group" ) if( $group );
    push( @query, "HAVING $having" ) if( $having );
    push( @query, "ORDER BY $order" ) if( $order );
    push( @query, $sort ) if( $sort && $order);
    push( @query, $limit ) if( $limit );
    if( $on_conflict )
    {
        if( $type eq 'insert' )
        {
            push( @query, $on_conflict );
        }
        else
        {
            warn( "The SQLite ON CONFLICT clause is only supported for INSERT queries. Your query was of type \"$type\".\n" );
        }
    }
    # Supported as of 3.35.0 (2021-03-12)
    push( @query, "RETURNING $returning" ) if( $returning && ( $type eq 'insert' || $type eq 'update' || $type eq 'delete' ) );
    return( \@query );
}

1;

__END__

=encoding utf-8

=head1 NAME

DB::Object::SQLite::Query - SQLite Query Object

=head1 SYNOPSIS

    my $q = DB::Object::SQLite::Query->new;

=head1 VERSION

    v0.3.8

=head1 DESCRIPTION

This is a SQLite specific query object.

=head1 METHODS

=head2 binded_having

Sets or gets the array object (L<Module::Generic::Array>) for the binded value in C<HAVING> clauses.

=head2 format_from_epoch

This takes the parameters I<bind> and I<value> and returns a formatted C<DATETIME(?, 'unixepoch', 'localtime')> expression.

=head2 format_to_epoch

This takes the parameters I<bind>, I<value> and I<quote>  and returns a formatted expression C<STRFTIME('%s',?)> to returns the epoch value out of the given field.

=head2 having

Calls L<DB::Object::Query/_where_having> to build a C<having> clause.

See L<SQLite documentation for more information|https://www.sqlite.org/lang_select.html>

=head2 limit

Build a new L<DB::Object::Query::Clause> clause object by calling L</_process_limit> and return it.

See L<SQLite documentation for more information|https://sqlite.org/limits.html>

=head2 on_conflict

Provided with some options and this will build a C<ON CONFLICT> clause (L<DB::Object::Query::Clause>). This is only available for SQLite version 3.35.0 released on 2021-03-12 or above.

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

See L<SQLite documentation for more information|https://www.sqlite.org/lang_upsert.html>.

=head2 reset

If the object property C<query_reset> is not already set, this will remove the following properties from the current query object, set L<DB::Object::Query/enhance> to true and return the query object.

Properties removed are: alias local binded binded_values binded_where binded_limit binded_group binded_having binded_order where limit group_by order_by reverse from_unixtime unix_timestamp sorted

=head2 reset_bind

Reset all the following object properties to an anonymous array: binded binded_where binded_group binded_having binded_order binded_limit

=head2 returning

This feature is available with SQLite version 3.35.0 or above, otherwise an error is returned.

It expects a string that is used to build the C<RETURNING> clause.

    # will instruct the database to return all the table columns
    $q->returning( '*' );

or

    $q->returning( 'id' );

But don't pass a reference:

    $q->returning( [qw( id name age )] );

It returns a new L<DB::Object::SQLite::Query::Clause> object.

See L<SQLite documentation for more information|https://www.sqlite.org/lang_returning.html>

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
