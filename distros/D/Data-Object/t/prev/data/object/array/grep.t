use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'grep';

use Scalar::Util 'refaddr';

subtest 'test the grep method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = (sub { shift >= 3 });
    my $grep = $array->grep(@argument);

    isnt refaddr($array), refaddr($grep);
    is_deeply $grep, [3,4,5];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $grep, 'Data::Object::Array';
};

ok 1 and done_testing;
