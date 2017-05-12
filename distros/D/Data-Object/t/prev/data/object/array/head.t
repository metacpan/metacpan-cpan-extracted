use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'head';

use Scalar::Util 'refaddr';

subtest 'test the head method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $head = $array->head(@argument);

    isnt refaddr($array), refaddr($head);
    is $head, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $head, 'Data::Object::Number';
};

ok 1 and done_testing;
