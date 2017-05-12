use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'downto';

use Scalar::Util 'refaddr';

subtest 'test the downto method' => sub {
    my $number = Data::Object::Number->new(10);
    my $downto = $number->downto(0);

    isnt refaddr($number), refaddr($downto);
    is_deeply $downto, [10,9,8,7,6,5,4,3,2,1,0];

    isa_ok $number, 'Data::Object::Number';
    isa_ok $downto, 'Data::Object::Array';
};

ok 1 and done_testing;
