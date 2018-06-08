use strict;
use warnings FATAL => 'all';
use feature 'say';
use utf8;
use open qw(:std :utf8);

use Test::More;

use Business::PFR;

sub check_get_check_digit {

    my $self = undef;

    my %tests = (
        '95' => '95',
        '99' => '99',
        '100' => '00',
        '101' => '00',
        '102' => '01',
        '201' => '00',
    );

    foreach my $sum (keys %tests) {
        is(
            Business::PFR::_get_check_digit($self, $sum),
            $tests{$sum},
            "Got correct check digit for sum '$sum'",
        );
    }

}

sub check_valid_pfrs {
    my @valid = (
        '112-233-445 95',
        '700-925-999 00',
    );

    foreach my $pfr (@valid) {
        my $bp = Business::PFR->new(
            value => $pfr,
        );

        ok($bp->is_valid(), "PFR $pfr is valid");
    }

}

sub check_invalid_pfrs {
    my @invalid = (
        '112-233-445 11',
        '',
        'abc',
        { a => 1 },
        undef,
    );

    foreach my $pfr (@invalid) {
        my $bp = Business::PFR->new(
            value => $pfr,
        );

        if (not defined $pfr) {
            $pfr = 'undef';
        } else {
            $pfr = "'$pfr'";
        }

        ok(not($bp->is_valid()), "PFR $pfr is not valid");
    }

}

sub main {

    pass('Loaded ok');

    check_get_check_digit();
    check_valid_pfrs();
    check_invalid_pfrs();

    done_testing();

}
main();
