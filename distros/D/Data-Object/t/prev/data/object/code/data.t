use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'data';

subtest 'test the data method' => sub {
    my $code = Data::Object::Code->new(sub { 'test' });
    isa_ok $code->data, 'CODE';
    is $code->data->(), 'test';
};

ok 1 and done_testing;
