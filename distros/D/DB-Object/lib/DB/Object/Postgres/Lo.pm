# -*- perl -*-
##----------------------------------------------------------------------------
## DB/Object/Postgres/Lo.pm
## Version 0.3
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/09/11
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## Package for PostgreSQL large objects
package DB::Object::Postgres::Lo;
BEGIN
{
    require 5.6.0;
    use strict;
    use parent qw( DB::Object::Postgres );
    our( $VERSION );
    $VERSION     = '0.3';
    use Devel::Confess;
};

sub new
{
	my $this  = shift( @_ );
	my $dbh   = shift( @_ );
	my $class = ref( $this ) ? ref( $this ) : $this;
	my $self  = {};
	$self->{ 'dbh' } = $dbh;
	bless( $self, $class );
	return( $self );
}

sub close
{
	my $self = shift( @_ );
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $rv = $self->{ 'dbh' }->pg_lo_close( $fh );
	return( $self->error( "Unable to close the large object file descriptor." ) ) if( !defined( $rv ) );
	return( $self );
}

sub create
{
	my $self = shift( @_ );
	my $mode  = shift( @_ ) || 077;
	my $id = $self->{ 'dbh' }->pg_lo_creat( $mode );
	$self->{ 'id' } = $id;
	return( $id );
}

sub export
{
	my $self = shift( @_ );
	my $file = shift( @_ );
	my $rv = $self->{ 'dbh' }->pg_lo_export( $file );
	return( $self->error( "Unable to export the large object to file $file." ) ) if( !defined( $rv ) );
	return( $self );
}

sub id
{
	my $self = shift( @_ );
	$self->{ 'id' } = shift( @_ ) if( @_ );
	return( $self->{ 'id' } );
}

sub import
{
	my $self = shift( @_ );
	my $file = shift( @_ );
	my $fh = $self->{ 'fh' };
	my $id = $self->{ 'dbh' }->pg_lo_import( $file );
	return( $self->error( "Unable to import the large object." ) ) if( !defined( $id ) );
	my $new = $self->new( $self->{ 'dbh' } );
	$new->id( $id );
	return( $new );
}

sub import_with_oid
{
	my $self = shift( @_ );
	my $file = shift( @_ );
	my $oid  = shift( @_ );
	my $fh = $self->{ 'fh' };
	my $id = $self->{ 'dbh' }->pg_lo_import_with_oid( $file, $oid );
	return( $self->error( "Unable to import the large object with the oid $oid." ) ) if( !defined( $id ) );
	my $new = $self->new( $self->{ 'dbh' } );
	$new->id( $id );
	return( $new );
}

sub open
{
	my $self = shift( @_ );
	my $id   = shift( @_ );
	## $dbh->{pg_INV_READ}, $dbh->{pg_INV_WRITE},  $dbh->{pg_INV_READ} | $dbh->{pg_INV_WRITE}
	my $mode = shift( @_ );
	my $fh = $self->{ 'dbh' }->pg_lo_open( $id, $mode );
	return( $self->error( "Cannot open large object. An error has occured." ) ) if( !defined( $fh ) );
	$self->{ 'fh' } = $fh;
	return( $self );
}

sub read
{
	my $self = shift( @_ );
	my( $buffer, $len ) = @_;
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $bytes = $self->{ 'dbh' }->pg_lo_read( $fh, $buffer, $len );
	return( $self->error( "Unable to read from the large object file descriptor." ) ) if( !defined( $bytes ) );
	return( $bytes );
}

sub seek
{
	my $self = shift( @_ );
	my( $offset, $whence ) = @_;
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $loc = $self->{ 'dbh' }->pg_lo_lseek( $fh, $offset, $whence );
	return( $self->error( "Unable to seek a position from the large object file descriptor." ) ) if( !defined( $loc ) );
	return( $loc );
}

sub tell
{
	my $self = shift( @_ );
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $loc = $self->{ 'dbh' }->pg_lo_tell( $fh );
	return( $self->error( "Unable to get the current position from the large object file descriptor." ) ) if( !defined( $loc ) );
	return( $loc );
}

sub truncate
{
	my $self = shift( @_ );
	my $len  = shift( @_ );
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $rv = $self->{ 'dbh' }->pg_lo_truncate( $fh );
	return( $self->error( "Unable to truncate the large object file descriptor." ) ) if( !defined( $rv ) );
	return( $self );
}

sub unlink
{
	my $self = shift( @_ );
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $rv = $self->{ 'dbh' }->pg_lo_unlink( $fh );
	return( $self->error( "Unable to delete the large object file descriptor." ) ) if( !defined( $rv ) );
	return( $self );
}

sub write
{
	my $self = shift( @_ );
	my( $buffer, $len ) = @_;
	return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{ 'dbh' }->{ 'AutoCommit' } );
	my $fh = $self->{ 'fh' };
	my $bytes = $self->{ 'dbh' }->pg_lo_write( $fh, $buffer, $len );
	return( $self->error( "Unable to write to the large object file descriptor." ) ) if( !defined( $bytes ) );
	return( $bytes );
}

1;

__END__
