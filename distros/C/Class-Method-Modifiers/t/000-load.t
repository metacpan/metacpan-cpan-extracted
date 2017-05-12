use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

do {
    package Class;
    use Class::Method::Modifiers;

    sub foo { }

    before foo => sub {
    };

    after foo => sub {
    };

    around foo => sub {
    };
};

pass("loaded correctly");

done_testing;
