# -*- perl -*-
##----------------------------------------------------------------------------
## DB/Object/Mysql/Statement.pm
## Version 0.3
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/06/17
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to automatically terminate the statement object and
## separate them from the connection object (DB::Object).
## Connection object last longer than statement objects
##----------------------------------------------------------------------------
package DB::Object::Mysql::Statement;
BEGIN
{
    require 5.6.0;
    use strict;
    use DB::Object::Mysql;
    use DB::Object::Statement;
    use IO::File;
    use DateTime;
    use File::Spec;
    use parent qw( DB::Object::Statement DB::Object::Mysql );
    our( $VERSION, $VERBOSE, $DEBUG );
    $VERSION    = '0.3';
    $VERBOSE    = 0;
    $DEBUG      = 0;
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
    my $query = $self->{ 'query' } ||
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
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DISTINCT|DISTINCTROW|ALL)[[:blank:]]+/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 DISTINCT /;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

## Customised for MySQL
sub dump
{
    my $self  = shift( @_ );
    my $args  = @_ == 1 ? shift( @_ ) : { @_ };
    my $vsep  = ",";
    my $hsep  = "\n";
    my $width = 35;
    my $fh    = IO::File->new;
    $fh->fdopen( fileno( STDOUT ), "w" );
    $vsep  = $args->{vsep} if( exists( $args->{vsep} ) );
    $hsep  = $args->{hsep} if( exists( $args->{hsep} ) );
    $width = $args->{width} if( exists( $args->{width} ) );
    my @fields = @{$self->{sth}->FETCH( 'NAME' )};
    return( $self->error( "No query to dump." ) ) if( !exists( $self->{sth} ) );
    if( exists( $args->{file} ) )
    {
        my $file = $args->{file};
        $file = File::Spec->catfile( File::Spec->tmpdir(), $file ) if( !File::Spec->file_name_is_absolute( $file ) );
        $fh = File::IO->new( ">$file" ) || return( $self->error( "Unable to open file $file in write mode: $!" ) );
        $fh->binmode( ':utf8' );
        my @header = sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields );
        my $date = DateTime->now;
        my $table = $self->{table};
        $fh->printf( "## Generated on %s for table $table\n", $date->strftime( '%c' ) );
        $fh->print( "## ", CORE::join( "\t", @header ), "\n" );
        my @data = ();
        while( @data = $self->fetchrow() )
        {
            $fh->print( CORE::join( "\t", @data ), "\n" );
        }
        $fh->close();
        $self->finish();
        return( $self );
    }
    elsif( exists( $args->{ 'fh' } ) )
    {
        if( !fileno( $args->{ 'fh' } ) )
        {
            return( $self->error( "The file descriptor provided does not seem to be valid (not open)" ) );
        }
        $fh = IO::File->new_from_fd( $args->{ 'fh' }, 'w' ) || return( $self->error( $! ) );
    }
    my $max    = 0;
    ## foreach my $field ( keys( %$fields ) )
    foreach my $field ( @fields )
    {
        $max = length( $field ) if( length( $field ) > $max );
    }
    my $template = '';
    ## foreach my $field ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
    foreach my $field ( @fields )
    {
        $template .= "$field" . ( '.' x ( $max - length( $field ) ) ) . ": %s\n";
    }
    $template .= "\n";
    my @data = ();
    while( @data = $self->fetchrow() )
    {
        $fh->printf( $template, @data );
    }
    $self->finish();
    return( $self );
}

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

sub ignore
{
    my $self = shift( @_ );
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ] );
    ## ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( INSERT UPDATE ALTER );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be ignored:\n$query" ) );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)[[:blank:]]+/i );
    return( $self ) if( $type eq 'ALTER' && $query !~ /^[[:blank:]]*$type[[:blank:]]+TABLE[[:blank:]]+/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 IGNORE /;
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
    return( shift->error( "SELECT | DELETE | UPDATE ONLY is not supported by Mysql." ) );
}

sub priority
{
    my $self = shift( @_ );
    my $prio = shift( @_ );
    my $map  =
    {
    0    => 'LOW_PRIORITY',
    1    => 'HIGH_PRIORITY',
    };
    ## Bad argument. Do not bother
    return( $self ) if( !exists( $map->{ $prio } ) );
    
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set priority for was provided." ) );
    my $type = uc( ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ] );
    my @allowed = qw( DELETE INSERT REPLACE SELECT UPDATE );
    my $allowed = CORE::join( '|', @allowed );
    ## Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not set priority on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    ## SELECT with something else than HIGH_PRIORITY is incompatible, so do not bother to go further
    return( $self ) if( $prio != 1 && $type =~ /^(?:SELECT)$/i );
    return( $self ) if( $prio != 0 && $type =~ /^(?:DELETE|INSERT|REPLACE|UPDATE)$/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 $map->{ $prio } /i;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new low priority query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new low priority query:\n$query" ) );
    }
    return( $sth );
}

## rollback is called using the dbh handler and is located in DB::Object::Postgres

## Inherited from DB::Object::Statement
## sub rows(@)

## Inherited from DB::Object::Statement
## sub undo

sub wait
{
    my $self = shift( @_ );
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set as to be delayed." ) );
    my $type = ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ];
    my @allowed = qw( INSERT REPLACE );
    my $allowed = CORE::join( '|', @allowed );
    ## Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not use wait (delayed query) on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)[[:blank:]]+/i );
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 DELAYED /i;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new delayed query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new delayed query:\n$query" ) );
    }
    return( $sth );
}

DESTROY
{
    ## Do nothing but existing so it is handled by this package
    ## print( STDERR "DESTROY'ing statement $self ($self->{ 'query' })\n" );
};

1;

__END__

