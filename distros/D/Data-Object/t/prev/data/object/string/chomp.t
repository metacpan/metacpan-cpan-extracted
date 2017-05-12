use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'chomp';

use Scalar::Util 'refaddr';

subtest 'test the chomp method' => sub {
    my $string = Data::Object::String->new("name, age, dob, email\n");
    my $chomped = $string->chomp;

    isnt refaddr($string), refaddr($chomped);
    is "$chomped", 'name, age, dob, email';

    isa_ok $string, 'Data::Object::String';
    isa_ok $chomped, 'Data::Object::String';
};

ok 1 and done_testing;
