use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Integer';
can_ok 'Data::Object::Integer', 'dump';

subtest 'test the dump method' => sub {
    my $integer = Data::Object::Integer->new(-12345);
    is $integer->dump, '-12345';
};

ok 1 and done_testing;
