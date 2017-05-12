use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'rcurry';

use Scalar::Util 'refaddr';

subtest 'test the rcurry method' => sub {
    my $code = Data::Object::Code->new(sub { [@_] });
    my $rcurry = $code->rcurry(1,2,3);
    my $result = $rcurry->call(4,5,6);

    isnt refaddr($code), refaddr($rcurry);
    is_deeply $result, [4,5,6,1,2,3];

    isa_ok $code, 'Data::Object::Code';
    isa_ok $rcurry, 'Data::Object::Code';
    isa_ok $result, 'Data::Object::Array';
};

ok 1 and done_testing;
