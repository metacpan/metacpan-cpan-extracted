use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'rindex';

use Scalar::Util 'refaddr';

subtest 'test the rindex method' => sub {
    my $answer;
    my $string = Data::Object::String->new('explain the unexplainable');

    $answer = $string->rindex('explain');
    is $$answer, 14; # 14
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 0);
    is $$answer, 0; # 0
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 21);
    is $$answer, 14; # 14
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 22);
    is $$answer, 14; # 14
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 23);
    is $$answer, 14; # 14
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 20);
    is $$answer, 14; # 14
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 14);
    is $$answer, 14; # 14
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 13);
    is $$answer, 0; # 0
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explain', 0);
    is $$answer, 0; # 0
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->rindex('explained');
    is $$answer, -1; # -1
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Integer';
};

ok 1 and done_testing;
