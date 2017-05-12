#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use_ok( 'CGI::Application::Plugin::CHI' );

main->cache_config( { driver    => 'Memory', global => 1 } );

my $rm = "foo_runmode";
sub get_current_runmode { $rm }

my $obj = bless { }, 'main';

$obj->rmcache->set( foo => 'bar' );
is( $obj->rmcache->get( 'foo' ), 'bar' );

$rm = "other_runmode";
is( $obj->rmcache->get( 'foo' ), undef );

clean();

my ( %flarg, %blarg );
main->cache_config( flarg => { driver  => 'Memory', datastore => \%flarg },
                    blarg => { driver  => 'Memory', datastore => \%blarg } );


$rm = "bar_runmode";
$obj->rmcache( 'flarg' )->set( bar => 'baz' );
$obj->rmcache( 'blarg' )->set( baz => 'quux' );
is( $obj->rmcache( 'flarg' )->get( 'bar' ), 'baz' );
is( $obj->rmcache( 'blarg' )->get( 'baz' ), 'quux' );

$rm = "other_runmode";
is( $obj->rmcache( 'flarg' )->get( 'bar' ), undef );
is( $obj->rmcache( 'blarg' )->get( 'baz' ), undef );

sub clean { 
    CGI::Application::Plugin::CHI->_clean_conf;
}

