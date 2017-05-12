#!/usr/bin/perl -w

use strict;
use Test;
use Business::CINS;

BEGIN { plan tests => 11 }

my $cins = Business::CINS->new();
ok($cins->cins, undef);
ok(!$cins->is_fixed_income);
ok($cins->is_fixed_income(1));
ok($cins->is_fixed_income);
ok($cins->cins('P8055KAP0'), 'P8055KAP0');
ok($cins->domicile_code, 'P');
ok($cins->issuer_num, '8055K');
ok($cins->issue_num, 'AP');

$cins = Business::CINS->new('P805KAPR1', 1);
ok($cins->is_fixed_income);
ok(!$cins->is_fixed_income(0));
ok(!$cins->is_fixed_income);

__END__
