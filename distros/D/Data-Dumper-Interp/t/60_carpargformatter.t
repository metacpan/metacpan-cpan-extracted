#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug my_capture_merged/; # Test2::V0 etc.

use Carp;
use Data::Dumper::Interp;

my $cluck_lno;
sub inner(@) {
  # Unfortunately Carp::longmess, contrarary to it's documentation, does
  # not return the same message as cluck/confess.  To avoid this test breaking
  # if that Carp bug is ever fixed, the actual cluck() output is captured.
  $cluck_lno = __LINE__ + 1;
  return my_capture_merged { Carp::cluck("cluck arg"); };
}

my $innercall_lno;
sub outer(@) {
  $innercall_lno = __LINE__ + 1;
  inner("foo", @_, \"YYY", {data => ["A".."F"]});
}

like(Data::Dumper::Interp::RefArgFormatter([1,2], Refaddr => 1),
     qr/^\<.*\>\[1,2\]$/, "direct RefArgFormatter call");

{
  local $Carp::RefArgFormatter = \&Data::Dumper::Interp::RefArgFormatter;
  my $s = outer(1,2,3);
  like( $s,
        qr/cluck arg at .*line $cluck_lno.*\n(?:.|\R)*inner\("foo", 1, 2, 3, .*\\"YYY",.*\{data => .*\["A", *"B", *.*"F"\] *\}.*called at.*${innercall_lno}/,
        "Used as Carp::RefArgFormatter" );
}

{
  local $Carp::RefArgFormatter = sub{
    Data::Dumper::Interp::RefArgFormatter($_[0], Maxdepth => 1) };
  my $s = outer(1,2,3);
  like( $s,
        qr/cluck arg at .*line $cluck_lno.*\n(?:.|\R)*inner\("foo", 1, 2, 3, .*\\"YYY",.*\{data => ARRAY.*\}.*called at.*${innercall_lno}/,
        "Carp::RefArgFormatter using curried Maxdepth => 1" );
}

{
  my $s = outer(1,2,3);
  like( $s,
        qr/cluck arg at .*line $cluck_lno.*\n(?:.|\R)*inner\("foo", 1, 2, 3, SCALAR.*, *HASH.*called at.*${innercall_lno}/,
        "Without Carp::RefArgFormatter" );
}

done_testing();
exit 0;
