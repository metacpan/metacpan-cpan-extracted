use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'uc';

use Scalar::Util 'refaddr';

subtest 'test the uc method' => sub {
    my $string = Data::Object::String->new('exciting');
    my $uppercased = $string->uc;

    isnt refaddr($string), refaddr($uppercased);
    is "$uppercased", 'EXCITING';

    isa_ok $string, 'Data::Object::String';
    isa_ok $uppercased, 'Data::Object::String';
};

ok 1 and done_testing;
