#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 54;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Money';
}

is_deeply [ @{ DR::Money->new } ], [ '+', 0, 0, '0.00' ], 'c 0';
is_deeply [ @{ Money 0 } ], [ '+', 0, 0, '0.00' ],       'fc 0';
is_deeply [ @{ Money 0.0001 } ], [ '+', 0, 0, '0.00' ],  'fc 0.0001';
is_deeply [ @{ Money -0.0001 } ], [ '+', 0, 0, '0.00' ], 'fc -0.0001';

is_deeply Money(0.1)->value, '0.10', 'value';
is_deeply +Money(0.1), '0.10', 'overload value';
is_deeply scalar Money(0.1), '0.10', 'overload value';
ok Money(0.1), 'bool positive';
ok Money(-0.1), 'bool negative';
ok !Money(0.00), 'bool zero';
is_deeply scalar Money('-01.122'), '-1.12', 'negative money';
cmp_ok Money(100.1), 'lt', Money(30.01), '100.10 lt 30.01';
cmp_ok Money(100.1), 'lt', 30.01, '100.10 lt 30.01';
cmp_ok Money(100.1), '>', Money(30.01), '100.10 > 30.01';
cmp_ok Money(-100.22), '==', -100.22, '-100.22 == -100.22';
cmp_ok 100.33, '==', Money(100.33), '100.33 == 100.33';

my $m1 = Money(25.23);
cmp_ok $m1, '==', 25.23, 'Constructor 25.23';
my $m2 = $m1;
cmp_ok $m2->value, '==', 25.23, 'copy Constructor 25.23';
$m2 = Money('12.11');
cmp_ok $m1->value, '==', 25.23, 'first value left unchanged 25.23';
cmp_ok $m2->value, '==', 12.11, 'second value is changed 12.11';

is --$m1, Money('25.22'), 'decrement';
is ++$m1, Money('25.23'), 'increment';
is $m1 += 0.1, Money(25.33), 'add in-place';
is $m1 -= 0.1, Money(25.23), 'sub in-place';
is $m1 *= 0.1, Money(2.52), 'mul in-place';
is $m1 /= 0.1, Money(25.20), 'div in-place';
ok !eval{$m1 /= Money(0.1); 1}, 'div in-place';
like $@ => qr{Can't divide money to money}, 'error text';
is $m1, Money(25.20), 'Value after error';

$m1 = Money(-22.23);
is --$m1, Money(-22.24), 'decrement';
is ++$m1, Money(-22.23), 'decrement';

is int Money(-11.11), -11, 'int Money';
is int Money(12.32), 12, 'int Money';

is Money(1) + Money(.1), '1.10', 'add: positive result';
is_deeply Money(-1) + Money(.1), Money('-0.9'), 'add: negative result';

is Money(1.11) * 3, '3.33', 'multiply';
is Money(1.11) * -3, '-3.33', 'multiply';
is Money(-1.11) * -3, '3.33', 'multiply';
is Money(0) * -3, '0.00', 'multiply';
is Money(1.23) - 1.22, '0.01', 'substract';
is 2.11 - Money(1.23), '0.88', 'substract';

is 2.11 / Money(2), '1.055', 'divide';
ok !ref(2.11 / Money(2)), 'number';
is Money(2.11) / Money(2), '1.055', 'divide';
ok !ref(Money(2.11) / Money(2)), 'number';
is Money(2.11) / 2, Money('1.055'), 'divide';
isa_ok Money(2.11) / 2, 'DR::Money', 'money';
ok !eval { (Money(2.11) / 0) || 1 }, 'division by zero';
like $@ => qr{by zero}, 'error message';
ok !eval { (123 / Money(0)) || 1 }, 'division by zero';
like $@ => qr{by zero}, 'error message';
ok !eval { (Money(123) / Money(0)) || 1 }, 'division by zero';
like $@ => qr{by zero}, 'error message';
