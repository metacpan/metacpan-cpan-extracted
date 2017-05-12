use strict;
use warnings;
use Test::More;

use Data::Object;
use Scalar::Util;

can_ok 'Data::Object', 'const';
subtest 'test the const function' => sub {
    my $const = Data::Object::const(Eg => 'Example');
    is $const, 'Example';
    is Eg(), 'Example';
};

subtest 'test the const function with routine' => sub {
    my $code  = sub { 'Example' };
    my $const = Data::Object::const('Eg' => $code);
    is $const, $code;
    is Eg(), 'Example';
};

subtest 'test the const function with explicit namespace' => sub {
    my $const = Data::Object::const('Eg::Example' => 'Example');
    is $const, 'Example';
    is Eg::Example(), 'Example';
};

subtest 'test the const function with explicit namespace and routine' => sub {
    my $code  = sub { 'Example' };
    my $const = Data::Object::const('Eg::Example' => $code);
    is $const, $code;
    is Eg::Example(), 'Example';
};

ok 1 and done_testing;
