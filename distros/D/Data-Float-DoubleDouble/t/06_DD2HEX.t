# In these tests we check that float_H() output agrees with C's %La and %LA values.

use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);
use Math::NV qw(:all);

my $t = 11;
print "1..$t\n";

my $ok = 1;
my $fmt = "%La";

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nA \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = '-' . random_select($digits) . 'e' . "$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nB \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 2\n"}
else {print "not ok 2\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "-$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nC \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 3\n"}
else {print "not ok 3\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = '-' . random_select($digits) . 'e' . "-$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nD \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 4\n"}
else {print "not ok 4\n"}

my $specific = nv('193e-3');
my $hex1 = DD2HEX($specific, "%La");
my $hex2 = DD2HEX($specific, "%LA");

if($hex1 eq lc($hex2) && uc($hex1) eq $hex2) {print "ok 5\n"}
else {
  warn "\n\$hex1: $hex1\n\$hex2: $hex2\n";
  print "not ok 5\n";
}

eval{my $h = DD2HEX($specific, "%Le");};

if($@ =~ /^Second arg to DD2HEX is %Le/) {print "ok 6\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 6\n";
}

eval{my $h = std_float_H($specific, "%Le");};

if($@ =~ /^Second arg to std_float_H is %Le/) {print "ok 7\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 7\n";
}

$ok = 1;
$fmt = "%LA";

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nE \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 8\n"}
else {print "not ok 8\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = '-' . random_select($digits) . 'e' . "$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nF \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 9\n"}
else {print "not ok 9\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "-$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nG \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 10\n"}
else {print "not ok 10\n"}

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = '-' . random_select($digits) . 'e' . "-$exp";
    my $nv = nv($str);
    my $hex1 = std_float_H($nv, $fmt);
    my $hex2 = DD2HEX($nv, $fmt);

    if($hex1 ne $hex2) {
      $ok = 0;
      warn "\nH \$hex1: $hex1\n\$hex2: $hex2\n";
    }
  }
}

if($ok) {print "ok 11\n"}
else {print "not ok 11\n"}

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return $ret;
}

__END__
