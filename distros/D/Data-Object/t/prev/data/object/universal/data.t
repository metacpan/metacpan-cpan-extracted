use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Universal';
can_ok 'Data::Object::Universal', 'data';

subtest 'test the data method' => sub {
    my $universal = Data::Object::Universal->new(undef);
    is $universal->data, undef;
};

ok 1 and done_testing;
