use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'rnsort';

use Scalar::Util 'refaddr';

subtest 'test the rnsort method' => sub {
    my $array = Data::Object::Array->new([5,4,3,2,1]);

    my @argument = ();
    my $rnsort = $array->rnsort(@argument);

    isnt refaddr($array), refaddr($rnsort);
    is_deeply $rnsort, [5,4,3,2,1];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $rnsort, 'Data::Object::Array';
};

ok 1 and done_testing;
