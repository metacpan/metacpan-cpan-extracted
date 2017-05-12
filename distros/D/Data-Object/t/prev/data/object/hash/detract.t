use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'detract';

subtest 'test the detract method' => sub {
    my $hash = Data::Object::Hash->new({1,2,3,4});
    is_deeply $hash->detract, {1,2,3,4};
};

ok 1 and done_testing;
