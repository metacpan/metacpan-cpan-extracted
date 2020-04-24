#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;

use strictures 2;
no warnings "experimental::signatures";

eval "use Test::Compile";
Test::More->builder->BAIL_OUT(
	"Test::Compile required for testing compilation")
	if $@;

all_pl_files_ok();
