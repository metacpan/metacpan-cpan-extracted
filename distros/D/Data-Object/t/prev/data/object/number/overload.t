use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';

subtest 'test object overloading' => sub {
    my $number = Data::Object::Number->new(+12345);
    is "$number", 12345;

    $number = Data::Object::Number->new('-12345');
    ok $number;
    ok $number == '-12345';
    ok $number =~ qr/^-12345$/;
    is $number => '-12345';
};

ok 1 and done_testing;
