use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'lcfirst';

use Scalar::Util 'refaddr';

subtest 'test the lcfirst method' => sub {
    my $string = Data::Object::String->new('EXCITING');
    my $lowercased = $string->lcfirst;

    isnt refaddr($string), refaddr($lowercased);
    is "$lowercased", 'eXCITING'; # eXCITING

    isa_ok $string, 'Data::Object::String';
    isa_ok $lowercased, 'Data::Object::String';
};

ok 1 and done_testing;
