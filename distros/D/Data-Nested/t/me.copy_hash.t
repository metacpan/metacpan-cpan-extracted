#!/usr/bin/perl -w

require 5.001;

$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
  $dir="./lib";
  $tdir="t";
} elsif ( -f "test.pl" ) {
  require "test.pl";
  $dir="../lib";
  $tdir=".";
} else {
  die "ERROR: cannot find test.pl\n";
}

unshift(@INC,$dir);
use Data::Nested::Multiele;

sub test {
  (@test)=@_;
  $val = $obj->value(@test);
  $err = $obj->err();

  if (ref($val) eq "HASH") {
    @val = map { $_,$$val{$_} } sort(keys %$val);
  } elsif (ref($val) eq "ARRAY") {
    @val = @$val;
  } else {
    @val = ($val);
  }
  return (@val,$err);
}

$obj = new Data::Nested::Multiele;
$obj->file("$tdir/ME.DATA.file.hash.yaml");
$obj->copy_ele("a","acopy");
$obj->copy_ele("b","bcopy");
$obj->copy_ele("c","ccopy");

$tests = "

acopy /x ~ 1 _blank_

acopy /y ~ 2 _blank_

";


print "copy_ele (hash)...\n";
test_Func(\&test,$tests,$runtests);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

