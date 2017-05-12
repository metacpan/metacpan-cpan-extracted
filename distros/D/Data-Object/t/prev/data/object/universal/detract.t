use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Universal';
can_ok 'Data::Object::Universal', 'detract';

subtest 'test the detract method' => sub {
    my $universal = Data::Object::Universal->new(undef);
    is $universal->detract, undef;
};

ok 1 and done_testing;
