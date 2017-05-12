#!perl

use 5.010;
use strict;
use warnings;

use Code::Embeddable;
use Test::More 0.98;

subtest pick => sub {
    is_deeply([Code::Embeddable::pick()], [undef]);
    is_deeply([Code::Embeddable::pick(1)], [1]);
    # XXX test randomness
};

subtest pick_n => sub {
    is_deeply([Code::Embeddable::pick_n(1)], []);
    is_deeply([Code::Embeddable::pick_n(2)], []);
    is_deeply([Code::Embeddable::pick_n(1, "a")], ["a"]);
    is_deeply([Code::Embeddable::pick_n(2, "a")], ["a"]);
    # XXX test randomness
};

subtest shuffle => sub {
    is_deeply([Code::Embeddable::shuffle()], []);
    is_deeply([Code::Embeddable::shuffle(1)], [1]);
    # XXX test randomness
};

subtest uniq => sub {
    is_deeply([Code::Embeddable::uniq(1,1,4,2,4,7,2,2)], [1,4,2,7]);
};

done_testing;
