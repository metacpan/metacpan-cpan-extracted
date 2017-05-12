use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'concat';

use Scalar::Util 'refaddr';

subtest 'test the concat method' => sub {
    my $string = Data::Object::String->new('ABC');
    my $concatenated = $string->concat('DEF', 'GHI');

    isnt refaddr($string), refaddr($concatenated);
    is "$concatenated", 'ABCDEFGHI'; # ABCDEFGHI

    isa_ok $string, 'Data::Object::String';
    isa_ok $concatenated, 'Data::Object::String';
};

ok 1 and done_testing;
