use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Scalar';
can_ok 'Data::Object::Scalar', 'dump';

subtest 'test the dump method' => sub {
    my $arrayref = [ 1, 2, 3 ];
    my $scalar = Data::Object::Scalar->new($arrayref);
    is $scalar->dump, q([1,2,3]);
};

ok 1 and done_testing;
