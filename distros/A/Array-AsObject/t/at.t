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
use Array::AsObject;

sub test {
  (@test) = @_;
  @ret    = ();
  $val    = $obj->at(@test);
  $err    = $obj->err();
  push(@ret,$err,$val);
  @val    = $obj->at(@test);
  $err    = $obj->err();
  push(@ret,$err,@val);
  return @ret;
}

$obj = new Array::AsObject;
$obj->list(qw(a b c));

$tests = "

a ~ 1 _undef_ 1 _undef_

4 ~ 1 _undef_ 1 _undef_

-4 ~ 1 _undef_ 1 _undef_

1 ~ 0 b 0 b

-2 ~ 0 b 0 b

1 2 ~ 1 _undef_ 0 b c

-1 -2 ~ 1 _undef_ 0 c b

";

print "at...\n";
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

