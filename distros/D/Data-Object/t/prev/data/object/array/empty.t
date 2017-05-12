use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'empty';

use Scalar::Util 'refaddr';

subtest 'test the empty method' => sub {
    my $array = Data::Object::Array->new(['a'..'g']);

    my @argument = ();
    my $empty = $array->empty(@argument);

    is refaddr($array), refaddr($empty);
    is_deeply $empty, [];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $empty, 'Data::Object::Array';
};

ok 1 and done_testing;
