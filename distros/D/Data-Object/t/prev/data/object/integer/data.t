use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'data';

subtest 'test the data method' => sub {
    my $integer = Data::Object::Number->new(99999);
    is $integer->data, 99999;

    $integer = Data::Object::Number->new('99999');
    is "$integer", 99999;
};

ok 1 and done_testing;
