package TestFloat;

use strict;
use warnings;

use base qw(Exporter);

use Test::More;

our @EXPORT = qw(cmp_float);

sub cmp_float {
    my($got, $wanted, $expn) = @_;
    my $fudge = 1e-8;

    ok(
        (
            $got >= 0 && (
                $wanted * ( 1 - $fudge) < $got &&
                $wanted * ( 1 + $fudge) > $got
            )
        ) || (
            $got < 0 && (
                $wanted * ( 1 - $fudge) > $got &&
                $wanted * ( 1 + $fudge) < $got
            )
        ),
        $expn
    ) || diag("         got: $got\n    expected: $wanted\n"); # copies format of is()'s output
}
