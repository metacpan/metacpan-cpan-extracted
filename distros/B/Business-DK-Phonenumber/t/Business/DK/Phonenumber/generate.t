# $Id$

use strict;
use Test::More qw(no_plan);
use Data::Dumper;

use_ok('Business::DK::Phonenumber');
my @phonenumbers = ();

ok(@phonenumbers = Business::DK::Phonenumber->generate());

foreach my $phonenumber (@phonenumbers) {
    like($phonenumber, qr/^\+45 \d{8}$/);
}

ok(@phonenumbers = Business::DK::Phonenumber->generate(2));

is(scalar @phonenumbers, 2); 

foreach my $phonenumber (@phonenumbers) {
    like($phonenumber, qr/^\+45 \d{8}$/);
}

ok(@phonenumbers = Business::DK::Phonenumber->generate(2, '%02d %02d %02d %02d'));

foreach my $phonenumber (@phonenumbers) {
    like($phonenumber, qr/^\d{2} \d{2} \d{2} \d{2}$/);
}

ok(@phonenumbers = Business::DK::Phonenumber->generate(100, '%02d %02d %02d %02d'));
