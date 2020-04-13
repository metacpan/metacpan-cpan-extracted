# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/SQLite/Query.pm
## Version 0.3.7
## Copyright(c) 2019- DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/06/16
## Modified 2019/11/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::SQLite::Query;
BEGIN
{
	use strict;
	use parent qw( DB::Object::Query );
	use Devel::Confess;
	our( $VERSION, $DEBUG, $VERBOSE );
	$VERSION = '0.3.7';
	$DEBUG = 0;
	$VERBOSE = 0;
};

sub init
{
	my $self = shift( @_ );
	$self->{having} = '';
	$self->SUPER::init( @_ );
	$self->{binded_having} = [];
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

## _having is in DB::Object::Query
## sub having { return( shift->_having( @_ ) ); }
sub having { return( shift->_where_having( 'having', 'having', @_ ) ); }

## http://www.postgresql.org/docs/9.3/interactive/queries-limit.html
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

sub reset
{
	my $self = shift( @_ );
    if( !$self->{query_reset} )
    {
        map{ delete( $self->{ $_ } ) } qw( alias local binded binded_values binded_where binded_limit binded_group binded_having binded_order where limit group_by order_by reverse from_unixtime unix_timestamp sorted );
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

## Not supported by SQLite
## sub returning

## Inherited from DB::Object::Query
## sub update

sub _query_components
{
	my $self = shift( @_ );
	my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
    my $tbl_o = $self->{table_object} || return( $self->error( "No table object is set." ) );
	my( $where, $group, $having, $sort, $order, $limit, $returning );
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
    	if( $tbl_o->can_update_delete_limit )
    	{
    		$limit = $self->limit();
    	}
    }
    ## Not supported
    ## $returning = $self->returning;
    my @query = ();
	push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
	push( @query, "GROUP BY $group" ) if( $group );
	push( @query, "HAVING $having" ) if( $having );
	push( @query, "ORDER BY $order" ) if( $order );
	push( @query, $sort ) if( $sort && $order);
	push( @query, $limit ) if( $limit );
    ## Not supported
	## push( @query, $returning ) if( $type eq 'insert' || $type eq 'update' );
	return( \@query );
}

1;

__END__
