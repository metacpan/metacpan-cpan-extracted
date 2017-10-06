#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.024

use Test::More;
use Test::CleanNamespaces;

if ( !Test::CleanNamespaces->find_modules() ) {
    plan skip_all => 'No files found to test.';
}

all_namespaces_clean();
