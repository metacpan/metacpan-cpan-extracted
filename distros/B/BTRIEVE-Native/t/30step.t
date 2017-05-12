#!perl -I./t

use strict;
use warnings;
use Test::More tests => 6;
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
$k = "\0" x 255;

for ( 1 .. @$My_Test::Data )
{
  is $B->( 24, $p, $d, $l, $k, 0 ), 0,'step';
  print '# ', join(':', unpack( $My_Test::Mask, $d ) ), "\n";
}
is $B->( 24, $p, $d, $l, $k, 0 ), 9,'eof';
