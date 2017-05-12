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

$l = $My_Test::Length;
$k = "\0" x 255;

for my $a ( @$My_Test::Data )
{
  $d = pack $My_Test::Mask, @$a;
  is $B->( 2, $p, $d, $l, $k, -1 ), 0,"insert @$a";
}
$d = pack $My_Test::Mask, @{$My_Test::Data->[0]};
is $B->( 2, $p, $d, $l, $k, -1 ), 5,"insert @{$My_Test::Data->[0]} (dup)";
