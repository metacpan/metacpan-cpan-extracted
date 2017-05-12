#!/usr/bin/perl
# $Id: prereq.t 1895 2006-09-16 08:14:06Z comdog $

use Test::More;
eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;
prereq_ok();
																																														   