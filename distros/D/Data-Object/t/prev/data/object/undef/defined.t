use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';
can_ok 'Data::Object::Undef', 'defined';

use Scalar::Util 'refaddr';

subtest 'test the defined method' => sub {
    my $undef = Data::Object::Undef->new(undef);
    my $defined = $undef->defined;

    isnt refaddr($undef), refaddr($defined);
    is $defined, 0;

    isa_ok $undef, 'Data::Object::Undef';
    isa_ok $defined, 'Data::Object::Number';

    $defined = $undef->defined(9876543210);

    isnt refaddr($undef), refaddr($defined);
    is $defined, 0;

    isa_ok $undef, 'Data::Object::Undef';
    isa_ok $defined, 'Data::Object::Number';
};

ok 1 and done_testing;
