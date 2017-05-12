#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use Algorithm::SlopeOne;

my $s = Algorithm::SlopeOne->new;
isa_ok($s, q(Algorithm::SlopeOne));
can_ok($s, qw(add predict));

$s->add([
    {
        squid       => 1.0,
        cuttlefish  => 0.5,
        octopus     => 0.2,
    }, {
        squid       => 1.0,
        octopus     => 0.5,
        nautilus    => 0.2,
    }, {
        squid       => 0.2,
        octopus     => 1.0,
        cuttlefish  => 0.4,
        nautilus    => 0.4,
    }, {
        cuttlefish  => 0.9,
        octopus     => 0.4,
        nautilus    => 0.5,
    },
]);
is_deeply(
    $s->predict({ squid => 0.4 }),
    { cuttlefish => 0.25, nautilus => 0.1, octopus => 7 / 30 },
    q(range 0-1),
);

$s->clear;

$s->add({
    24          => 9.5,
    Lost        => 8.2,
    House       => 6.8,
});
$s->add({
    24          => 3.7,
    "Big Bang Theory" => 2.1,
    House       => 8.3,
});
$s->add([
    {
        24          => 9.5,
        Lost        => 3.4,
        House       => 5.5,
        "Big Bang Theory" => 9.3,
    }, {
        24          => 7.2,
        Lost        => 5.1,
        House       => 8.4,
        "The Event" => 7.8,
    },
]);
is_deeply(
    $s->predict({ House => 3, q(Big Bang Theory) => 7.5 }),
    { 24 => 4.95, Lost => 1.65, q(The Event) => 2.4 },
    q(range 0-10),
);

is_deeply(
    $s->predict({ Eastenders => 7.25 }),
    {},
    q(non-matching),
);

done_testing 5;
