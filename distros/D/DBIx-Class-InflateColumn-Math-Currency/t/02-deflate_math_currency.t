#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Data::Dumper;

use Math::Currency;

use DBIx::Class::InflateColumn::Math::Currency;

subtest "Deflate Positive Math::Currency Value" => sub {
    my $value = Math::Currency->new('1.23');
    my $float = DBIx::Class::InflateColumn::Math::Currency::_deflate($value);

    cmp_ok(ref \$float, 'eq', 'SCALAR', "Check Return Type");
    cmp_ok($float,     '==', $value, "Check Value");
};

subtest "Deflate Positive Integer Value" => sub {
    my $value = 42;
    my $float = DBIx::Class::InflateColumn::Math::Currency::_deflate($value);

    cmp_ok(ref \$float, 'eq', 'SCALAR', "Check Return Type");
    cmp_ok($float,     '==', $value, "Check Value");
};

subtest "Deflate Positive Float Value" => sub {
    my $value = 1.23;
    my $float = DBIx::Class::InflateColumn::Math::Currency::_deflate($value);

    cmp_ok(ref \$float, 'eq', 'SCALAR', "Check Return Type");
    cmp_ok($float,     '==', $value, "Check Value");
};

subtest "Deflate Negative Math::Currency Value" => sub {
    my $value = Math::Currency->new('-1.23');
    my $float = DBIx::Class::InflateColumn::Math::Currency::_deflate($value);

    cmp_ok(ref \$float, 'eq', 'SCALAR', "Check Return Type");
    cmp_ok($float,     '==', $value, "Check Value");
};

subtest "Deflate Negative Integer Value" => sub {
    my $value = -42;
    my $float = DBIx::Class::InflateColumn::Math::Currency::_deflate($value);

    cmp_ok(ref \$float, 'eq', 'SCALAR', "Check Return Type");
    cmp_ok($float,     '==', $value, "Check Value");
};

subtest "Deflate Negative Float Value" => sub {
    my $value = -1.23;
    my $float = DBIx::Class::InflateColumn::Math::Currency::_deflate($value);

    cmp_ok(ref \$float, 'eq', 'SCALAR', "Check Return Type");
    cmp_ok($float,     '==', $value, "Check Value");
};

subtest "Deflate Non Numeric Value" => sub {
    throws_ok {
        my $math_currency = DBIx::Class::InflateColumn::Math::Currency::_deflate('NOT A NUMBER');
    } qr/Failed to deflate .*/, "Dies on invalid number";
};

done_testing;
