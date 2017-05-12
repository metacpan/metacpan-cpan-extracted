use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'detract';

subtest 'test the detract method' => sub {
    my $code = Data::Object::Code->new(sub { 'test' });
    isa_ok $code->detract, 'CODE';
    is $code->detract->(), 'test';
};

ok 1 and done_testing;
