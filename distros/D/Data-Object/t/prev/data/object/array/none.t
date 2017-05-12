use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'none';

use Scalar::Util 'refaddr';

subtest 'test the none method' => sub {
    my $array = Data::Object::Array->new([2..5]);

    my @argument = (sub { shift() <= 1 });
    my $none = $array->none(@argument);

    isnt refaddr($array), refaddr($none);
    is $none, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $none, 'Data::Object::Number';
};

ok 1 and done_testing;
