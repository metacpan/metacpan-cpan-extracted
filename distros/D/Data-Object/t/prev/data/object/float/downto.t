use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'downto';

use Scalar::Util 'refaddr';

subtest 'test the downto method' => sub {
    my $integer = Data::Object::Float->new(10.9999);
    my $downto = $integer->downto(0);

    isnt refaddr($integer), refaddr($downto);
    is_deeply $downto, [10,9,8,7,6,5,4,3,2,1,0];

    isa_ok $integer, 'Data::Object::Float';
    isa_ok $downto, 'Data::Object::Array';
};

ok 1 and done_testing;
