#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN
{
    use_ok('Bio::Taxonomy::GlobalNames') || print "Bail out!\n";
}

diag(
"Testing Bio::Taxonomy::GlobalNames $Bio::Taxonomy::GlobalNames::VERSION, Perl $], $^X"
);
