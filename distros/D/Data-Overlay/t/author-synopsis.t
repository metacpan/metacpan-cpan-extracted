#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use Test::More;
use Data::Overlay;

my $out = qx(perl -x -MData::Overlay $INC{"Data/Overlay.pm"});
is( $?, 0, "SYNOPSIS runs under -x")
    or diag "system perl -x SYNOPSIS failed: $?\n$!";
like($out, qr/\$VAR/, "SYNOPSIS output looks like Data::Dumper" );

done_testing();
