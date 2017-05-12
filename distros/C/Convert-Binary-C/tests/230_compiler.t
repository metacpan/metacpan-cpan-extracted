################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;
use vars '%config';

$^W = 1;

BEGIN {
  %cc = map { /^(.*?([\w-]+))\.cfg$/
              ? ( $2 => { cfg => "$1.cfg", bin => "$1.bin", dat => "$1.dat" } )
              : () } glob 'tests/compiler/*.cfg';
  plan tests => 2 * keys %cc;
}

sub slurp
{
  my $file = shift;
  local *F;
  open F, $file or die "$file: $!\n";
  my $data = do { local $/; <F> };
  close F;
  return $data;
}

for my $cur (sort keys %cc) {
  print "# -- $cur --\n";

  my $dat = eval slurp($cc{$cur}{dat});
  my $bin = slurp($cc{$cur}{bin});
  $bin =~ s/\s+//gms;
  $bin = pack "H*", $bin;

  do $cc{$cur}{cfg};

  my $c = new Convert::Binary::C %config;
  $c->parse_file('tests/compiler/test.h');
  my $pck = $c->pack('test', $dat);

  my $pass = 0;
  my $fail = 0;

  for my $i (0 .. $c->sizeof('test')-1) {
    my $a = ord substr $pck, $i, 1;
    my $b = ord substr $bin, $i, 1;
    next if $b == 0;
    $pass++;
    next if $a == $b;
    $fail++;
    print "# [$i]  $a != $b\n";
  }

  print "# pass=$pass fail=$fail\n";

  ok($pass > 0);
  ok($fail == 0);
}
