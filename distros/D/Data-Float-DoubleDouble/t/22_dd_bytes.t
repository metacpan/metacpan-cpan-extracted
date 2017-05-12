use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);

print "1..2\n";

my $ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "$exp";
    my $nv = $str * 1.0;
    my $bytes = dd_bytes($nv);
    my $hex = NV2H($nv);
    if(lc($hex) ne lc($bytes)) {
      $ok = 0;
      warn "\n\$bytes: $bytes\n\$hex: $hex\n\n";
    }
  }
}

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "-$exp";
    my $nv = $str * 1.0;
    my $bytes = dd_bytes($nv);
    my $hex = NV2H($nv);
    if(lc($hex) ne lc($bytes)) {
      $ok = 0;
      warn "\n\$bytes: $bytes\n\$hex: $hex\n\n";
    }
  }
}

if($ok) {print "ok 2\n"}
else {print "not ok 2\n"}

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return $ret;
}


