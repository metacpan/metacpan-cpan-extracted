#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place
use Algorithm::MasterMind qw(random_string);
use Algorithm::MasterMind::Secret;

BEGIN {
	use_ok( 'Algorithm::MasterMind::Consistent_Set' );
}

my $size = 128;
my @alphabet = qw( A B C D E F );
my $length = 4;

my @strings;
for (1..$size) {
  push @strings, random_string( \@alphabet, $length);
}

my $c_set = new Algorithm::MasterMind::Consistent_Set( \@strings );
my @sorted = sort @strings;
my @sorted_set = sort $c_set->consistent_strings;
is( $sorted_set[0], $sorted[0], 'Set OK' );
is( $sorted_set[$#sorted_set], $sorted[$#sorted], 'Set OK' );

for my $s (@strings ) {
  ok( $c_set->is_in( $s ), 'Added');
}

$c_set->compute_entropy_score;
my @top_scorers = $c_set->top_scorers('entropy');
is( $top_scorers[0] ne '', 1, "Computing top scores");

$c_set->compute_most_score;
@top_scorers = $c_set->top_scorers('most');
my $one_string = splice( @top_scorers, rand( @top_scorers ), 1);
my $secret = new Algorithm::MasterMind::Secret $one_string; # to ensure non-zero partitions
my $other_string = $top_scorers[ rand( @top_scorers )];
my $result = $secret->check( $other_string ); # Another of the 
$c_set->cull_inconsistent_with( $one_string, $result );

if (@{$c_set->{'_combinations'}} ) { # Check other ctor
  my $rules = [ { combination => $one_string,
		  blacks => $result->{'blacks'},
		  whites => $result->{'whites'}} ];
  my $other_c_set = Algorithm::MasterMind::Consistent_Set->create_consistent_with( \@strings, $rules );
  is_deeply( $other_c_set->{'_combinations'}, $c_set->{'_combinations'}, 'Consistent creation' );
}



my $new_random_string = (  random_string( \@alphabet, $length) );
$c_set->add_combination( $new_random_string );
ok( $c_set->is_in( $new_random_string ), 'Added');

@strings = qw(AAAA BBBB CCCC ABCD);
$c_set = new Algorithm::MasterMind::Consistent_Set( \@strings );
my %partitions = (   
		  'AAAA' =>  { '0b-0w' => 2,
			       '1b-0w' => 1},
		  'ABCD' =>{ '1b-0w' => 3 },
		  'BBBB' => { '0b-0w' => 2,
			      '1b-0w' => 1 },
		  'CCCC' => { '0b-0w' => 2,
			      '1b-0w' => 1 } );
for my $s (@strings) {
  is_deeply($c_set->partitions_for($s), $partitions{$s}, "Partitions for $s" );
}
$c_set->compute_most_score;
is( $c_set->score_most( 'ABCD' ), 1, 'Scoring OK');
is( $c_set->score_most( 'AAAA' ), 2, 'Scoring OK');
@top_scorers = $c_set->top_scorers('most');
is_deeply ( scalar(@top_scorers), 3, 'Top scorers' );
$secret = new Algorithm::MasterMind::Secret 'ABEE';
my $a_move = 'DDDD';
$result = $secret->check( $a_move); # Simulating move
$c_set->cull_inconsistent_with( 'DDDD', $result );
is_deeply($c_set->partitions_for('AAAA'), { '0b-0w' => 2 }, "New partitioning" );
