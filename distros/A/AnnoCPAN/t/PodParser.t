use strict;
use warnings;
use Test::More;
use AnnoCPAN::PodParser;

#plan 'no_plan';
plan tests => 1;

my $parser = AnnoCPAN::PodParser->new;
isa_ok( $parser, 'AnnoCPAN::PodParser' );
