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
  %ret = $obj->path_values(@test);
  @ret = ();
  foreach $key (sort { $a <=> $b } keys %ret) {
    push(@ret,$key,$ret{$key});
  }
  return @ret;
}

$obj = new Data::Nested::Multiele;
$obj->file("$tdir/ME.DATA.which.list.yaml");

$tests = "

/h1/h1k1
~
   3
   dh1v1

/h1/h1k1
1
~
   2
   _undef_
   3
   dh1v1

";


print "path_values (list)...\n";
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

