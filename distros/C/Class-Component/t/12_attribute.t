#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More qw(no_plan);

use MyClass;


my $obj = MyClass->new({ load_plugins => [qw/ Attribute /] });

is $obj->call( test => 'test set'), 'attribute return';
is $obj->{test_str}, 'test set';


