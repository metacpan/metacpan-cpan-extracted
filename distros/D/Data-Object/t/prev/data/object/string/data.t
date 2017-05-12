use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'data';

subtest 'test the data method' => sub {
    my $string = Data::Object::String->new('');
    is $string->data, '';

    $string = Data::Object::String->new('longgggg');
    is "$string", 'longgggg';
};

ok 1 and done_testing;
