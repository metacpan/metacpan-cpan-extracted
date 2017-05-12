#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use Algorithm::SlopeOne;

my $s = Algorithm::SlopeOne->new;

is_deeply(
    $s->predict({ Eastenders => 7.25 }),
    {},
    q(empty),
);

eval { $s->add(1) };
like(
    $@,
    qr/^Expects a HashRef or an ArrayRef of HashRefs at/,
    q(add()),
);

eval { $s->predict(1) };
like(
    $@,
    qr/^Expects a HashRef at/,
    q(predict()),
);

done_testing 3;
