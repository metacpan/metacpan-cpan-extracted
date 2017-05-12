package TestDeepRecursion;
use strict;
use warnings;
use Constant::Export::Lazy (
    constants => {
        TEST_DEEP_RECURSION => sub {
            my ($ctx) = @_;

            return $ctx->call('TEST_DEEP_RECURSION');
        },
    },
);

package main;
use strict;
use warnings;
use Test::More tests => 3;
BEGIN {
    my @warnings;
    eval {
        local $SIG{__WARN__} = sub {
            chomp(my ($warn) = @_);
            push @warnings => $warn;
            return;
        };
        TestDeepRecursion->import(qw(
            TEST_DEEP_RECURSION
        ));
        1;
    } or do {
        my $error = $@ || "Zombie Error";
        like($error, qr/Deep recursion on anonymous subroutine/, "We died in our recursive subroutine due to FATAL recursion warnings");
    };
    cmp_ok(scalar @warnings, '==', 1, "We also got one additional warning");
    like($warnings[0], qr/Deep recursion on subroutine "Constant::Export::Lazy::Ctx::call"/, "Our warnings <@warnings> matched!");
}
