#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug/; # Test2::V0 etc.

#
# Verify that internal function _show_as_number() distinguishes numerics
# from strings which look like numbers, e.g. "0", and various corner cases.
#

use Data::Dumper::Interp;
use Scalar::Util qw(blessed);

use Math::BigInt;
use Math::BigFloat;
use Math::BigRat;
require Data::Dumper;

my $inf = 9**9**9;
my $nan = -sin($inf);
my $minf = -$inf;

sub show_empty_string($) {
  $_[0] eq "" ? "<empty string>" : $_[0]
}

sub fmt($) {
  my $value = shift;
  return "undef" unless defined($value);
  if (my $class = blessed($value)) {
    return "($class)".show_empty_string($value.""); # let it stringify
  } else {
    return Data::Dumper::Interp::_dbvis($value);
  }
}

my $n_count = 0;
my $s_count = 0;
sub check_numeric($$) { # calls ok(...)
  my ($value, $expected) = @_;
  my $san = Data::Dumper::Interp::_show_as_number($value);
  my $desc = ($expected ? "":"non-")."numeric ".fmt($value);
  my $ok = (!!$san == !!$expected);
  if (!$ok) {
    my $lno = (caller)[2];
    my @msgs = ("----- Failing test at line $lno, got ".u($san)." expecting ".u($expected)."\n",
                "Dump of value:".Data::Dumper::Interp::_dbvis($value)."\n",
                "Repeating with Debug enabled...\n");
    my $san2 = do{
      local $SIG{__WARN__} = sub{ push @msgs, $_[0]; };
      local $Data::Dumper::Interp::Debug = 1;
      Data::Dumper::Interp::_show_as_number($value);
    };
    push @msgs, "Urp! Different result with Debug==1:". u($san2)
      if u($san2) ne u($san);
    diag @msgs;
  }
#FUTURE
#  if ($ok && defined($value)) {
#    my $str = visnew->Useqq(1)->vis($value);
#    if ( (!$expected) ne !!($str =~ /^"/) ) {
#      diag "$desc value=",u($value)," not formatted accordingly:$str";
#      $ok = 0;
#    }
#  }
  @_ = ($ok, $desc);
  goto &Test2::V0::ok;  # so caller's line number is shown on failure
}


diag "=== prelim checks ===";

check_numeric("mumble", 0);
check_numeric("-1",     0);
check_numeric(1,        1);
check_numeric(-1,       1);
check_numeric(3 < 4,    0); # is_bool

diag "=== numerics ===";
for my $v (-1, 0, 1, 42, $nan, $inf, $minf) {
  for my $value ($v,
                 Math::BigInt->new("$v"),
                 Math::BigFloat->new("$v"),
                 Math::BigRat->new("$v")) {
    check_numeric($value, 1);
  }
}
check_numeric(Math::BigRat->new("17/27"), 1);
check_numeric(Math::BigRat->new("-17/27"), 1);

diag "=== undef ===";
check_numeric(undef, 0);

diag "=== strings ===";
for my $value ("", "-1", "0", "00", "001", "1", "42", "19/37",
               (map{ chr($_) } (0..260)),
               (map{ "0".chr($_) } (0..260)),
               (map{ "-1".chr($_) } (0..260)),
              ) {
  check_numeric($value, 0);
}

diag "=== numbers with 'use bigrat' ===";
{
  use bigrat;
  check_numeric(-1, 1);
  check_numeric(0, 1);
  check_numeric(1, 1);
  check_numeric(0.5, 1);
  check_numeric(1/9, 1);
}

done_testing();

#say "Checked $n_count numerics and $s_count strings";

exit 0;
