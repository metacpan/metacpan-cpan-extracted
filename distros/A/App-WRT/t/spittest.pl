#!/usr/bin/env perl

use lib 'lib';

use SpitTest;

my $obj = SpitTest->new();

$obj->cat("Persian ");
print $obj->moose;

$obj->moose("dog");
print $obj->moose;
