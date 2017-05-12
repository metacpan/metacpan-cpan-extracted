use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'dump';

subtest 'test the dump method' => sub {
    my $hash = Data::Object::Hash->new({1,2,3,4});
    is $hash->dump, '{1 => 2,3 => 4}';
};

ok 1 and done_testing;
