# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Mysql/Query.pm
## Version v0.4.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2025/03/06
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Mysql::Query;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Query );
    use vars qw( $VERSION $DEBUG );
    use Wanted;
    our $DEBUG = 0;
    our $VERSION = 'v0.4.0';
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
    $opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] => 'strict' ) );
    if( $opts->{bind} )
    {
        return( "FROM_UNIXTIME(?)" );
    }
    else
    {
        return( sprintf( 'FROM_UNIXTIME(%s)', $opts->{value} ) );
    }
}

sub format_to_epoch
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] => 'strict' ) );
    if( $opts->{bind} )
    {
        return( 'UNIX_TIMESTAMP(?)' );
    }
    else
    {
        return( sprintf( "UNIX_TIMESTAMP(%s)", $opts->{quote} ? "'" . $opts->{value} . "'" : $opts->{value} ) );
    }
}

# _having is in DB::Object::Query
sub having { return( shift->_where_having( 'having', 'having', @_ ) ); }

# <https://dev.mysql.com/doc/refman/8.0/en/select.html>
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
                    ? CORE::sprintf( 'LIMIT %s, %s', $limit->metadata->offset, $limit->metadata->limit )
                    : CORE::sprintf( 'LIMIT %s', $limit->metadata->limit )
            );
        }
    }

    if( !$limit && want( 'OBJECT' ) )
    {
        return( $self->new_null( type => 'object' ) );
    }
    return( $limit );
}

# 4.1.0
# $q->on_conflict({
#     target => 'id',              # Optional: implies a specific key, but MySQL uses any duplicate key
#     action => 'nothing',         # No-op (ignore conflict)
#     action => 'update',          # Perform update on duplicate key
#     fields => { a => 'some value', b => 'some other' }, # Fields to update
# });
sub on_conflict
{
    my $self = shift( @_ );
    my $opts = {};
    $self->{_on_conflict} = {} if( ref( $self->{_on_conflict} ) ne 'HASH' );

    if( @_ )
    {
        my $tbl_o = $self->{table_object} || return( $self->error( "No table object is set." ) );
        # No version check needed—ON DUPLICATE KEY UPDATE is in MySQL since 4.1.0 (2004)
        my $ver = $tbl_o->database_object->version;
        if( version->parse( $ver ) < version->parse( '4.1.0' ) )
        {
            return( $self->error( "MySQL version is $ver, but version 4.1.0 or higher is required to use this on duplicate clause." ) );
        }

        $opts = $self->_get_args_as_hash( @_ );
        my $hash = {};
        my @comp = ('ON DUPLICATE KEY UPDATE');

        # Target is optional in MySQL—implicitly uses any duplicate key (primary or unique)
        if( $opts->{target} )
        {
            $hash->{target} = $opts->{target};
            # MySQL doesn’t support explicit constraint targeting (unlike PostgreSQL/SQLite),
            # so we store it for reference but don’t alter the query syntax.
            warn( "MySQL does not support explicit constraint targeting, so the target specified '$opts->{target}' will not be applied." ) if( $self->_is_warnings_enabled( 'DB::Object' ) );
        }

        # Action handling
        if( $opts->{action} )
        {
            if( $opts->{action} eq 'update' )
            {
                $hash->{action} = $opts->{action};

                # No fields provided—defer to callback using INSERT data
                if( !$opts->{fields} )
                {
                    $self->{_on_conflict_callback} = sub
                    {
                        my $f_ref = $self->{_args};
                        $self->is_upsert(1);
                        # Assuming this returns a formatted SET clause
                        my $elems = $self->format_update($f_ref);
                        push( @comp, $elems->formats->join( ', ' ) );
                        $hash->{query} = join(' ', @comp);
                        $self->{_on_conflict} = $hash;
                        $self->{on_conflict}  = join( ' ', @comp );
                        $self->elements->push( $elems->elements->list ) if( $elems->elements );
                        CORE::delete( $self->{_on_conflict_callback} );
                    };
                    # Empty string signals deferred processing
                    return( '' );
                }

                # Validate fields
                return( $self->error( "Fields property for on_conflict update must be a hash or array." ) )
                    if( !$self->_is_hash( $opts->{fields} => 'strict' ) && !$self->_is_array( $opts->{fields} ) && !$self->{_on_conflict_callback} );
                if( $self->_is_hash( $opts->{fields} => 'strict' ) )
                {
                    return( $self->error( "Fields property for on_conflict update contains no fields!" ) )
                        if( !scalar( keys( %{$opts->{fields}} ) ) );
                }
                elsif( $self->_is_array( $opts->{fields} ) )
                {
                    return( $self->error( "Fields property for on_conflict update contains no fields!" ) )
                        if( !scalar( @{$opts->{fields}} ) );
                }

                # Convert array fields to hash with VALUES(column)
                if( $self->_is_array( $opts->{fields} ) )
                {
                    $opts->{fields} = +{ map{ $_ => \"VALUES($_)" } @{$opts->{fields}} };
                }
                $hash->{fields} = $opts->{fields};

                # Build the SET clause
                my $q = [];
                foreach my $k ( sort( keys( %{$opts->{fields}} ) ) )
                {
                    my $val = $opts->{fields}->{ $k };
                    push( @$q, sprintf( '%s = %s', $k, ref( $val ) eq 'SCALAR' ? $$val : $tbl_o->database_object->quote( $val ) ) );
                }
                if( scalar( @$q ) )
                {
                    push( @comp, join( ', ', @$q ) );
                }
                else
                {
                    return( $self->error( "ON DUPLICATE KEY UPDATE specified, but no fields to update." ) );
                }
            }
            elsif( $opts->{action} eq 'nothing' || 
                   $opts->{action} eq 'ignore' )
            {
                # MySQL doesn’t have a native "do nothing" for ON DUPLICATE KEY UPDATE,
                # so we set a no-op (e.g., id = id)
                $hash->{action} = $opts->{action};
                # Fallback to 'id' if no PK defined
                my $pk = $tbl_o->primary_key || 'id';
                push( @comp, "$pk = $pk" );
            }
            else
            {
                return( $self->error( "Unknown action '$opts->{action}' for on_conflict clause." ) );
            }
        }
        else
        {
            return( $self->error( "No action specified for the on_conflict clause." ) );
        }

        $hash->{query} = join( ' ', @comp );
        $self->{_on_conflict} = $hash;
        $self->{on_conflict} = $self->new_clause({ value => join( ' ', @comp ) });
    }

    # Execute callback if called by _query_components
    if( $self->{_on_conflict_callback} && !scalar( @_ ) )
    {
        $self->{_on_conflict_callback}->();
    }
    return $self->{on_conflict};
}

