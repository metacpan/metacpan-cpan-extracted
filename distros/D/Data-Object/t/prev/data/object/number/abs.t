use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'abs';

use Scalar::Util 'refaddr';

subtest 'test the abs method' => sub {
    my $number = Data::Object::Number->new(12);
    my $abs = $number->abs();

    isnt refaddr($number), refaddr($abs);
    is $abs, 12;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $abs, 'Data::Object::Number';
};

ok 1 and done_testing;
