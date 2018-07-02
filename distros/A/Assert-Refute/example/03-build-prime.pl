#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

=pod

This example builds a prime number test, tests it, and runs some checks
against command line arguments.

It should be split into 3 files denoted by BEGIN ... END here
in a real-life application:

=over

=item * lib/My/Prime.pm - a module exporting is_prime check by default;

=item * t/my-prime.t - a unit test that tests the test;

It actually caught a bug in my prime definition on first run of this script!

=item * bin/test-primes.pl - a binary that works on input.

=back

=cut

# --- BEGIN lib/My/Prime.pm ---
# We're not exporting anything just yet (already in main)
# But if we did, Exporter has to be use'd manually just yet
use parent qw(Exporter);
use Assert::Refute::Build;

# build refutation
build_refute is_prime => sub {
    my $n = shift;

    # get rid of inappropriate values
    return "not a positive number: ".to_scalar($n)
        unless defined $n and $n =~ /^\+?\d+$/;

    # handle corner cases
    return "$n is not prime" if $n <= 1;

    # look for a refutation
    for( my $i = 2; $i*$i <= $n; $i++) {
        $n % $i or return "$i divides $n";
    };

    # found none
    return 0;
}, args => 1, export => 1;
# prototyped for 1 meaningful argument + optional descriprion
# added to @EXPORT (export_ok works just the same)
1;
# --- END lib/My/Prime.pm ---

if (!@ARGV) {
    # test the test!
    # --- BEGIN t/my-prime-test.t ---
    use Assert::Refute;
    my $spec = contract {
        is_prime( $_ ) for @_;
    };

    note "SELF-TEST";
    my $report = $spec->apply( "Foo", 0, 1, 2, 3, 4, 5, 37, 55 );
    # t=start testing; N= 1 failed test; nnn = many passed tests; d = done
    is $report->get_sign, "tNNN2N2Nd", "Results as expected";
    like $report->get_result(6), qr/\b2\b/, "Reason for 4 contains 2";
    like $report->get_result(9), qr/\b5\b/, "Reason for 55 contains 5";
    note "<REPORT>\n".$report->get_tap."</REPORT>";
    done_testing;
    # --- END t/my-prime-test.t ---
} else {
    # --- BEGIN bin/test-primes.pl ---
    # use Test::More;
    # use My::Prime;

    # Just work on input.
    is_prime( $_, "$_ is prime" ) for @ARGV;
    done_testing;
    # --- END bin/test-primes.pl ---
};
