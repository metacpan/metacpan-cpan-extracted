use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';
can_ok 'Data::Object::Undef', 'detract';

subtest 'test the detract method' => sub {
    my $string = Data::Object::Undef->new(undef);
    is $string->detract, undef;
};

ok 1 and done_testing;
