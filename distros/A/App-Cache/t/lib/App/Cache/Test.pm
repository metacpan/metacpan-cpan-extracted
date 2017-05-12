package App::Cache::Test;
use strict;
use warnings;
use App::Cache;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP::Simple qw(get);
use Path::Class qw();
use Storable qw(nstore retrieve);
use File::Path qw(rmtree);
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(mkpath rmtree);
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw());

sub cleanup {
    my $self  = shift;
    my $cache = App::Cache->new;
    rmtree( $cache->directory->parent->stringify );
    ok( !-d $cache->directory->parent, 'removed cache dir' );
}

sub file {
    my $self  = shift;
    my $cache = App::Cache->new;
    isa_ok( $cache, 'App::Cache' );
    is( $cache->application, 'App::Cache::Test' );
    like( $cache->directory, qr/app_cache_test/ );

    $cache->delete('test');
    my $data = $cache->get('test');
    is( $data, undef );

    $cache->set( 'test', 'one' );
    $data = $cache->get('test');
    is( $data, 'one' );

    $cache->clear;
    $data = $cache->get('test');
    is( $data, undef );

    $cache->set( 'test', { foo => 'bar' } );
    $data = $cache->get('test');
    is_deeply( $data, { foo => 'bar' } );

    $cache->ttl(1);
    sleep 2;
    $data = $cache->get('test');
    is( $data, undef );
}

sub code {
    my $self  = shift;
    my $cache = App::Cache->new( { ttl => 1 } );
    my $data  = $cache->get_code( "code", sub { $self->onetwothree() } );
    is_deeply( $data, [ 1, 2, 3 ] );
    $data = $cache->get_code( "code", sub { $self->onetwothree() } );
    is_deeply( $data, [ 1, 2, 3 ] );
    sleep 2;
    $data = $cache->get_code( "code", sub { $self->onetwothree() } );
    is_deeply( $data, [ 1, 2, 3 ] );
}

sub onetwothree {
    my $self = shift;
    return [ 1, 2, 3 ];
}

sub url {
    my $self = shift;
    my $url  = shift;

    my $test_html = get($url);
SKIP:
    {
        skip "Can't access $url", 3
            unless $test_html && $test_html =~ /Astray.com/;
        my $cache = App::Cache->new( { ttl => 1 } );
        my $orig = $cache->get_url($url);
        like( $orig, qr{Astray.com} );
        my $html = $cache->get_url($url);
        is( $html, $orig );
        sleep 2;
        $html = $cache->get_url($url);
        is( $html, $orig );
    }
}

sub scratch {
    my $self    = shift;
    my $cache   = App::Cache->new( { ttl => 1 } );
    my $scratch = $cache->scratch;
    foreach my $i ( 1 .. 10 ) {
        my $filename = Path::Class::File->new( $scratch, "$i.dat" );
        nstore( { i => $i }, "$filename" )
            || die "Error writing to $filename: $!";
    }
    foreach my $i ( 1 .. 10 ) {
        my $filename = Path::Class::File->new( $scratch, "$i.dat" );
        is( retrieve("$filename")->{i}, $i );
    }
    $cache->clear;
    foreach my $i ( 1 .. 10 ) {
        my $filename = Path::Class::File->new( $scratch, "$i.dat" );
        ok( !-f $filename );
    }
}

sub dir {
    my $self = shift;
    my $tmp_dir = tempdir( CLEANUP => 1 );
    $self->with_dir($tmp_dir);
    rmtree($tmp_dir);
    ok( !-d $tmp_dir, 'tmp_dir removed successfully' );
    $self->with_dir($tmp_dir);
}

sub with_dir {
    my ( $self, $dir ) = @_;
    my $cache = App::Cache->new( { directory => $dir } );
    isa_ok( $cache, 'App::Cache' );
    is( $cache->directory, $dir );
    ok( -d $dir, 'tmp_dir exists ok' );
}

sub disabled {
    my $self = shift;
    my $cache = App::Cache->new( { enabled => 0 } );
    $cache->set( 'a', '1' );
    is( $cache->get('a'), undef, 'disabled does not cache' );
}

1;

