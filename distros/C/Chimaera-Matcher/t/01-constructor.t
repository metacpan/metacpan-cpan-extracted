#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;


BEGIN {
    use_ok( 'Chimaera::Matcher' ) || print "Can't find the Chimaera::Matcher module!\n";
}

# Build a Chimaera::Matcher object - this should work
my $good = Chimaera::Matcher->new(

	'haplotype1' => 'AACGTGTCG',
	'haplotype2' => 'CGGGATTAG'

);
ok( defined($good) && ref $good eq 'Chimaera::Matcher', 'new() works with two haplotypes' );

# Build a Chimaera::Matcher object with no haplotype1 defined - should throw an Exception
throws_ok { my $bad1 = Chimaera::Matcher->new('haplotype2' => 'CGGGATTAG') } 'Error::Simple', 'new() fails with no haplotype 1' ;

# Build a Chimaera::Matcher object with no haplotype2 defined - should throw an Exception
throws_ok { my $bad2 = Chimaera::Matcher->new('haplotype1' => 'CGGGATTAG') } 'Error::Simple', 'new() fails with no haplotype 2' ;

# Build a Chimaera::Matcher object with two haplotypes defined - should work
lives_ok { my $good = Chimaera::Matcher->new('haplotype1' => 'CGGGATTAG', 'haplotype2' => 'CGGGATCAG') } 'No error when given two (different) equal length haplotypes' ;


# Build a Chimaera::Matcher object with two haplotypes of differing length - should throw an Exception
throws_ok { my $bad3 = Chimaera::Matcher->new('haplotype1' => 'CGGGATTAG', 'haplotype2' => 'CGGGATTAGCCCC') } 'Error::Simple', 'new() fails when haplotypes are of different length' ;


# Build a Chimaera::Matcher object with two empty haplotypes - should throw an Exception
throws_ok { my $bad4 = Chimaera::Matcher->new('haplotype1' => '', 'haplotype2' => '') } 'Error::Simple', 'new() fails when haplotypes are empty strings' ;

# Build a Chimaera::Matcher object with two identical haplotypes - should throw an Exception
throws_ok { my $bad5 = Chimaera::Matcher->new('haplotype1' => 'CGGGATTAG', 'haplotype2' => 'CgggATTAG') } 'Error::Simple', 'new() fails when haplotypes are identical' ;
