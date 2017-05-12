
use strict;
use warnings;
use Test::More tests => 7;

use Data::CompactDump qw/compact/;

my $dump = compact( 'asdf' );
ok($dump, 'dump result is defined');
my $r = eval $dump;
ok(!$@,'no errors in eval');
is($r, 'asdf');

my $xd_structure = [ [ 1, 2 ], [ 3, [ 4, 5 ] ] ];
$dump = compact( $xd_structure );
ok($dump, 'dump result is defined');
$r = eval $dump;
ok(!$@,'no errors in eval');
is($r->[0][0],1) or diag $dump;
is($r->[1][0],3) or diag $dump;
