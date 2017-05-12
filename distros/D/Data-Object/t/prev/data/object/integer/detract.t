use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'detract';

subtest 'test the detract method' => sub {
    my $integer = Data::Object::Number->new(99999);
    is $integer->detract, 99999;

    $integer = Data::Object::Number->new('99999');
    is "$integer", 99999;
};

ok 1 and done_testing;
