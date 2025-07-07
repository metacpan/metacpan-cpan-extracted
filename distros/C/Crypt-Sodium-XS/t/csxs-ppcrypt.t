use strict;
use warnings;
use Test::More;
use File::Temp;
use FindBin;

SKIP: {
  skip "perl version too old" if $] < 5.020000;
  package Crypt::Sodium::XS::Test::Pminisign;
  require "$FindBin::Bin/../bin/csxs-ppcrypt" or die "require csxs-ppcrypt failed: $@";
}

# TODO

ok(1);

done_testing();
