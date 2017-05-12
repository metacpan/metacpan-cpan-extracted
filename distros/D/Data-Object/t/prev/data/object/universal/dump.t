use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Universal';
can_ok 'Data::Object::Universal', 'dump';

subtest 'test the dump method' => sub {
    my $universal = Data::Object::Universal->new(undef);
    is $universal->dump, 'undef';
};

ok 1 and done_testing;
