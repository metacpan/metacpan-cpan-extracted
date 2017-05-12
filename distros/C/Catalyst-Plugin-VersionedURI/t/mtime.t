
use strict;
use warnings;

use Test::More tests => 6;                      # last test to print

use lib 't/lib';

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'MTimeApp');

$mech->get_ok( '/resolve_as_component' );
$mech->content_like( qr#\Q/foo/something?v=\E\d+$# );

# Test the fallback
$mech->get_ok( '/resolve_merged' );
$mech->content_like( qr#\Q/bar/something?v=1.2.3\E$# );

$mech->get_ok( '/normal' );
$mech->content_like( qr#\Q/baz/something\E$# );
