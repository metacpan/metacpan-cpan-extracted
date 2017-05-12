use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'hashify';

use Scalar::Util 'refaddr';

subtest 'test the hashify method - natural' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $hashify = $array->hashify(@argument);

    isnt refaddr($array), refaddr($hashify);
    is_deeply $hashify, {1=>1,2=>1,3=>1,4=>1,5=>1};

    isa_ok $array, 'Data::Object::Array';
    isa_ok $hashify, 'Data::Object::Hash';
};

subtest 'test the hashify method - codified' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ('$a % 2');
    my $hashify = $array->hashify(@argument);

    isnt refaddr($array), refaddr($hashify);
    is_deeply $hashify, {1=>1,2=>0,3=>1,4=>0,5=>1};

    isa_ok $array, 'Data::Object::Array';
    isa_ok $hashify, 'Data::Object::Hash';
};

ok 1 and done_testing;
