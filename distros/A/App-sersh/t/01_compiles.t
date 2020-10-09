use Test::Most;
use 5.010;
use strict;
use warnings;

use FindBin qw($Bin);
use Path::Class qw(file);

lives_ok(
    sub {
        require(file($Bin, '..', 'sersh'));
    },
    'sersh compiles'
);

done_testing;
