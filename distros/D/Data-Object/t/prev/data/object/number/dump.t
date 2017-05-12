use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'dump';

subtest 'test the dump method' => sub {
    my $number = Data::Object::Number->new(12345);
    is $number->dump, '12345';
};

ok 1 and done_testing;
