#!/usr/bin/perl -w

use strict;
use Test;
use Business::CUSIP;

BEGIN { plan tests => 10 }

my $cusip = Business::CUSIP->new();
ok($cusip->cusip, undef);
ok(!$cusip->is_fixed_income);
ok($cusip->is_fixed_income(1));
ok($cusip->is_fixed_income);
ok($cusip->cusip('92940*118'), '92940*118');
ok($cusip->issuer_num, '92940*');
ok($cusip->issue_num, '11');

$cusip = Business::CUSIP->new('125144AC9', 1);
ok($cusip->is_fixed_income);
ok(!$cusip->is_fixed_income(0));
ok(!$cusip->is_fixed_income);

__END__
