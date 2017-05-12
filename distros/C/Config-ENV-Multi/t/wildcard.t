package MyConfig;
use strict;
use warnings;
use Config::ENV::Multi 'ENV',
    any => ':any:', unset => ':unset:';

config ':any:' => {
    any => 1,
};

config ':unset:' => {
    unset => 1,
};

use Test::More;
use Test::Deep;

undef $ENV{ENV};
cmp_deeply +__PACKAGE__->current, {
    unset => 1,
    any   => 1,
};

$ENV{ENV} = 'dev';
cmp_deeply +__PACKAGE__->current, {
    any => 1,
};


done_testing;
