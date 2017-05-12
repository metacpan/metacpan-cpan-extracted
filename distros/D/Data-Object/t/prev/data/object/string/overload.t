use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';

subtest 'test object overloading' => sub {
    my $string = Data::Object::String->new('');
    is "$string", '';

    $string = Data::Object::String->new('longgggg');
    ok $string;
    ok $string eq 'longgggg';
    ok $string =~ qr/long+/;
    is "$string", 'longgggg';
};

ok 1 and done_testing;
