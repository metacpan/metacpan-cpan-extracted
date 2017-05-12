use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';

subtest 'test object overloading' => sub {
    my $integer = Data::Object::Number->new(99999);
    is "$integer", 99999;

    $integer = Data::Object::Number->new('99999');
    ok $integer;
    ok $integer == '99999';
    ok $integer =~ qr/9{5}/;
    is $integer => '99999';
};

ok 1 and done_testing;
