#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;

eval "use Test::Compile";
Test::More->builder->BAIL_OUT(
	"Test::Compile required for testing compilation")
	if $@;

all_pm_files_ok();
