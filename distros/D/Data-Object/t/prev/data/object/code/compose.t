use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'compose';

use Scalar::Util 'refaddr';

subtest 'test the compose method' => sub {
    my $code = Data::Object::Code->new(sub { [@_] });
    my $compose = $code->compose($code, 1,2,3);
    my $result  = $compose->call(4,5,6);

    isnt refaddr($code), refaddr($compose);
    is_deeply $result, [[1,2,3,4,5,6]];

    isa_ok $code, 'Data::Object::Code';
    isa_ok $compose, 'Data::Object::Code';
    isa_ok $result, 'Data::Object::Array';
};

ok 1 and done_testing;
