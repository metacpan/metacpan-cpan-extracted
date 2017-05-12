use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'reverse';

use Scalar::Util 'refaddr';

subtest 'test the reverse method' => sub {
    my $string = Data::Object::String->new('dlrow ,olleH');
    my $reversed = $string->reverse;

    isnt refaddr($string), refaddr($reversed);
    is "$reversed", 'Hello, world'; # Hello, world

    isa_ok $string, 'Data::Object::String';
    isa_ok $reversed, 'Data::Object::String';
};

ok 1 and done_testing;
