use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

# use checkster with check sub
use Checkster 'check';

subtest 'array test' => sub {
    my $var = check->array(1);
    is $var, 0; 

    $var = check->array([]);
    is $var, 1; 

    $var = check->array([1, 2, 3]);
    is $var, 1; 

    $var = check->not->array(1);
    is $var, 1;

    $var = check->all->array([1, 2], 1);
    is $var, 0;

    $var = check->any->array([1, 2], 1);
    is $var, 1;
};

subtest 'number test' => sub {
    my $var = check->number(1.0);
    is $var, 1;

    $var = check->number([]);
    is $var, 0; 

    $var = check->number(1, 2, 0.3);
    is $var, 1; 

    $var = check->not->number('foo');
    is $var, 1;

    $var = check->all->number([1, 2], 1);
    is $var, 0;

    $var = check->any->number([1, 2], 1);
    is $var, 1;
};


done_testing;
