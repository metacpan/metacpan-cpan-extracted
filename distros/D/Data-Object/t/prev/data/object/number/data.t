use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'data';

subtest 'test the data method' => sub {
    my $number = Data::Object::Number->new('+12345');
    is $number->data, 12345;

    $number = Data::Object::Number->new(-12345);
    is "$number", -12345;
};

ok 1 and done_testing;
