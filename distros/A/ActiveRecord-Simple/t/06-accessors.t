#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

package t::class;

use base 'ActiveRecord::Simple';

__PACKAGE__->table_name('t');
__PACKAGE__->columns(['foo', 'bar']);
__PACKAGE__->primary_key('foo');

1;

use Test::More;

ok my $c = t::class->new({
    foo => 1,
    bar => 2,
});

ok $c->foo;
is $c->foo, 1;

ok $c->bar;
is $c->bar, 2;

ok $c->foo(3);
is $c->foo, 3;

ok $c->foo(4)->bar(5);

is $c->foo, 4;
is $c->bar, 5;


done_testing();
