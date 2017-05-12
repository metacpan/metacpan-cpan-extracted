#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'CGI::Application::Plugin::CHI' );

main->cache_config( foo => { driver => 'Memory', global => 1 } );

my $obj = bless { }, 'main';

my $testc = $obj->cache( 'foo' );
$testc->set( dog => 'snoopy' );
is( $testc->get( 'dog' ), 'snoopy' );

eval { 
    my $c = $obj->cache;
};

like( $@, qr/no default cache/ );

main->cache_default( 'foo' );

is( $obj->cache->get( 'dog' ), 'snoopy' );
