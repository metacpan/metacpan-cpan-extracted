use Test::More;
use strict;
use warnings;

use Data::Money;

##  test a sane value
{
    my $m = Data::Money->new(value => '$21.00');
    cmp_ok($m->as_string, 'eq', '$21.00', 'Strip the $ symbol');
};

##  test an insane one
{
    my $m = Data::Money->new(value => 'xyz234');
    cmp_ok($m->as_string, 'eq', '$234.00', 'Strip all kinds of nonsense');
};

##  just a pure string
{
    my $m = Data::Money->new(value => 'nothing but a string');
    cmp_ok($m->as_string, 'eq', '$0.00', 'Passing it a pure string just makes it zero');
};


done_testing;
