use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'dump';

subtest 'test the dump method' => sub {
    my $float = Data::Object::Float->new(3.99);
    is $float->dump, '3.99';
};

ok 1 and done_testing;
