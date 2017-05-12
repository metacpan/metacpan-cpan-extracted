use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'contains';

use Scalar::Util 'refaddr';

subtest 'test the contains method' => sub {
    my $answer;
    my $string = Data::Object::String->new('Nullam ultrices placerat nibh vel.');

    $answer = $string->contains('trices');
    is $$answer, 1; # 1; true
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->contains('itrices');
    is $$answer, 0; # 0; false
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->contains(qr/trices/);
    is $$answer, 1; # 1; true
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';

    $answer = $string->contains(qr/itrices/);
    is $$answer, 0; # 0; false
    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';
};

ok 1 and done_testing;
