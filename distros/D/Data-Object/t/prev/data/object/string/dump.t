use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'dump';

subtest 'test the dump method' => sub {
    my $string = Data::Object::String->new('abcdefghi');
    is $string->dump, 'abcdefghi';
};

ok 1 and done_testing;
