use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'keyed';

use Scalar::Util 'refaddr';

subtest 'test the keyed method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ('a'..'d');
    my $keyed = $array->keyed(@argument);

    isnt refaddr($array), refaddr($keyed);
    is_deeply $keyed, {a=>1,b=>2,c=>3,d=>4};

    isa_ok $array, 'Data::Object::Array';
    isa_ok $keyed, 'Data::Object::Hash';
};

ok 1 and done_testing;
