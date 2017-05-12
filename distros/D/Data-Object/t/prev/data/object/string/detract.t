use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'detract';

subtest 'test the detract method' => sub {
    my $string = Data::Object::String->new('');
    is $string->detract, '';

    $string = Data::Object::String->new('longgggg');
    is "$string", 'longgggg';
};

ok 1 and done_testing;
