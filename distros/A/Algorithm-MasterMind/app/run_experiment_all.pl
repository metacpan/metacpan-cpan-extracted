#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib ../../Algorithm-Evolutionary/lib);

use YAML qw(LoadFile);
use IO::YAML;
use DateTime;
use Algorithm::Combinatorics qw(variations_with_repetition);

use Algorithm::MasterMind qw( check_combination );

my $config_file = shift || die "Usage: $0 <configfile.yaml>\n";

$config_file .= ".yaml" if ! ($config_file =~ /\.ya?ml$/);

my $conf = LoadFile($config_file) || die "Can't open $config_file: $@\n";

my $method = $conf->{'Method'};
eval "require Algorithm::MasterMind::$method" || die "Can't load $method: $@\n";

my $io = IO::YAML->new($conf->{'ID'}."-$method-".DateTime->now().".yaml", ">");

my $method_options = $conf->{'Method_options'};
$io->print( $method, $method_options );

my $engine = variations_with_repetition($method_options->{'alphabet'}, 
					$method_options->{'length'});

my $combination;
my $repeats = $conf->{'repeats'} || 10;
while ( $combination = $engine->next() ) {
  my $secret_code = join("",@$combination);
  for ( 1..$repeats ) {
    print "Code $secret_code\n";
    my $solver;
    eval "\$solver = new Algorithm::MasterMind::$method \$method_options";
    die "Can't instantiate $solver: $@\n" if !$solver;
    my $game = { code => $secret_code,
		 combinations => []};
    my $move = $solver->issue_first;
    my $response =  check_combination( $secret_code, $move);
    push @{$game->{'combinations'}}, [$move,$response] ;
    
    while ( $move ne $secret_code ) {
      $solver->feedback( $response );
      $move = $solver->issue_next;
      print "Playing $move\n";
      $response = check_combination( $secret_code, $move);
      push @{$game->{'combinations'}}, [$move, $response] ;
      $solver->feedback( $response );
      if ( $solver->{'_consistent'} ) {
	push @{$game->{'consistent_set'}}, [ keys %{$solver->{'_consistent'}} ] ;
      }  else {
	my $partitions = $solver->{'_partitions'};
	push @{$game->{'consistent_set'}}, 
	  [ map( $_->{'_string'}, @{$partitions->{'_combinations'}}) ];
	if ( $partitions->{'_score'}->{'_most'} ) {
	  push @{$game->{'top_scorers'}}, [ $partitions->top_scorers('most') ];
	} elsif ( $partitions->{'_score'}->{'_entropy'} ) {
	  push @{$game->{'top_scorers'}}, [ $partitions->top_scorers('entropy') ];
	}
      }
      if ( $solver->{'_data'} ) {
	push @{$game->{'data'}}, $solver->{'_data'};
      }
    }

    $game->{'evaluations'} = $solver->evaluated();
    $io->print($game);
    print "Finished\n";
  }
}
$io->close;
