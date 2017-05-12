
use strict;
use warnings;

use Test::More tests => 9;                      # last test to print

use lib 't/lib';

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');

$mech->get_ok( '/resolve_as_component' );
$mech->content_like( qr#\Q/foo/v1.2.3/something\E$# );

$mech->get_ok( '/resolve_merged' );
$mech->content_like( qr#\Q/bar/v1.2.3/something\E$# );

$mech->get_ok( '/normal' );
$mech->content_like( qr#\Q/baz/something\E$# );

# Controller

$mech->get_ok( '/foo/v1.2.3/something' );
$mech->get_ok( '/bar/v1.2.3/something' );
$mech->get_ok( '/baz/something' );
