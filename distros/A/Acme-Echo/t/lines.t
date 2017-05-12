#!/usr/bin/perl

use IO::Scalar;
my ($out, $SH);
BEGIN {
  $SH = new IO::Scalar \$out;
};
use Acme::Echo qw/lines/, 'line_fmt' => "--> %s <--\n", fh => $SH;
use strict;
use warnings;
use Test::More tests => 2;
my $x = 1;
my $y;
$y = $x ** 2;
my $s = 0;
$s += $_ for 1 .. 10;
$s = 0;
if($s >= 0 ){
  $s = 3;
}else{
  $s = 4;
}
$s += $s < 3 ? 1 : 0;
foreach (1 .. 10){
  $s += $_;
}
$s=0;
while($s < 3){
  $s++;
}
sub cube {
  my $n = shift;
  return $n ** 3
}

no Acme::Echo;
my $expected = do { local $/ = undef; <DATA> };
is( $out, $expected, "output matches" );
is( $s, 3, "s=3" );

__DATA__
--> use strict; <--
--> use warnings; <--
--> use Test::More tests => 2; <--
--> my $x = 1; <--
--> my $y; <--
--> $y = $x ** 2; <--
--> my $s = 0; <--
--> $s += $_ for 1 .. 10; <--
--> $s = 0; <--
COMPOUND STATEMENTS NOT SUPPORTED IN lines MODE
--> $s += $s < 3 ? 1 : 0; <--
COMPOUND STATEMENTS NOT SUPPORTED IN lines MODE
--> $s=0; <--
COMPOUND STATEMENTS NOT SUPPORTED IN lines MODE
SUB STATEMENTS NOT SUPPORTED IN lines MODE
