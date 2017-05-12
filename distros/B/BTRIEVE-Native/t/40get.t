#!perl -I./t

use strict;
use warnings;
use Test::More tests => 7;
use My_Test();
BEGIN { use_ok 'BTRIEVE::Native' }

my $B = \&BTRIEVE::Native::Call;

my $p = "\0" x 128;
my $d = "\0";
my $l = 0;
my $k = $My_Test::File;

is $B->( 0, $p, $d, $l, $k, 0 ), 0,'open';

$d = "\0" x $My_Test::Length;
$l = $My_Test::Length;

$k = $My_Test::NotExistingKey;
is $B->( 5, $p, $d, $l, $k, 0 ), 4,'not found';

$k = $My_Test::FirstKey;
is $B->( 5, $p, $d, $l, $k, 0 ), 0, 'found';
print '# ', join(':', unpack( $My_Test::Mask, $d ) ), "\n";

for ( 2 .. @$My_Test::Data )
{
  is $B->( 6, $p, $d, $l, $k, 0 ), 0,'get';
  print '# ', join(':', unpack( $My_Test::Mask, $d ) ), "\n";
}
is $B->( 6, $p, $d, $l, $k, 0 ), 9,'eof';
