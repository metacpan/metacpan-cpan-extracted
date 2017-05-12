#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More;

plan 'no_plan';

use MyClass;

my $obj = MyClass->new({ load_plugins => [qw/ DefaultHook /] });
is $obj->run_hook('default_hook')->[0], 'defaulthook';
