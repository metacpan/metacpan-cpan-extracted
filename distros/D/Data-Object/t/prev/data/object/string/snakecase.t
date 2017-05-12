use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'snakecase';

use Scalar::Util 'refaddr';

subtest 'test the snakecase method' => sub {
    my $string = Data::Object::String->new('hello world');
    my $snakecase = $string->snakecase;

    isnt refaddr($string), refaddr($snakecase);
    is "$snakecase", 'helloWorld'; # helloWorld

    isa_ok $string, 'Data::Object::String';
    isa_ok $snakecase, 'Data::Object::String';
};

ok 1 and done_testing;
