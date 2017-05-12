use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';
can_ok 'Data::Object::Undef', 'data';

subtest 'test the data method' => sub {
    my $string = Data::Object::Undef->new(undef);
    is $string->data, undef;
};

ok 1 and done_testing;
