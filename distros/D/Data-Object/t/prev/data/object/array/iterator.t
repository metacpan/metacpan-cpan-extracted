use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'iterator';

use Scalar::Util 'refaddr';

subtest 'test the iterator method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my $values = [];
    my $i      = 0;
    my @argument = ();

    my $iterator = $array->iterator(@argument);
    while (my $value = $iterator->()) {
        $i++; push @{$values}, $value;
    }

    isnt refaddr($array), refaddr($iterator);
    is_deeply $values, [1,2,3,4,5];
    is $i, 5;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $iterator, 'Data::Object::Code';
};

ok 1 and done_testing;
