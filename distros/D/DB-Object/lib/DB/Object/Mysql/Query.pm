# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Mysql/Query.pm
## Version v0.3.7
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2023/02/24
## All rights reserved
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
    use Devel::Confess;
    use Want;
    our $DEBUG = 0;
    our $VERSION = 'v0.3.7';
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
    $self->{query_reset_keys} = [qw( alias binded binded_values binded_where binded_limit binded_group binded_having binded_order from_unixtime group_by limit local order_by reverse sorted unix_timestamp where )];
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
    $opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) );
    if( $opts->{bind} )
    {
        return( 'UNIX_TIMESTAMP(?)' );
    }
    else
    {
        return( sprintf( "UNIX_TIMESTAMP('%s')", $opts->{quote} ? "'" . $opts->{value} . "'" : $opts->{value} ) );
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

sub replace
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    my %arg  = ();
    my $select = '';
    if( !%arg && $data && $self->_is_hash( $data ) )
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
    my( $fields, $values ) = $self->format_statement();
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
        my $keys = [qw( alias binded binded_values binded_where binded_limit binded_group binded_having binded_order from_unixtime group_by limit local order_by reverse sorted unix_timestamp where )];
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

## Not supported in MySQL
## sub returning

## Inherited from DB::Object::Query
## sub update

sub _query_components
{
    my $self = shift( @_ );
    my $type = ( @_ > 0 && lc( shift( @_ ) ) ) || $self->_query_type() || return( $self->error( 'You must specify a query type: select, insert, update or delete' ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $where, $group, $having, $sort, $order, $limit );
    $where  = $self->where();
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
        my( @offset_limit ) = $self->limit;
        ## https://dev.mysql.com/doc/refman/5.7/en/update.html
        ## https://dev.mysql.com/doc/refman/5.7/en/delete.html
        $limit = sprintf( 'LIMIT %d', $offset_limit[0] ) if( scalar( @offset_limit ) );
    }
    my @query = ();
    push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
    push( @query, "GROUP BY $group" ) if( $group && $type eq 'select'  );
    push( @query, "HAVING $having" ) if( $having && $type eq 'select'  );
    push( @query, "ORDER BY $order" ) if( $order && $type eq 'select'  );
    push( @query, $sort ) if( $sort && $order && $type eq 'select'  );
    push( @query, "$limit" ) if( $limit && $type eq 'select' );
#     foreach my $this ( @query )
#     {
#     }
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

    v0.3.7

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
