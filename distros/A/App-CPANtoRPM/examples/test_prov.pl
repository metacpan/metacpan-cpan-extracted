#!/usr/bin/perl

#use re 'debug';

$file = "test_prov.pm";
$out  = "test_prov.out";
$exp  = "test_prov.exp";

#####

@sep = ("  ",
        "\n",
        " # comment\n",
        " # comment1\n # comment2\n",
        " # comment1\n # comment2\n ",
       );
@end = (" ",
        "# end comment",
        "{",
        ";");
@mod = ("Foo",
        "Foo::Bar",
        "Foo::Bar::Baz");
@ver = ("1.1",
        "1.1_01",
        "v1.2.3",
        "v1.2.3.4");

open(OUT,">$file");

$i = 0;
foreach $sep1 (@sep) {
  foreach $mod (@mod) {
    foreach $sep2 (@sep) {
      foreach $ver (@ver) {
        foreach $end (@end) {
          $i++;
          $str = "package$sep1$mod$i$sep2$ver$end";
          print OUT "$str\n";
        }
      }
    }
  }
}

close(OUT);

system("../cpantorpm-depreq --provides $file > $out; diff $exp $out; rm $out $file");

