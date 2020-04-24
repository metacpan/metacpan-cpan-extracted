#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use Test::CleanNamespaces;

use strictures 2;
no warnings "experimental::signatures";

my @modules = Test::CleanNamespaces->find_modules;

#all_namespaces_clean;
namespaces_clean grep { $_ ne 'Boxer::Types' } @modules;

TODO: {
	local $TODO = 'uncertain how to clean or if a false positive';

	namespaces_clean 'Boxer::Types';
}

done_testing()
