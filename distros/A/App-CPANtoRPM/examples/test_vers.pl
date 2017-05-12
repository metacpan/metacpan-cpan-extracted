#!/usr/bin/perl

#use re 'debug';

$file = "test_vers.pm";
$out  = "test_vers.out";
$exp  = "test_vers.exp";

#####

@ver = ("X.1",
        "X.1_01",
        "vX.2.3");

open(OUT,">$file");

$i = 0;
$mod = "Foo";

foreach $ver (@ver) {

  $i++;
  $v = $ver;
  $v =~ s/X/$i/g;
  print OUT "package $mod$i $v;\n";

  foreach $pack (0,1) {
    foreach $q ('','sq','dq','q','qq') {

      $i++;
      $v = $ver;
      $v =~ s/X/$i/g;
      if ($q eq 'sq') {
        $v = "'$v'";
      } elsif ($q eq 'dq') {
        $v = "\"$v\"";
      } elsif ($q eq 'q') {
        $v = "q($v)";
      } elsif ($q eq 'qq') {
        $v = "qq($v)";
      }
      print OUT "package $mod$i;\n";
      print OUT "\$";
      print OUT "$mod${i}::"  if ($pack);
      print OUT "VERSION = $v;\n";
    }
  }
}

close(OUT);

system("../cpantorpm-depreq --provides $file > $out; diff $exp $out; rm $out $file");

