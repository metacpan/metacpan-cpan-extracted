use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'strip';

use Scalar::Util 'refaddr';

subtest 'test the strip method' => sub {
    my $string = Data::Object::String->new('one,  two,  three');
    my $stripped = $string->strip;

    is "$stripped", 'one, two, three';
    isnt refaddr($string), refaddr($stripped);

    isa_ok $string, 'Data::Object::String';
    isa_ok $stripped, 'Data::Object::String';
};

ok 1 and done_testing;
