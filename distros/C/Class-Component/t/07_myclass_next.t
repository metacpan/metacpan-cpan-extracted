#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More qw(no_plan);

use MyClass;
MyClass->load_components(qw/ B A /);

my $obj = MyClass->new;
is $obj->test, ' -> A  -> C  -> B  -> D  -> Component ';


MyClass->load_components(qw/ E /);
is $obj->test, ' -> E  -> F  -> A  -> C  -> B  -> D  -> Component ';

