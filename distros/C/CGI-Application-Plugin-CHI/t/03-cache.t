#!perl -T

use strict;
use warnings;

use Test::More tests => 15;

use_ok( 'CGI::Application::Plugin::CHI' );

my %conf = ( driver    => 'Memory', global => 1 );

main->cache_config( \%conf );

my $testc = CHI->new( %conf );
isa_ok( $testc, 'CHI::Driver::Memory' );

$testc->set( foo => 'bar' );
is( $testc->get( 'foo'), 'bar' );

my $obj = bless { }, 'main';
is( $obj->cache->get( 'foo' ), 'bar' );

clean();
delete $conf{global};

my ( %flarg, %blarg );
my $testc1 = CHI->new( %conf, datastore => \%flarg );
my $testc2 = CHI->new( %conf, datastore => \%blarg );
isa_ok( $testc1, 'CHI::Driver::Memory' );
isa_ok( $testc2, 'CHI::Driver::Memory' );

$testc1->set( foo => 'bar' );
$testc2->set( foo => 'baz' );

is( $testc1->get( 'foo' ), 'bar' );
is( $testc2->get( 'foo' ), 'baz' );

main->cache_config( flarg => { %conf, datastore => \%flarg }, 
                    blarg => { %conf, datastore => \%blarg } );

is( $obj->cache( 'flarg' )->get( 'foo' ), 'bar' );
is( $obj->cache( 'blarg' )->get( 'foo' ), 'baz' );

my %glarg;
my $testc3 = CHI->new( %conf, datastore => \%glarg );
isa_ok( $testc3, 'CHI::Driver::Memory' );

$testc3->set( foo => 'zab' );

is( $testc3->get( 'foo' ), 'zab' );

main->cache_config( glarg => { %conf, datastore => \%glarg } );

is( $obj->cache( 'glarg' )->get( 'foo' ), 'zab' );
is( $obj->cache( 'flarg' )->get( 'foo' ), 'bar' );
is( $obj->cache( 'blarg' )->get( 'foo' ), 'baz' );


sub clean { 
    CGI::Application::Plugin::CHI->_clean_conf;
}

