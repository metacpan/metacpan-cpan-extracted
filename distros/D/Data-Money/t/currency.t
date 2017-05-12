use Test::More;
use strict;
use warnings;
use Encode;

use Test::utf8;
use Test::Exception;

use Data::Money;

## check defaults
{
    my $m = Data::Money->new;
    cmp_ok($m->code, 'eq', 'USD', 'code default: USD');
    cmp_ok($m->value, '==', 0, 'value default: 0');
    cmp_ok($m->format, 'eq', 'FMT_COMMON', 'format default: FMT_COMMON');
}

## stringfy w/utf8
{
    my $m = Data::Money->new(value => 1);
    cmp_ok($m->as_string, 'eq', '$1.00', 'USD formatting');
    is_sane_utf8($m->as_string);

    my $yen = Data::Money->new(code => 'JPY', value => 1);
    cmp_ok($yen->as_string, 'eq', '¥1', 'JPY formatting');
    is_sane_utf8($m->as_string);

    my $gbp = Data::Money->new(code => 'GBP', value => 1);
    cmp_ok($gbp->as_string, 'eq', '£1.00', 'GBP formatting');
    is_sane_utf8($m->as_string);

    my $cad = Data::Money->new(code => 'CAD', value => 1);
    cmp_ok($cad->as_string, 'eq', '$1.00', 'CAD formatting');
    is_sane_utf8($m->as_string);
};

## unknown code
{
    dies_ok { Data::Money->new(code => 'OMG') } 'unknown currency code';
}

done_testing;
