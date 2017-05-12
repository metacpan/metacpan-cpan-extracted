use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'uppercase';

use Scalar::Util 'refaddr';

subtest 'test the uppercase method' => sub {
    my $string = Data::Object::String->new('exciting');
    my $uppercase = $string->uppercase;

    isnt refaddr($string), refaddr($uppercase);
    is "$uppercase", 'EXCITING';

    isa_ok $string, 'Data::Object::String';
    isa_ok $uppercase, 'Data::Object::String';
};

ok 1 and done_testing;
