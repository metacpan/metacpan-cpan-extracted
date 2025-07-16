use strict;
use warnings;
use Test::More;
use File::Temp;
use FindBin '$Bin';

plan skip_all => "perl version too old" if $] < 5.020000;
{
  ok(require "$Bin/../bin/csxs-ppcrypt", "require csxs-ppcrypt");
}

# TODO

done_testing();
