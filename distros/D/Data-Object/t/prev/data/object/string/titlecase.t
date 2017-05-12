use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'titlecase';

use Scalar::Util 'refaddr';

subtest 'test the titlecase method' => sub {
    my $string = Data::Object::String->new('mr. wellington III');
    my $titlecased = $string->titlecase;

    isnt refaddr($string), refaddr($titlecased);
    is "$titlecased", 'Mr. Wellington III';

    isa_ok $string, 'Data::Object::String';
    isa_ok $titlecased, 'Data::Object::String';
};

ok 1 and done_testing;
