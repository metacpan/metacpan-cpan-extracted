# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/SQLite/Statement.pm
## Version v0.300.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2017/07/19
## Modified 2020/05/22
## 
##----------------------------------------------------------------------------
## This package's purpose is to automatically terminate the statement object and
## separate them from the connection object (DB::Object).
## Connection object last longer than statement objects
##----------------------------------------------------------------------------
package DB::Object::SQLite::Statement;
BEGIN
{
    require 5.6.0;
    use strict;
    use IO::File;
    use DB::Object::SQLite;
    use DB::Object::Statement;
    use parent qw( DB::Object::SQLite DB::Object::Statement );
    our( $VERSION, $VERBOSE, $DEBUG );
    $VERSION    = 'v0.300.1';
    $VERBOSE    = 0;
    $DEBUG        = 0;
    use Devel::Confess;
};

## Inherited from DB::Object::Statement
## sub bind_param

## sub commit is called by dbh, so it is in DB::Object::Postgres

## Customised for Postgres
sub distinct
{
    my $self = shift( @_ );
    my $what = shift( @_ );
    my $query = $self->{query} ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    ## ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( SELECT );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be distinct:\n$query" ) );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DISTINCT|ALL)[[:blank:]]+/i );
    my $clause = defined( $what ) ? "DISTINCT ON ($what)" : "DISTINCT";
    
    $query =~ s/^([[:blank:]]*)($allowed)([[blank:]]+)/$1$2 $clause /;
    ## my $sth = $self->prepare( $query ) ||
    ## $self->{ 'query' } = $query;
    ## saving parameters to bind later on must have been done previously
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

## Inherited from DB::Object
## sub dump

## Inherited from DB::Object::Statement
## sub execute

## Inherited from DB::Object::Statement
## sub executed

## Inherited from DB::Object::Statement
## sub fetchall_arrayref($@)

## Inherited from DB::Object::Statement
## sub fetchcol($;$)

## Inherited from DB::Object::Statement
## sub fetchhash(@)

## Inherited from DB::Object::Statement
## sub fetchrow(@)

## Inherited from DB::Object::Statement
## sub finish

## https://sqlite.org/lang_insert.html
## https://sqlite.org/lang_update.html
sub ignore
{
    my $self = shift( @_ );
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ] );
    ## ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( INSERT UPDATE );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be ignored:\n$query" ) );
    }
    ## Already done. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+OR[[:blank:]]+IGNORE[[:blank:]]+/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 OR IGNORE$3/;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

## Inherited from DB::Object::Statement
## sub join

## Inherited from DB::Object::Statement
## sub object

sub only
{
    return( shift->error( "SELECT | DELETE | UPDATE ONLY is not supported by SQLite." ) );
}

sub priority
{
    return( shift->error( "Priority is not supported in SQLite." ) );
}

## rollback is called using the dbh handler and is located in DB::Object::Postgres

## Inherited from DB::Object::Statement
## sub rows(@)

## Inherited from DB::Object::Statement
## sub undo

sub unprepared_statements
{
    my $self = shift( @_ );
    if( $self->{dbh}->{sth} )
    {
        return( $self->{dbh}->{sth}->{sqlite_unprepared_statements} );
    }
    return;
}

## Does nothing in SQLite. This is a Mysql feature
sub wait
{
    return( shift( @_ ) );
}

DESTROY
{
    ## Do nothing but existing so it is handled by this package
    ## print( STDERR "DESTROY'ing statement $self ($self->{ 'query' })\n" );
};

1;

__END__

