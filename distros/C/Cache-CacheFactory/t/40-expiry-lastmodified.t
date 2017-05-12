#!perl -T

use strict;
use warnings;

use Test::More;
use Cache::CacheFactory;
eval "use Cache::MemoryCache";
plan skip_all => "Cache::MemoryCache required for testing expiry policies" if $@;
eval "use IO::File";
plan skip_all => "IO::File required for testing expiry policies" if $@;
eval "use File::Temp";
plan skip_all => "File::Temp required for testing expiry policies" if $@;

plan tests => 5;

my ( $cache, $key, $file, $fh, $time );
my %vals = (
    'valid' => 'value for valid key',
    );

SKIP:
{

( $fh, $file ) = File::Temp::tempfile();
skip "Unable to create temporary file for dependency checking." => 5 unless $fh;
$fh->close();

$time = touch( $file );

skip "Unable to touch dependency file." => 5 unless $time;
if( time() == $time )
{
    sleep( 1 ); #  So that the last modified time is definitely in the past.
}
if( time() == $time )
{
    sleep( 1 ); #  So that the last modified time is definitely in the past.
}
skip "Unable to sleep until dependency file mtime is in the past." => 5
  if time() == $time;

ok( $cache = Cache::CacheFactory->new(
    storage  => 'memory',
    validity => 'lastmodified',
    ), "construct cache" );

$key = 'valid';
$cache->set(
    key          => $key,
    data         => $vals{ $key },
    dependencies => $file,
    );

$key = 'valid';
is( $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );

$cache->purge();

$key = 'valid';
is( $cache->get( $key ), $vals{ $key }, "post-purge immediate $key fetch" );

$time = touch( $file );
skip "Unable to touch dependency file." => 2 unless $time;

$key = 'valid';
is( $cache->get( $key ), undef, "post-touch $key fetch" );

$cache->purge();

$key = 'valid';
is( $cache->get( $key ), undef, "post-purge post-touch $key fetch" );
}

unlink( $file ) if $file and -e $file;

sub touch
{
    my ( $filename ) = @_;
    my ( $fh, $time, $mtime );

    $time = time();
    $fh = IO::File->new( "> $filename" );
    unless( $fh )
    {
        diag( "Couldn't open $filename for write." );
        return( 0 );
    }
    $fh->print( "touched at $time\n" );
    $fh->close();

    $mtime = (stat( $filename ))[ 9 ];
    return( $mtime ) if $mtime >= $time;
    diag( "$filename mtime is in the past - last-mod-time: " .
        localtime( $mtime ) . " vs file-open-time: " .
        localtime( $time ) . "." );
    return( 0 );
}
