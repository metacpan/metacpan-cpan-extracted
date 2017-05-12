package MoneyConverter;

use Moo;
use namespace::clean;
with 'Data::Money::Converter';

sub convert {
    my ($self, $money, $code) = @_;

    return $money->clone(
        value => $money->value * 2,
        code  => $code
    );
}

package main;

use strict;
use warnings;
use Test::More;
use Data::Money;

my $curr = Data::Money->new(value => 100);
my $conv = MoneyConverter->new;
my $newc = $conv->convert($curr, 'GBP');

cmp_ok($newc->value,  '==', 200,           'value changed');
cmp_ok($newc->code,   'eq', 'GBP',         'code_changed' );
cmp_ok($newc->format, 'eq', $curr->format, 'format same'  );

done_testing;
