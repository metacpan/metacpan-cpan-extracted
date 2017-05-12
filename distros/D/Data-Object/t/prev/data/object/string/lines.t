use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'lines';

use Scalar::Util 'refaddr';

subtest 'test the lines method' => sub {
    my $string = Data::Object::String->new(
        "who am i?\nwhere am i?\nhow am I here\n"
    );

    my $lines = $string->lines;

    is_deeply $lines, ['who am i?','where am i?','how am I here'];

    isa_ok $string, 'Data::Object::String';
    isa_ok $lines, 'Data::Object::Array';
};

ok 1 and done_testing;
