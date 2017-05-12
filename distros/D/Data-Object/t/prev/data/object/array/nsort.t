use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'nsort';

use Scalar::Util 'refaddr';

subtest 'test the nsort method' => sub {
    my $array = Data::Object::Array->new([5,4,3,2,1]);

    my @argument = ();
    my $nsort = $array->nsort(@argument);

    isnt refaddr($array), refaddr($nsort);
    is_deeply $nsort, [qw(1 2 3 4 5)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $nsort, 'Data::Object::Array';
};

ok 1 and done_testing;
