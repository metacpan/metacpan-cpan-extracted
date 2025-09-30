#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 2;

use Assert::Refute::T::Errors;

{
    package T;
    use Assert::Refute qw(:all), { on_fail => 'carp' };
};

warns_like {
    package T;
    try_refute {
        refute 1, "This shouldn't be output";
    };
} [ qr/not ok 1.*1..1.*[Cc]ontract failed/s ], "Warning as expected";

warns_like {
    package T;
    try_refute {
        refute 0, "This shouldn't be output";
    };
} [], "Warning as expected";

