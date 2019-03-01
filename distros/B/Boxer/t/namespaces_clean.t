#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;
use Test::CleanNamespaces;

my @modules = Test::CleanNamespaces->find_modules;

#all_namespaces_clean;
namespaces_clean grep { $_ ne 'Boxer::Types' } @modules;

TODO: {
	local $TODO = 'uncertain how to clean or if a false positive';

	namespaces_clean 'Boxer::Types';
}

done_testing()
