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
use Data::Nested::Multifile;

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

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.data.1.yaml",
           "FILE2","$tdir/MF.DATA.data.2.yaml");
$obj->default_element("def11","/usedef1","1");
$obj->default_element("def21","/usedef2","1");
$obj->default_element("def31","/usedef3","1");
$obj->default_element("def12","/usedef1","1");
$obj->default_element("def22","/usedef2","1");
$obj->default_element("def32","/usedef3","1");

$tests = "

a /dh1/a ~ _undef_ nmeacc04

b /dh1/a ~ valBa _blank_

c /dh1/a ~ _undef_ nmeacc04

d /dh1/a ~ valDa _blank_

e /dh1/a ~ def1a _blank_

f /dh1/a ~ valFa _blank_

g /dh1/a ~ def1a _blank_

h /dh1/a ~ valHa _blank_

";


print "value...\n";
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

