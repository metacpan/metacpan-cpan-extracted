use strict;
use warnings;

use Business::CUSIP;
use Business::CUSIP::Random;

use Test::More tests => 1002;

srand($$);
for (1..1000) {
    my $fixed_inc = int rand(2);
    my $cusip = Business::CUSIP::Random->generate(fixed_income => $fixed_inc);
    my $fixed_inc_msg = $fixed_inc ? ' fixed income' : '';
    my $message = $cusip->cusip . " is a valid$fixed_inc_msg CUSIP";
    ok($cusip->is_valid, $message);
}

my $cusip = Business::CUSIP::Random->generate_string;
ok(! ref $cusip, 'generate_string returns a string');

$cusip = Business::CUSIP->new($cusip);
ok( $cusip->is_valid, 'generate_string returns a *valid* string');

