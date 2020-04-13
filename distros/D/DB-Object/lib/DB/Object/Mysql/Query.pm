# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Mysql/Query.pm
## Version 0.3.6
## Copyright(c) 2019- DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/11/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Mysql::Query;
BEGIN
{
	use strict;
	use parent qw( DB::Object::Query );
	use Devel::Confess;
	our( $VERSION, $DEBUG, $VERBOSE );
	$VERSION = '0.3.6';
	$DEBUG = 0;
	$VERBOSE = 0;
};

sub init
{
	my $self = shift( @_ );
	$self->{ 'having' } = '';
	$self->SUPER::init( @_ );
	$self->{ 'binded_having' } = [];
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
		return( sprintf( "FROM_UNIXTIME(%s)", $opts->{value} ) );
	}
}

sub format_to_epoch
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) );
	if( $opts->{bind} )
	{
		return( "UNIX_TIMESTAMP(?)" );
	}
	else
	{
		return( sprintf( "UNIX_TIMESTAMP('%s')", $opts->{quote} ? "'" . $opts->{value} . "'" : $opts->{value} ) );
	}
}

## _having is in DB::Object::Query
sub having { return( shift->_where_having( 'having', 'having', @_ ) ); }

## http://www.postgresql.org/docs/9.3/interactive/queries-limit.html
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
        $select = $data->as_string();
    }
    %arg = @arg if( @arg );
    my $tbl_o = $self->table_object || return( $self->error( "No table object is set." ) );
    my $table   = $tbl_o->name ||
    return( $self->error( "No table was provided to replace data." ) );
    my $structure = $tbl_o->structure();
    my $null      = $tbl_o->null();
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
    my $query = $self->{ 'query' } = $select ? "REPLACE INTO $table $select" : "REPLACE INTO $table ($fields) VALUES($values)";
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
    if( !$self->{ 'query_reset' } )
    {
        map{ delete( $self->{ $_ } ) } qw( alias local binded binded_values binded_where binded_limit binded_group binded_having binded_order where limit group_by order_by reverse from_unixtime unix_timestamp sorted );
        $self->{ 'query_reset' }++;
        $self->{ 'enhance' } = 1;
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
	my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
	my( $where, $group, $having, $sort, $order, $limit );
    $where  = $self->where();
    if( $type eq "select" )
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
    	## $self->message( 3, "limit array value received contains: ", sub{ $self->dumper( \@offset_limit ) } );
    	## https://dev.mysql.com/doc/refman/5.7/en/update.html
    	## https://dev.mysql.com/doc/refman/5.7/en/delete.html
    	$limit = sprintf( 'LIMIT %d', $offset_limit[0] ) if( scalar( @offset_limit ) );
    }
    my @query = ();
	push( @query, $where ) if( $where );
	push( @query, $group ) if( $group  );
	push( @query, $having ) if( $having );
	push( @query, $order ) if( $order );
	push( @query, $sort ) if( $sort && $order );
	push( @query, $limit ) if( $limit );
	return( \@query );
}

sub _query_components
{
	my $self = shift( @_ );
	my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
	my( $where, $group, $having, $sort, $order, $limit );
    $where  = $self->where();
    if( $type eq "select" )
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
    	## $self->message( 3, "limit array value received contains: ", sub{ $self->dumper( \@offset_limit ) } );
    	## https://dev.mysql.com/doc/refman/5.7/en/update.html
    	## https://dev.mysql.com/doc/refman/5.7/en/delete.html
    	$limit = sprintf( 'LIMIT %d', $offset_limit[0] ) if( scalar( @offset_limit ) );
    }
    my @query = ();
    ## $self->message( 3, "\$where is '$where', \$group = '$group', \$having = '$having', \$order = '$order', \$limit = '$limit'." );
	push( @query, "WHERE $where" ) if( $where && $type ne 'insert' );
	push( @query, "GROUP BY $group" ) if( $group && $type eq 'select'  );
	push( @query, "HAVING $having" ) if( $having && $type eq 'select'  );
	push( @query, "ORDER BY $order" ) if( $order && $type eq 'select'  );
	push( @query, $sort ) if( $sort && $order && $type eq 'select'  );
	push( @query, "$limit" ) if( $limit && $type eq 'select' );
# 	$self->message( 3, "Query components are:" );
# 	foreach my $this ( @query )
# 	{
# 		$self->message( 3, "Query component: $this" );
# 	}
# 	$self->message( 3, "Returning query components: ", sub{ $self->dump( @query ) } );
	return( \@query );
}

1;

__END__
