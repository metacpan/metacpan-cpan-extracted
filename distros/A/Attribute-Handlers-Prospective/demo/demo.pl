#! /usr/local/bin/perl -w

use v5.6.0;
use Demo;
use base Demo;

my $y :Demo :This($this) = sub :Demo(1,2,3) {};
sub x :Demo(4, 5, 6) :Multi {}
local %z :Demo('hash') :Multi(method,maybe);
