use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';

subtest 'test object overloading' => sub {
    my $string = Data::Object::Undef->new(undef);
    ok !$string;
};

ok 1 and done_testing;
