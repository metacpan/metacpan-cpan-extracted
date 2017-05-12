use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'clear';

use Scalar::Util 'refaddr';

subtest 'test the clear method' => sub {
    my $array = Data::Object::Array->new(['a'..'g']);
    my $clear = $array->clear();

    is refaddr($array), refaddr($clear);
    is_deeply $clear, [];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $clear, 'Data::Object::Array';
};

ok 1 and done_testing;
