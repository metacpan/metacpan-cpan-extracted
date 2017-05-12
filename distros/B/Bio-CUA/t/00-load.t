#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Bio::CUA' ) || print "Bail out!\n";
    use_ok( 'Bio::CUA::Summarizer' ) || print "Bail out!\n";
    use_ok( 'Bio::CUA::SeqIO' ) || print "Bail out!\n";
    use_ok( 'Bio::CUA::Seq' ) || print "Bail out!\n";
    use_ok( 'Bio::CUA::CUB::Builder' ) || print "Bail out!\n";
    use_ok( 'Bio::CUA::CUB::Calculator' ) || print "Bail out!\n";
}

diag( "Testing Bio::CUA $Bio::CUA::VERSION, Perl $], $^X" );
