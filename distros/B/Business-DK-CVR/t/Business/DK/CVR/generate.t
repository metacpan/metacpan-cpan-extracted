# $Id: generate.t,v 1.1 2008-06-11 08:08:00 jonasbn Exp $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok('Business::DK::CVR', qw(generate)); };

my @cvrs;
my $cvr;

ok(@cvrs = Business::DK::CVR->generate());

is(scalar @cvrs, 1);

ok(@cvrs = Business::DK::CVR::generate());

is(scalar @cvrs, 1);

ok($cvr = Business::DK::CVR->generate());

like($cvr, qr/\b\d{8}\b/);

ok($cvr = Business::DK::CVR->generate(2));

is(ref $cvr, 'ARRAY');

ok($cvr = Business::DK::CVR::generate(2));

is(ref $cvr, 'ARRAY');

ok($cvr = Business::DK::CVR->generate(1, 19));

is($cvr, '00000019');

ok($cvr = Business::DK::CVR::generate(1, 19));

is($cvr, '00000019');

dies_ok { @cvrs = Business::DK::CVR->generate(99999999); }
