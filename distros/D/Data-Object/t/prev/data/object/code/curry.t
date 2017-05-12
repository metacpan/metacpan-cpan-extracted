use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'curry';

use Scalar::Util 'refaddr';

subtest 'test the curry method' => sub {
    my $code = Data::Object::Code->new(sub { [@_] });
    my $curry = $code->curry(1,2,3);
    my $result = $curry->call(4,5,6);

    isnt refaddr($code), refaddr($curry);
    is_deeply $result, [1,2,3,4,5,6];

    isa_ok $code, 'Data::Object::Code';
    isa_ok $curry, 'Data::Object::Code';
    isa_ok $result, 'Data::Object::Array';
};

ok 1 and done_testing;
