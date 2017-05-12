#!/usr/bin/perl

use strict;
use warnings;

#use Benchmark qw(cmpthese);
use Test::Benchmark;
use Scalar::Util qw(refaddr reftype blessed);

use Test::More 'no_plan';

is_fastest("opcheck_true", -1, {
	#ref_true => 'ref([])',
	reftype_true => 'package main; reftype([])',
	opcheck_true => 'package main; use B::XSUB::Dumber qw(reftype); reftype([])',
	#ref_false => 'ref(1)',
	#reftype_false => 'reftype(1)',
	#opcheck_false => 'use B::XSUB::Dumber qw(reftype); reftype(1)',
}, "OMG FAST");

