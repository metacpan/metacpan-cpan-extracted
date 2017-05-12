use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'append';

use Scalar::Util 'refaddr';

subtest 'test the append method' => sub {
    my $string = Data::Object::String->new('firstname');
    my $appended = $string->append('lastname');

    isnt refaddr($string), refaddr($appended);
    is "$appended", 'firstname lastname';

    isa_ok $string, 'Data::Object::String';
    isa_ok $appended, 'Data::Object::String';
};

ok 1 and done_testing;
