#!perl -T

use Test::More tests => 10;
use strict;
use warnings;

BEGIN
{
  use_ok( 'Bio::GeneDesign' )               || print "Can't use GeneDesign\n";
  use_ok( 'Bio::GeneDesign::Basic' )        || print "Can't use Basic\n";
  use_ok( 'Bio::GeneDesign::Codons' )       || print "Can't use Codons\n";
  use_ok( 'Bio::GeneDesign::CodonJuggle' )  || print "Can't use CodonJuggle\n";
  use_ok( 'Bio::GeneDesign::Oligo' )        || print "Can't use Oligo\n";
  use_ok( 'Bio::GeneDesign::Random' )       || print "Can't use Random\n";
  use_ok( 'Bio::GeneDesign::PrefixTree' )   || print "Can't use PrefixTree\n";

  use_ok( 'Bio::GeneDesign::RestrictionEnzyme' )
      || print "Can't use RestrictionEnzyme\n";

  use_ok( 'Bio::GeneDesign::RestrictionEnzymes' )
      || print "Can't use RestrictionEnzymes\n";

  use_ok( 'Bio::GeneDesign::ReverseTranslate' )
      || print "Can't use ReverseTranslate\n";
}

