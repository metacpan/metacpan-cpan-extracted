use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';

subtest 'test object overloading' => sub {
    my $float = Data::Object::Float->new(.01);
    is "$float", .01;

    $float = Data::Object::Float->new('.01');
    ok $float;
    ok $float == '.01';
    ok $float =~ qr/.01/;
    is $float => '.01';
};

ok 1 and done_testing;
