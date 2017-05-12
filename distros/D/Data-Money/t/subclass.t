use Test::More;
use strict;
use warnings;
use Data::Money;

## subclass Data::Money
{
    package Data::Money::Too;

    use Moo;
    extends 'Data::Money';
}


## test subclass
{
    my $m1 = Data::Money::Too->new(value => 1);
    cmp_ok(ref $m1, 'eq', 'Data::Money::Too', 'subclass new');

    my $m2 = $m1 + 2;
    cmp_ok(ref $m2, 'eq', 'Data::Money::Too', 'add num');

    my $m3 = $m2 - $m1;
    cmp_ok(ref $m3, 'eq', 'Data::Money::Too', 'subtract Money');
};

{
    my $gbp = Data::Money::Too->new(code => 'GBP', value => 1);
    my $cad = Data::Money::Too->new(code => 'CAD', value => 1);

    eval { my $result = $gbp + $cad; };
    ok($@ =~ /unable to perform arithmetic on different currency types/, 'code comparison caught for subclassed money types');
};

done_testing;
