use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use lib 't/lib';
use Test::Class::Load ':all';

{
    package ConstantISA;

    use constant ISA => 1;
}

is(
    exception { is_class_loaded('ConstantISA') },
    undef,
    'no error checking whether class with ISA constant is loaded'
);

{
    package ConstantVERSION;

    use constant VERSION => 1;
}

is(
    exception { is_class_loaded('ConstantVERSION') },
    undef,
    'no error checking whether class with VERSION constant is loaded'
);

done_testing();
