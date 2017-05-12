use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'call';

use Scalar::Util 'refaddr';

subtest 'test the call method' => sub {
    my $code = Data::Object::Code->new(sub { (shift // 0) + 1 });
    my $call = $code->call(undef);

    my $result;

    isnt refaddr($code), refaddr($call);
    is $call, 1;

    $call = $code->call(0);
    isa_ok $call, 'Data::Object::Number';

    isnt refaddr($code), refaddr($call);
    is $call, 1;

    $call = $code->call(1);
    isa_ok $call, 'Data::Object::Number';

    isnt refaddr($code), refaddr($call);
    is $call, 2;

    $call = $code->call(2);
    isa_ok $call, 'Data::Object::Number';

    isnt refaddr($code), refaddr($call);
    is $call, 3;

    isa_ok $code, 'Data::Object::Code';
    isa_ok $call, 'Data::Object::Number';
};

ok 1 and done_testing;
