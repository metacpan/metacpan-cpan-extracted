use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 3;}

use MyPerson;

my $instance = MyPerson->new(
    -first_name => 'foo',
    -last_name => 'bar',
);

ok $instance->first_name, 'foo';
ok $instance->last_name, 'bar';
ok $instance->full_name, 'foo bar';

