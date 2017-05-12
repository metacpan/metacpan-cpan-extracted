use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);
use Math::NV qw(:all);

my $t = 4;
print "1..$t\n";

my $ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = random_select($digits) . 'e' . "$exp";
    my $nv = nv($str);
    my @arr1 = float_B($nv);
    my @arr2 = NV2binary($nv);

    if(!arr_cmp(\@arr1, \@arr2)) {
      $ok = 0;
      for(my $i = 0; $i < 3; $i++) {
        print "\n$nv\n";
        print "$arr1[0] $arr2[0]\n";
        print "$arr1[1]\n$arr2[1]\n";
        print "$arr1[2] $arr2[2]\n";
      }
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
    my @arr1 = float_B($nv);
    my @arr2 = NV2binary($nv);

    if(!arr_cmp(\@arr1, \@arr2)) {
      $ok = 0;
      for(my $i = 0; $i < 3; $i++) {
        print "\n$nv\n";
        print "$arr1[0] $arr2[0]\n";
        print "$arr1[1]\n$arr2[1]\n";
        print "$arr1[2] $arr2[2]\n";
      }
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
    my @arr1 = float_B($nv);
    my @arr2 = NV2binary($nv);

    if(!arr_cmp(\@arr1, \@arr2)) {
      $ok = 0;
      for(my $i = 0; $i < 3; $i++) {
        print "\n$nv\n";
        print "$arr1[0] $arr2[0]\n";
        print "$arr1[1]\n$arr2[1]\n";
        print "$arr1[2] $arr2[2]\n";
      }
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
    my @arr1 = float_B($nv);
    my @arr2 = NV2binary($nv);

    if(!arr_cmp(\@arr1, \@arr2)) {
      $ok = 0;
      for(my $i = 0; $i < 3; $i++) {
        print "\n$nv\n";
        print "$arr1[0] $arr2[0]\n";
        print "$arr1[1]\n$arr2[1]\n";
        print "$arr1[2] $arr2[2]\n";
      }
    }
  }
}

if($ok) {print "ok 4\n"}
else {print "not ok 4\n"}

sub arr_cmp {
  my @arr1 = @{$_[0]};
  my @arr2 = @{$_[1]};

  $arr1[1] =~ s/0+$//;
  $arr1[1] = '0' if $arr1[1] eq '';

  return 0 if @arr1 != 3;
  return 0 if @arr2 != 3;
  return 0 if $arr1[0] ne $arr2[0];
  return 0 if $arr1[1] ne $arr2[1];
  if($arr1[1] eq 'nan' || $arr1[1] eq 'inf' || $arr1[1] eq '0') {return 1} # exponents may differ
  return 0 if $arr1[2] != $arr2[2];
  return 1;
}


sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return $ret;
}
