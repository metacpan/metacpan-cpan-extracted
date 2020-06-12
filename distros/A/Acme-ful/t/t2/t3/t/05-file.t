use Test::Most 'die', tests => 2;

use ful {
    file => '02-relative.t',
    libdirs => [qw/lib vendor/],
};

use_ok('Proof05_1');
use_ok('Proof05_2');

done_testing;