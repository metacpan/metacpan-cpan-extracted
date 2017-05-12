use Test::More;
use strict;
use warnings;
use Encode;

use Test::utf8;

use Data::Money;
## currency around the world
{
    my $m = Data::Money->new(value => 1);
    cmp_ok($m->as_string, 'eq', '$1.00', 'USD formatting');

    eval { my $m2 = Data::Money->new(value => 1.345); };
    ok($@ =~ /Excessive precision for this currency type/, 'USD only has two decimal places');

    my $yen = Data::Money->new(code => 'JPY', value => 1);
    cmp_ok($yen->as_string, 'eq', '¥1', 'JPY formatting');

    eval { my $yen2 = Data::Money->new(code => 'JPY', value => 1.1); };
    ok($@ =~ /Excessive precision for this currency type/, 'JPY has no decimal places');

    my $bah = Data::Money->new(code => 'BHD', value => 1);
    cmp_ok($bah->as_string, 'eq', 'BD 1.000', 'BHD formatting');

    my $bah2 = Data::Money->new(code => 'BHD', value => 1.345);
    cmp_ok($bah2->as_string, 'eq', 'BD 1.345', 'BHD formatting');

    my $bah3 = Data::Money->new(code => 'BHD', value => 1.34);
    cmp_ok($bah3->as_string, 'eq', 'BD 1.340', 'BHD formatting');

    eval { Data::Money->new(code => 'BHD', value => 1.3456); };
    ok($@ =~ /Excessive precision for this currency type/, 'BHD only has three decimal places');

};

done_testing();
