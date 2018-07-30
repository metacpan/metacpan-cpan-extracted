#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 2;
use Assert::Refute::T::Errors;

warns_like {
    package T;
    use Assert::Refute;

    try_refute {
        refute 1, "This fails";
    };
} [qr/try_refute.*configure.*DEPRECATED/, qr/not ok 1 - This fails/], "Deprecated + failure auto-warns";

warns_like {
    package T2;
    use Assert::Refute;

    try_refute {
        refute 0, "This passes";
    };
} qr/try_refute.*configure.*DEPRECATED/, "Only deprecated warning";


