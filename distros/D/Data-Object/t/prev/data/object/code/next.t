use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'next';

use Scalar::Util 'refaddr';

subtest 'test the next method' => sub {
    my $code = Data::Object::Code->new(sub { (shift // 0) + 1 });
    my $next = $code->next(undef);

    my $result;

    isnt refaddr($code), refaddr($next);
    is $next, 1;

    $next = $code->next(0);
    isa_ok $next, 'Data::Object::Number';

    isnt refaddr($code), refaddr($next);
    is $next, 1;

    $next = $code->next(1);
    isa_ok $next, 'Data::Object::Number';

    isnt refaddr($code), refaddr($next);
    is $next, 2;

    $next = $code->next(2);
    isa_ok $next, 'Data::Object::Number';

    isnt refaddr($code), refaddr($next);
    is $next, 3;

    isa_ok $code, 'Data::Object::Code';
    isa_ok $next, 'Data::Object::Number';
};

ok 1 and done_testing;
