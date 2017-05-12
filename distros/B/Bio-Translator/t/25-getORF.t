#!perl

use Test::More 'no_plan';
use Bio::Util::DNA qw(randomDNA);

use Bio::Translator::Utils;

my $utils = new Bio::Translator::Utils;

ok( $utils->getORF( randomDNA() ), 'getORF ran' );