# I know I could alias one on the other, but I want it to show up in the stack trace, so ti can be corrected.
sub on_update { return( shift->on_conflict( @_ ) ); }

sub replace
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    my %arg  = ();
    my $select = '';
    if( !%arg && $data && $self->_is_hash( $data => 'strict' ) )
    {
        %arg = %$data;
    }
    elsif( $data && $self->_is_object( $data ) && $data->isa( 'DB::Object::Statement' ) )
    {
        $select = $data->as_string;
    }
    %arg = @arg if( @arg );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table   = $tbl_o->name ||
    return( $self->error( "No table was provided to replace data." ) );
    my $structure = $tbl_o->structure || return( $self->pass_error( $tbl_o->error ) );
    my $null      = $tbl_o->null;
    my @avoid     = ();
    foreach my $field ( keys( %$structure ) )
    {
        ## It is useless to insert a blank data in a field whose default value is NULL.
        ## Especially since a test on a NULL field may be made specifically.
        push( @avoid, $field ) if( !exists( $arg{ $field } ) && $null->{ $field } );
    }
    $self->getdefault({
        table => $table, 
        arg => \@arg, 
        avoid => \@avoid
    });
    my( $fields, $values ) = $self->format_statement;
    ## $self->{ 'binded_values' } = $db_data->{ 'binded_values' };
    my $query = $self->{query} = $select ? "REPLACE INTO $table $select" : "REPLACE INTO $table ($fields) VALUES($values)";
    ## Everything meaningfull lies within the object
    ## If no bind should be done _save_bind does nothing
    $self->_save_bind();
    ## Query string should lie within the object
    ## _cache_this sends back an object no matter what or unde() if an error occurs
    my $sth = $tbl_o->_cache_this( $self );
    ## STOP! No need to go further
    if( !defined( $sth ) )
    {
        return( $self->error( "Error while preparing query to replace data into table '$table':\n$query", $self->errstr() ) );
    }
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to replace data to table '$table':\n$query" ) );
    }
    return( $sth );
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

