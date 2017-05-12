use strict;
use warnings;
use utf8;

use Acme::MadokaMagica;

use Test::More;

subtest 'Variabe' => sub{
    ok ( defined $magical);
    ok ( defined $miracle);
    is $miracle,'奇跡';
    is $magical,'魔法';
};

done_testing();
