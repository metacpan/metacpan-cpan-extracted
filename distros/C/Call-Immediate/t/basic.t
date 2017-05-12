use FindBin;
use lib "$FindBin::Bin";

use Test::More tests => 6;

BEGIN { use_ok('TestImmediate') }

my $ctr;
BEGIN { $ctr = 0 }

is($ctr++, 3);

begin {
    is($ctr++, 0);
    is($ctr++, 1);
};

xbegin is($ctr++, 2);

is($ctr++, 4);
