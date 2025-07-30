# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Cache/Tables.pm
## Version v0.100.5
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2024/09/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Cache::Tables;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use JSON;
    use Fcntl qw( :flock );
    use Module::Generic::File qw( sys_tmpdir );
    our $VERSION = 'v0.100.5';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{cache} = {};
    $self->{cache_dir} = sys_tmpdir();
    $self->{cache_file} = "$self->{cache_dir}/sql_tables.json";
    $self->{timeout} = 86400;
    $self->SUPER::init( @_ );
    $self->{updated} = '';
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
        # No change
        return( $f ) if( $f eq $self->{cache_file} );
        if( -e( $f ) )
        {
            my $mtime = ( stat( $f ) )[9];
            $self->updated( $mtime );
            my $hash = $self->read( $f ) || return;
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
    $opts = shift( @_ ) if( @_ && $self->_is_hash( $_[0] => 'strict' ) );
    foreach my $k ( qw( host port driver ) )
    {
        return( $self->error( "Parameter \"$k\" is missing." ) ) if( !length( $opts->{ $k } ) );
    }
    my $cache = $self->cache;
    my $timeout = $self->timeout;
    my $part  = {};
    return( [] ) if( !exists( $cache->{ $opts->{host} }->{ $opts->{driver} }->{ $opts->{port} }->{ $opts->{database} }->{tables} ) );
    $part = $cache->{ $opts->{host} }->{ $opts->{driver} }->{ $opts->{port} }->{ $opts->{database} };
    my $ts = $part->{timestamp};
    return( $part->{tables} ) if( $opts->{ignore_ttl} || ( $ts && ( time() - $ts < $timeout ) ) );
    return( [] );
}

sub read
{
    my $self = shift( @_ );
    my $tables_cache_file = shift( @_ ) || $self->cache_file || return( {} );
    $tables_cache_file = $self->new_file( $tables_cache_file );
    my $hash = {};
    my $j = JSON->new->relaxed;
    if( $tables_cache_file->exists && !$tables_cache_file->is_empty )
    {
        if( my $fh = $tables_cache_file->open_utf8 )
        {
            $fh->autoflush(1);
            # my $data = join( '', $fh->getlines );
            # $fh->close;
            my $data = $tables_cache_file->load;
            eval
            {
                $hash = $j->decode( $data );
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
    return( $self->error( "Hash reference provided for tables cache ($hash) is not a hash reference." ) ) if( !$self->_is_hash( $hash => 'strict' ) );
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
        $cache = $self->read( $f ) || return;
    }
    $cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} } = {} if( ref( $cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} } ) ne 'HASH' );
    $cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} }->{tables} = $hash->{tables};
    $cache->{ $hash->{host} }->{ $hash->{driver} }->{ $hash->{port} }->{ $hash->{database} }->{timestamp} = time();
    if( !defined( $self->write( $cache ) ) )
    {
        return;
    }
    return( $self );
}

sub timeout { return( shift->_set_get_number( 'timeout', @_ ) ); }

sub updated { return( shift->_set_get_number( 'updated', @_ ) ); }

sub write
{
    my $self = shift( @_ );
    my $hash = shift( @_ ) || return( $self->error( "No table cache data was provided to write to cache file \"", $self->cache_file, "\"." ) );
    my $tables_cache_file = shift( @_ ) || $self->cache_file || return( $self->error( "No cache file was set to write data to it." ) );
    $tables_cache_file = $self->new_file( $tables_cache_file );
    return( $self->error( "Tables cache data provided is not an hash reference." ) ) if( ref( $hash ) ne 'HASH' );
    my $j = JSON->new->allow_nonref;
    if( my $fh = $tables_cache_file->open_utf8( '>' ) )
    {
        $fh->autoflush(1);
        eval
        {
            $tables_cache_file->lock( LOCK_EX );
        };
        $fh->print( $j->encode( $hash ) ) || return( $self->error( "Unable to write data to tables cache file \"$tables_cache_file\": ", $tables_cache_file->error ) );
        eval
        {
            $tables_cache_file->unlock;
        };
        $self->updated( $tables_cache_file->finfo->mtime );
        return( -s( $tables_cache_file ) );
    }
    elsif( $tables_cache_file->exists && !$tables_cache_file->can_write )
    {
        return( $self->error( "Table cache file \"$tables_cache_file\" does not have write permission: ", $tables_cache_file->error ) );
    }
    else
    {
        return( $self->error( "Although table cache file \"$tables_cache_file\" is writable, I am unable to write to it: ", $tables_cache_file->error ) );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Cache::Tables - Table Cache

=head1 SYNOPSIS

    my $cache = DB::Object::Cache::Tables->new({
        timeout => 86400,
        # This is automatically set
        # cache_file => '/some/dir/sql_tables.json',
    });
    $dbh->cache_tables( $cache_tables );
    $tables = $dbh->tables_info;
    my $cache = 
    {
    host => $host,
    driver => $driver,
    port => $port,
    database => $database,
    tables => $tables,
    };
    if( !defined( $cache->set( $cache ) ) )
    {
        warn( "Unable to write to tables cache: ", $cache->error, "\n" );
    }
    
    # Returning an array reference of tables hash reference definition
    $all = $cache_tables->get({
        host => $self->host,
        driver => $self->driver,
        port => $self->port,
        database => $db,
    }) || do
    
=head1 VERSION

    v0.100.5

=head1 DESCRIPTION

This is a simple way to maintain a cache of database tables in a session. When a connection object is created, it will issue a query to get the list of all tables and views in the database and pass it to L<DB::Object::Cache::Tables>, and save its object. It is then used later several times such as when instantiating table objects.

=head1 METHODS

=head2 init

Possible parameters:

=over 4

=item I<cache_dir>

An absolute path to a directory that will contain the json cache file. Beware that if you run your script from the web, this directory must be writable by the http server user.

=item I<cache_file>

Alternatively to I<cache_dir>, you can provide an absolute path to the json cache file.

=item I<timeout>

An amount of time in second until the cache file becomes obsolete.

=back

=head2 cache

Returns the hash reference structure of the cache

=head2 cache_dir

Set or get the cache dir.

When set, this will also set the cache file calling L</"cache_file">

=head2 cache_file

Set or get the cache file.

When set, this will store the cache file modification time to check later if it has become obsolete and load its json data into the L</"cache">

=head2 get

Given an hash reference of parameters, this will return an array reference of table hash reference.

Parameters are:

=over 4

=item I<host>

=item I<driver>

=item I<port>

=item I<database>

=back

=head2 read

Given a full path to a json cache file, this will read the file and return its data as a hash reference.

If an error occurs while reading the json cache file, it will issue a warning using B<warn> and return an empty hash reference.

=head2 set

Provided with an hash reference of parameters, this will add it to the cache data and write it to the file.

Parameters are:

=over 4

=item I<host>

=item I<driver>

=item I<port>

=item I<database>

=item I<tables>

An array reference of hash reference containing table definition as returned by L<DB::Object::table_info>

=back

=head2 timeout

Set/get the cache file timeout.

If the current unix timestamp minus the cache file timestamp is higher than the timeout, the cache file has expired.

=head2 updated

Set/get the cache file last modified unix timestamp

=head2 write

Provided with a cache data, which is a hash reference and optionally the full path to the cache file, and B<write> will write the hash data as a json to the cache file.

If no cache file is provided as a second argument, it will use the default one set up when the object was instantiated.

It returns the size of the cache file or return undef and set the B<error>

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 SEE ALSO

L<DB::Object>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
