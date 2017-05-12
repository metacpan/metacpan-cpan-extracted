#!perl 

use strict;
use warnings;

use Test::More;
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

BEGIN {
	use_ok( 'Algorithm::MasterMind' );
	use_ok( 'Algorithm::MasterMind::Secret');
	use_ok( 'Algorithm::MasterMind::Test' );
	BEGIN { use_ok('Algorithm::MasterMind', qw(check_combination)); };

}

diag( "Testing Algorithm::Mastermind $Algorithm::MasterMind::VERSION, Perl $], $^X" );

my @combinations = qw( AAAA AABB AAAB ABCD ABCD AFFF);
my @strings = qw( ABBB BBAA BAAA BADC ABCD EAEE);
my @results = ( { blacks => 1,
		  whites => 0 },
		{ blacks => 0,
		  whites => 4 },
		{ blacks => 2,
		  whites => 2 },
		{ blacks => 0,
		  whites => 4 },
		{ blacks => 4,
		  whites => 0 },
		{ blacks => 0,
		  whites => 1} );

my @secrets;
while (@combinations ) {
  my $combination = shift @combinations;
  my $secret = new Algorithm::MasterMind::Secret $combination;
  push @secrets, $secret;
  my $string = shift @strings;
  my $result = shift @results;
  my $result_obtained = check_combination( $combination, $string );
  my $other_result_obtained = $secret->check($string);
  is( $secret->string, $combination, "Atributes");
  is_deeply( $result_obtained, $result, "$string vs $combination");
  is_deeply( $other_result_obtained, $result, "Secret $string vs $combination");
}

my $code = 'BCAD';
my $sikrit = new Algorithm::MasterMind::Secret $code;
for my $s (@secrets ) {
  my $one_result = check_combination( $s->{'_string'}, $code );
  my $the_other = { blacks => 0,
		    whites => 0};
  $sikrit->check_secret( $s, $the_other );
  is_deeply( $one_result, $the_other, "Checking secrets $s->{'_string'}");
}
#Mock play

my @played = qw( ABCA BCAE BBAD BCAD );

my $mm = new Algorithm::MasterMind::Test { options => ''};
my $number_of_rules = 0;
my @matches = qw( 0 1 0 3);
my @distances = qw( 0 0 -4 0 );
for my $p ( @played ) {
  my $matches = $mm->matches( $p );
  is( $matches->{'matches'}, shift @matches, "Matching" );
  my $result = check_combination( $code, $p );
  my $distance = shift @distances;
  is( $mm->distance_taxicab( $p )->[0], $distance, "Distance correct");
  $mm->add_rule( $p, $result );
  $number_of_rules++;
  is( $mm->number_of_rules(), $number_of_rules, "Rule added ".$matches->{'matches'} );
  if ( $p ne $code ) {
    is( $mm->distance_taxicab( $p )->[0] < $distance, 1, "Distance correct");
  }
  $matches = $mm->matches( $p );
  is( $mm->number_of_rules(), $number_of_rules, "Check self"  );
}

done_testing();
