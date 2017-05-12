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
$obj->file("$tdir/ME.DATA.file.list.yaml");
$obj->copy_ele(0);
$obj->copy_ele(2);
$obj->copy_ele(1,4);

$tests = "

0 /x ~ 1 _blank_

0 /y ~ 2 _blank_

1 /x ~ 3 _blank_

1 /y ~ 4 _blank_

3 /x ~ 1 _blank_

3 /y ~ 2 _blank_

4 /x ~ 3 _blank_

4 /y ~ 4 _blank_

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

