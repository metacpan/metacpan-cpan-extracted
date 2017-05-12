use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'rotate';

use Scalar::Util 'refaddr';

subtest 'test the rotate method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $rotate = $array->rotate(@argument);

    is refaddr($array), refaddr($rotate);
    is_deeply $rotate, [qw(2 3 4 5 1)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $rotate, 'Data::Object::Array';
};

ok 1 and done_testing;
