use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';
can_ok 'Data::Object::Undef', 'dump';

subtest 'test the dump method' => sub {
    my $undef = Data::Object::Undef->new(undef);
    is $undef->dump, 'undef';
};

ok 1 and done_testing;