# Not supported in MySQL
# sub returning

# Inherited from DB::Object::Query
# sub update

sub _query_components
{
    my $self = shift( @_ );
    my $type = ( @_ > 0 && lc( shift( @_ ) ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my $opts = $self->_get_args_as_hash( @_ );
    # ok options:
    # no_bind_copy: because join for example does it already and this would duplicate the binded types, so we use this option to tell this method to set an exception. Kind of a hack that needs clean-up in the future from a design point of view.
    $opts->{no_bind_copy} //= 0;
    my( $where, $group, $having, $sort, $order, $limit, $on_conflict );

    $where = $self->where();
    if( $type eq 'select' )
    {
        $group  = $self->group;
        $having = $self->having;
        $sort   = $self->reverse ? 'DESC' : $self->sort ? 'ASC' : '';
        $order  = $self->order;
    }
    $limit = $self->limit;
    $on_conflict = $self->on_conflict;
    my @query = ();
    push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
    if( $where && $where->types->length )
    {
        $self->elements->push( $where ) unless( $opts->{no_bind_copy} );
    }
    push( @query, "GROUP BY $group" ) if( $group && $type eq 'select'  );
    push( @query, "HAVING $having" ) if( $having && $type eq 'select'  );
    push( @query, "ORDER BY $order" ) if( $order && $type eq 'select'  );
    push( @query, $sort ) if( $sort && $order && $type eq 'select'  );
    if( $limit && $type eq 'select' )
    {
        push( @query, "$limit" );
        if( $limit->elements->length )
        {
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
            warn( "Warning only: the MySQL ON CONFLICT clause is only supported for INSERT queries. Your query was of type \"$type\".\n" );
        }
    }
    return( \@query );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Mysql::Query - Query Object for MySQL

=head1 SYNOPSIS

    use DB::Object::Mysql::Query;
    my $this = DB::Object::Mysql::Query->new || die( DB::Object::Mysql::Query->error, "\n" );

=head1 VERSION

    v0.4.0

=head1 DESCRIPTION

This is a MySQL specific query object.

=head1 METHODS

=head2 binded_having

Sets or gets the array object (L<Module::Generic::Array>) for the binded value in C<HAVING> clauses.

=head2 format_from_epoch

This takes the parameters I<bind> and I<value> and returns a formatted C<FROM_UNIXTIME> expression.

=head2 format_to_epoch

This takes the parameters I<bind>, I<value> and I<quote>  and returns a formatted expression to returns the epoch value out of the given field: C<UNIX_TIMESTAMP>

=head2 having

Calls L<DB::Object::Query/_where_having> to build a C<having> clause.

=head2 limit

Build a new L<DB::Object::Query::Clause> clause object by calling L</_process_limit> and return it.

=head2 on_conflict

Provided with some options, this will build an C<ON DUPLICATE KEY UPDATE> clause (L<DB::Object::Query::Clause>) for MySQL. This feature is available in MySQL since version 4.1.0, making it compatible with virtually all modern installations.

=over 4

=item C<action>

Valid values are C<nothing> (or C<ignore>) and C<update>.

If set to C<nothing> or C<ignore>, the query will perform a no-op update (e.g., C<id = id>) to effectively ignore the conflict. Note that MySQL does not natively support a "do nothing" option for C<ON DUPLICATE KEY UPDATE>, so this is emulated by setting a primary key or a default field (C<id>) to its current value.

    INSERT INTO mytable (id, a, b) VALUES (1, 'foo', 'bar')
        ON DUPLICATE KEY UPDATE id = id;

If set to C<update>, this will either use the provided C<fields> or set a callback routine to format an update statement using L<DB::Object::Query/format_update> based on the original C<INSERT> fields.

    INSERT INTO mytable (id, a, b) VALUES (1, 'foo', 'bar')
        ON DUPLICATE KEY UPDATE a = 'foo', b = 'bar';

If the original C<insert> uses placeholders, the C<ON DUPLICATE KEY UPDATE> will reuse those placeholders, and the L<DB::Object::Statement> object will double the bind values to accommodate both the C<INSERT> and C<UPDATE> portions of the query. The callback is triggered by L<DB::Object::Query/insert>, as C<on_conflict> relies on the query columns being previously set.

=item C<fields>

An array (or array object) or hash of fields to use with C<action> set to C<update>.

If an array is provided, each field is automatically mapped to C<VALUES(field)>, which references the proposed value from the C<INSERT>:

    $q->on_conflict({
        action => 'update',
        fields => [qw(a b)],
    });

    INSERT INTO mytable (id, a, b) VALUES (1, 'foo', 'bar')
        ON DUPLICATE KEY UPDATE a = VALUES(a), b = VALUES(b);

If a hash is provided, the keys are the fields to update, and the values can be literal values or scalar references for raw expressions:

    $q->on_conflict({
        action => 'update',
        fields => { a => 'new_val', b => \'b + 1' },
    });

    INSERT INTO mytable (id, a, b) VALUES (1, 'foo', 'bar')
        ON DUPLICATE KEY UPDATE a = 'new_val', b = b + 1;

If no C<fields> are provided with C<action => 'update'>, the fields from the original C<INSERT> will be used via a callback.

=item C<target>

An optional target specification, such as a column name or constraint. However, MySQL’s C<ON DUPLICATE KEY UPDATE> does not allow targeting a specific key constraint or column explicitly—it triggers on any duplicate key violation (primary key or unique index). The C<target> is stored for reference and logged, but it does not alter the query behavior.

    $q->on_conflict({
        target => 'id',
        action => 'update',
        fields => { a => 'new' },
    });

    # Logs: "Target 'id' specified, but MySQL will use any duplicate key constraint."
    INSERT INTO mytable (id, a, b) VALUES (1, 'foo', 'bar')
        ON DUPLICATE KEY UPDATE a = 'new';

Value for C<target> can also be a scalar reference (used as-is in logging) or an array (joined with commas), though these have no effect on the MySQL query syntax.

=item C<where>

Unlike PostgreSQL and SQLite, MySQL’s C<ON DUPLICATE KEY UPDATE> does not support a C<WHERE> clause. If provided, it will be ignored and a debug message logged, but no error will be raised to maintain API consistency across drivers.

    $q->on_conflict({
        action => 'update',
        fields => { a => 'new' },
        where  => 'a > 0', # Ignored in MySQL
    });

    INSERT INTO mytable (id, a, b) VALUES (1, 'foo', 'bar')
        ON DUPLICATE KEY UPDATE a = 'new';

=back

See L<MySQL documentation for more information|https://dev.mysql.com/doc/refman/8.0/en/insert-on-duplicate.html>.

=head2 on_update

This is an alias for L<on_conflict|/on_conflict>

=head2 replace

This method can take either 1 parameter which would then be a L<DB::Object::Statement> object, or it can also be an hash reference of options.

It can alternatively take an hash of options.

If a statement was provided, it will be stringified calling L<DB::Object::Statement/as_string> and used as a select query in the C<replace> statement.

When preparing the C<replace> query, this will be mindful to avoid fields that are C<null> by default and not provided among the options.

If called in void context, this will execute the prepared statement immediately.

It returns the prepared statement handler (L<DB::Object::Statement>).

=head2 reset

If the object property C<query_reset> is not already set, this will remove the following properties from the current query object, set L<DB::Object::Query/enhance> to true and return the query object.

Properties removed are: alias local binded binded_values binded_where binded_limit binded_group binded_having binded_order where limit group_by order_by reverse from_unixtime unix_timestamp sorted

=head2 reset_bind

Reset all the following object properties to an anonymous array: binded binded_where binded_group binded_having binded_order binded_limit

=head2 _query_components

This is called by the various query methods like L<DB::Object::Query/select>, L<DB::Object::Query/insert>, L<DB::Object::Query/update>, L<DB::Object::Query/delete>

It will get the various query components (group, having, sort, order, limit) that have been set and add them formatted to an array that is returned.

This version of L</_query_components> exists here to provide MySQL specific implementation. See also the generic one in L<DB::Object::Query/_query_components>

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
