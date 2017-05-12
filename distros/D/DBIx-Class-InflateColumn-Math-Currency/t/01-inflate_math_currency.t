#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Data::Dumper;

use Math::Currency;

use DBIx::Class::InflateColumn::Math::Currency;

subtest "Inflate Positive Math::Currency Value" => sub {
    my $value         = Math::Currency->new('1.23');
    my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate($value);

    cmp_ok(ref $math_currency, 'eq', 'Math::Currency', "Check Return Type");
    cmp_ok($math_currency,     '==', $value, "Check Value");
};

subtest "Inflate Positive Integer Value" => sub {
    my $value         = Math::Currency->new('42');
    my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate($value);

    cmp_ok(ref $math_currency, 'eq', 'Math::Currency', "Check Return Type");
    cmp_ok($math_currency,     '==', $value, "Check Value");
};

subtest "Inflate Positive Float Value" => sub {
    my $value         = 1.23;
    my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate($value);

    cmp_ok(ref $math_currency, 'eq', 'Math::Currency', "Check Return Type");
    cmp_ok($math_currency,     '==', $value, "Check Value");
};

subtest "Inflate Negative Math::Currency Value" => sub {
    my $value         = Math::Currency->new('-1.23');
    my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate($value);

    cmp_ok(ref $math_currency, 'eq', 'Math::Currency', "Check Return Type");
    cmp_ok($math_currency,     '==', $value, "Check Value");
};

subtest "Inflate Negative Integer Value" => sub {
    my $value         = Math::Currency->new('-42');
    my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate($value);

    cmp_ok(ref $math_currency, 'eq', 'Math::Currency', "Check Return Type");
    cmp_ok($math_currency,     '==', $value, "Check Value");
};

subtest "Inflate Negative Float Value" => sub {
    my $value         = -1.23;
    my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate($value);

    cmp_ok(ref $math_currency, 'eq', 'Math::Currency', "Check Return Type");
    cmp_ok($math_currency,     '==', $value, "Check Value");
};

subtest "Inflate Non Numeric Value" => sub {
    throws_ok {
        my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_inflate('NOT A NUMBER');
    } qr/Failed to inflate .*/, "Dies on invalid number";
};

done_testing;
