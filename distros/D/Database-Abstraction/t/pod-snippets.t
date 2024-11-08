#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Pod::Snippets';

my @modules = qw/ Database::Abstraction /;
Test::Pod::Snippets->import();
Test::Pod::Snippets->new()->runtest(module => $_, testgroup => 1) for @modules;

done_testing();
