use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';

#plan 'no_plan';
plan tests => 1;

is( AnnoCPAN::Config->option('cpan_root'), 't/CPAN', 'option');
