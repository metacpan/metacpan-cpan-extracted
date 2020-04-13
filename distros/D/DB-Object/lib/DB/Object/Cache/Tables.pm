# -*- perl -*-
##----------------------------------------------------------------------------
## DB/Object/Cache/Tables.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/08/25
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Cache::Tables;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
	use JSON;
	use File::Spec;
	use Fcntl qw( :flock );
	use Devel::Confess;
	our $VERSION = '0.1';
};

sub init
{
	my $self = shift( @_ );
	$self->{ 'cache' } = {};
	$self->{ 'cache_dir' } = File::Spec->tmpdir();
	$self->{ 'cache_file' } = "$self->{cache_dir}/sql_tables.json";
	$self->{ 'timeout' } = 86400;
	$self->SUPER::init( @_ );
	$self->{ 'updated' } = '';
	$self->cache_dir( $self->{cache_dir} ) if( $self->{cache_dir} );
	$self->cache_file( $self->{cache_file} ) if( $self->{cache_file} );
	return( $self );
}

sub cache { return( shift->_set_get_hash( 'cache', @_ ) ); }

sub cache_dir
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $v = shift( @_ );
		$self->{cache_dir} = $v;
		$self->cache_file( "$v/sql_tables.json" );
	}
	return( $self->{cache_dir} );
}

sub cache_file
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $f = shift( @_ ) || return( $self->error( "No tables cache file path was provided." ) );
		## No change
		return( $f ) if( $f eq $self->{cache_file} );
		if( -e( $f ) )
		{
			my $mtime = ( stat( $f ) )[9];
			$self->updated( $mtime );
			my $hash = $self->read( $f ) || return( undef() );
			$self->cache( $hash );
		}
		$self->{cache_file} = $f;
	}
	return( $self->{cache_file} );
}

sub get
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ && $self->_is_hash( $_[0] ) );
	foreach my $k ( qw( host port driver ) )
	{
		return( $self->error( "Parameter \"$k\" is missing." ) ) if( !length( $opts->{ $k } ) );
	}
	my $cache = $self->cache;
	my $timeout = $self->timeout;
	my $part  = {};
	return( [] ) if( !exists( $cache->{ $opts->{host} }->{ $opts->{driver} }->{ $opts->{port} }->{ $opts->{database} }->{tables} ) );
	my $part = $cache->{ $opts->{host} }->{ $opts->{driver} }->{ $opts->{port} }->{ $opts->{database} };
	my $ts = $part->{timestamp};
	return( $part->{tables} ) if( $opts->{ignore_ttl} || ( $ts && ( time() - $ts < $timeout ) ) );
	return( [] );
}

sub read
{
	my $self = shift( @_ );
	my $tables_cache_file = shift( @_ ) || $self->cache_file || return( {} );
	my $hash = {};
	my $j = JSON->new->relaxed;
	if( -e( $tables_cache_file ) &&
		!-z( $tables_cache_file ) )
	{
		if( my $fh = IO::File->new( "<$tables_cache_file" ) )
		{
			$fh->binmode( ':utf8' );
			$fh->autoflush( 1 );
			my $data = join( '', $fh->getlines );
			$fh->close;
			eval
			{
				$cache = $j->decode( $data );
			};
			if( $@ )
			{
				warn( "An error occured while decoding json data from the table cache file: $@\n" );
			}
		}
		else
		{
			warn( "Warning only: cannot read the tables cache file \"$tables_cache_file\".\n" );
		}
	}
	return( $hash );
}

sub set
{
	my $self = shift( @_ );
	my $hash = shift( @_ ) || return( $self->error( "No hash reference was provided to add to tables cache." ) );
	return( $self->error( "Hash reference provided for tables cache ($hash) is not a hash reference." ) ) if( !$self->_is_hash( $hash ) );
	foreach my $k ( qw( host port driver tables ) )
	{
		return( $self->error( "Tables cache provided is missing the \"$k\" key." ) ) if( !length( $hash->{ $k } ) );
	}
	return( $self->error( "\"tables\" property in cache data is not an array reference." ) ) if( !$self->_is_array( $hash->{tables} ) );
	## Possibly reload the cache if the modification date changed
	my $cache = $self->cache;
	my $f = $self->cache_file;
	my $last_update = $self->updated;
	if( -s( $f ) && $last_update && ( stat( $f ) )[9] != $last_update )
	{
		$cache = $self->read( $f ) || return( undef() );
	}
	$cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} } = {} if( ref( $cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} } ) ne 'HASH' );
	$cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} }->{tables} = $hash->{tables};
	$cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} }->{timestamp} = time();
	if( !defined( $self->write( $cache ) ) )
	{
		return( undef() );
	}
	return( $self );
}

sub timeout { return( shift->_set_get_number( 'timeout', @_ ) ); }

sub updated { return( shift->_set_get_number( 'updated', @_ ) ); }

sub write
{
	my $self = shift( @_ );
	my $hash = shift( @_ ) || return( $self->error( "No table cache data was provided to write to cache file \"$tables_cache_file\"." ) );
	my $tables_cache_file = shift( @_ ) || $self->cache_file || return( $self->error( "No cache file was set to write data to it." ) );
	return( $self->error( "Tables cache data provided is not an hash reference." ) ) if( ref( $hash ) ne 'HASH' );
	my $j = JSON->new->allow_nonref;
	if( my $fh = IO::File->new( ">$tables_cache_file" ) )
	{
		$fh->binmode( ':utf8' );
		$fh->autoflush( 1 );
		eval
		{
			flock( $fh, LOCK_EX );
		};
		$fh->print( $j->encode( $hash ) ) || return( $self->error( "Unable to write data to tables cache file \"$tables_cache_file\": $!" ) );
		eval
		{
			flock( $fh, LOCK_UN );
		};
		$fh->close;
		$self->updated( ( stat( $tables_cache_file ) )[9] );
		return( -s( $tables_cache_file ) );
	}
	else
	{
		return( $self->error( "Unable to write to file $tables_cache_file: $!" ) );
	}
}

1;

__END__
