use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'ucfirst';

use Scalar::Util 'refaddr';

subtest 'test the ucfirst method' => sub {
    my $string = Data::Object::String->new('exciting');
    my $ucfirst = $string->ucfirst;

    isnt refaddr($string), refaddr($ucfirst);
    is "$ucfirst", 'Exciting';

    isa_ok $string, 'Data::Object::String';
    isa_ok $ucfirst, 'Data::Object::String';
};

ok 1 and done_testing;
