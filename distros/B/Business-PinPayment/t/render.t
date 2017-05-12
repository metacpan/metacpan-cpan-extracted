#!perl -T

use strict;
use warnings;
use Test::More;

plan tests => 3;

use_ok('Business::PinPayment');

can_ok('Business::PinPayment', qw(new card_token json_response response successful error id status));

# Missing API Key
my $fail_charge = Business::PinPayment->new();
my $api_error = $fail_charge->error();

like ($api_error, qr/Missing Secret API Key/, 'Invalid API Key');
