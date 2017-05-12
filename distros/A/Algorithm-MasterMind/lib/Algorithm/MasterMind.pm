package Algorithm::MasterMind;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv("v0.4.5");  #Quest for non-failing tests

use Algorithm::Combinatorics qw(variations_with_repetition);

#use Memoize;
#memoize( "check_rule" );

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( check_combination partitions entropy random_string 
		     response_as_string);

use lib qw( ../../lib ../lib ../../../lib );

# Module implementation here

sub new {

  my $class = shift;
  my $options = shift || croak "Need options here in Algorithm::MasterMind::New\n";

  my $self =  { _rules => [],
		_evaluated => 0,
		_hash_rules => {} };

  bless $self, $class;
  $self->initialize( $options );
  return $self;
}

sub random_combination {
  my $self = shift;
  return random_string( $self->{'_alphabet'}, $self->{'_length'});
}

sub random_string {
  my $alphabet = shift;
  my $length = shift;
  my $string;
  my @alphabet = @{$alphabet};
  for (my $i = 0; $i <  $length; $i++ ) {
    $string .= $alphabet[ rand( @alphabet) ];
  }
  return $string;
}

sub issue_first { #Default implementation
  my $self = shift;
  return $self->{'_last'} = $self->random_combination;
}

sub start_from {
  my $class = shift;
  my $options = shift || croak "Options needed to start!";

  my $self = {};
  bless $self, $class;
  for my $o ( qw( consistent alphabet rules evaluated ) ) {
    $self->{"_$o"} = $options->{$o};
  }
  return $self;
}

sub issue_first_Knuth {
  my $self = shift;
  my $string;
  my @alphabet = @{ $self->{'_alphabet'}};
  my $half = @alphabet/2;
  for ( my $i = 0; $i < $self->{'_length'}; $i ++ ) {
    $string .= $alphabet[ $i % $half ]; # Recommendation Knuth
  }
  $self->{'_first'} = 1; # Flag to know when the second is due
  return $self->{'_last_string'} = $string;
}

sub issue_next {
  croak "To be reimplemented in derived classes";
}

sub add_rule {
  my $self = shift;
  my ($combination, $result) = @_;
  my %new_rule = %$result;
  $new_rule{'combination'} = $combination;
  push @{ $self->{'_rules'} }, \%new_rule;

}

sub feedback {
  my $self = shift;
  my ($result) = @_;
  $self->add_rule( $self->{'_last'}, $result );
}

sub number_of_rules {
  my $self= shift;
  return scalar @{ $self->{'_rules'}};
}

sub rules {
  my $self= shift;
  return   $self->{'_rules'};
}

sub evaluated {
  my $self=shift;
  return $self->{'_evaluated'};
}

sub matches {

  my $self = shift;
  my $string = shift || croak "No string\n";
  my @rules = @{$self->{'_rules'}};
  my $result = { matches => 0,
		 result => [] };
#  print "Checking $string, ", $self->{'_evaluated'}, "\n";
  for my $r ( @rules ) {    
    my $rule_result = $self->check_rule( $r, $string );
    $result->{'matches'}++ if ( $rule_result->{'match'} );
    push @{ $result->{'result'} }, $rule_result;
  }
  $self->{'_evaluated'}++;
  return $result;
}

sub check_rule {
  my $self = shift;
  my $rule = shift;
  my $string = shift;
  if ( ! $self->{'_rules_hash'}->{ $rule->{'combination'} }{ $string } ) {
    my $result = check_combination( $rule->{'combination'}, $string );
    if ( ( $rule->{'blacks'} == $result->{'blacks'} )
	 && ( $rule->{'whites'} == $result->{'whites'} ) ) {
      $result->{'match'} = 1;
    } else {
      $result->{'match'} = 0;
    }
    $self->{'_rules_hash'}->{ $rule->{'combination'} }{ $string } = $result;
  } 
  return $self->{'_rules_hash'}->{ $rule->{'combination'} }{ $string };
}

sub check_combination {
  my $combination = shift;
  my $string = shift;

  my ( %hash_combination, %hash_string );
  my $blacks = 0;
  my ($c, $s);
  while ( $c = chop( $combination ) ) {
    $s = chop( $string );
    if ( $c eq $s ) {
      $blacks++;
    } else {
      $hash_combination{ $c }++;
      $hash_string{ $s }++;
    }
  }
  my $whites = 0;
  for my $k ( keys %hash_combination ) {
    next if ! defined $hash_string{$k};
    $whites += ($hash_combination{$k} > $hash_string{$k})
      ?$hash_string{$k}
	:$hash_combination{$k};
  }
  return { blacks => $blacks,
	   whites => $whites };
}

sub distance_taxicab {
  my $self = shift;
  my $combination = shift || croak "Can't compute distance to nothing";
  my $matches = $self->matches( $combination );

  my $distance = 0;
  my @rules = @{$self->{'_rules'}};
  for ( my $r = 0; $r <= $#rules; $r++) {
    $distance -= abs( $rules[$r]->{'blacks'} - $matches->{'result'}->[$r]->{'blacks'} ) +
      abs( $rules[$r]->{'whites'} - $matches->{'result'}->[$r]->{'whites'} );
  }

  return [$distance, $matches->{'matches'}];
}

sub distance_chebyshev {
  my $self = shift;
  my $combination = shift || croak "Can't compute distance to nothing";
  my $rules =  $self->number_of_rules();
  my $matches = $self->matches( $combination );

  my $distance = 0;
  my @rules = @{$self->{'_rules'}};
  for ( my $r = 0; $r <= $#rules; $r++) {
    my $diff_black = abs( $rules[$r]->{'blacks'} - $matches->{'result'}->[$r]->{'blacks'});
    my $diff_white = abs( $rules[$r]->{'whites'} - $matches->{'result'}->[$r]->{'whites'} );
    my $this_distance = ($diff_black > $diff_white)?$diff_black:$diff_white;
    $distance -= $this_distance ;
  }

  return [$distance, $matches->{'matches'}];
}

sub check_combination_old {
  my $combination = shift;
  my $string = shift;

  my @combination_arr = split(//, $combination );
  my @string_arr = split(//, $string);
  my $blacks = 0;
  for ( my $i = 0; $i < length($combination); $i ++ ) {
    if ( $combination_arr[ $i ] eq $string_arr[ $i ] ) {
      $combination_arr[ $i ] = $string_arr[ $i ] = 0;
      $blacks++;
    }
  }
  my %hash_combination;
  map( $hash_combination{$_}++, @combination_arr);
  my %hash_string;
  map( $hash_string{$_}++, @string_arr);
  my $whites = 0;
  for my $k ( keys %hash_combination ) {
    next if $k eq '0'; # Mark for "already computed"
    next if ! defined $hash_string{$k};
    $whites += ($hash_combination{$k} > $hash_string{$k})
      ?$hash_string{$k}
	:$hash_combination{$k};
  }
  return { blacks => $blacks,
	   whites => $whites };
}

sub hashify {
  my $str = shift;
  my %hash;
  map( $hash{$_}++, split(//, $str));
  return %hash;
}

sub not_in_combination {
  my $self = shift;
  my $combination = shift;
  my @alphabet = @{$self->{'_alphabet'}};
  my %alphabet_hash;
  map( $alphabet_hash{$_}=1, @alphabet );
  for my $l ( split(//, $combination ) ) {
    delete $alphabet_hash{$l} if  $alphabet_hash{$l};
  }
  return keys %alphabet_hash;
}

sub partitions {
  my @combinations = sort @_;

  my %partitions;
  my %hash_results;
  for my $c ( @combinations ) {
    for my $cc ( @combinations ) {
      next if $c eq $cc;
      my $result;
      if ( $c lt $cc ) {
	$result = check_combination ( $c, $cc );
	$hash_results{$c}{$cc} = $result;
      } else {
	$result = $hash_results{$cc}{$c};
      }
      $partitions{$c}{$result->{'blacks'}."b-".$result->{'whites'}."w"}++;
    }
    
  }
  return \%partitions;
}

sub all_combinations {
  my $self = shift; 
  my @combinations_array = variations_with_repetition( $self->{'_alphabet'}, 
						       $self->{'_length'});
  my @combinations = map( join( "", @$_), @combinations_array );
  
}

sub all_responses {
    my $self = shift;
    my $length = $self->{'_length'};
    my @responses_array = variations_with_repetition( ['B', 'W', '-'], 
						      $length );
    my %responses;
    for my $r ( @responses_array ) {
      my %partial = ( W => 0,
		      B => 0 );
      for my $c (@$r) {
	$partial{$c}++;
      }
      
      $responses{$partial{'B'}."B-".$partial{'W'}."W"} = 1;
    }
    # Delete impossible
    my $impossible = ($length-1)."B-1W";
    delete $responses{$impossible};
    my @possible_responses = sort keys %responses;
    return @possible_responses;

}

sub entropy {
  my $combination = shift;
  my %freqs;
  map( $freqs{$_}++, split( //, $combination));
  my $entropy;
  for my $k (keys %freqs ) {
    my $probability = $freqs{$k}/length($combination);
    $entropy -= $probability * log ($probability);
  }
  return $entropy;
}

sub response_as_string {
  return $_[0]->{'blacks'}."b-".$_[0]->{'whites'}."w";
}
  

"4 blacks, 0 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind - Framework for algorithms that solve the MasterMind game

=head1 VERSION

This document describes Algorithm::MasterMind version 0.4.1 


=head1 SYNOPSIS

    use Algorithm::MasterMind;
    use Algorithm::MasterMind::Solver; # Change "solver" to your own.

    my $solver = new Algorithm::MasterMind::Solver $options; 

    my $first_string = $solver->issue_first();
    $solver->feedback( check_combination( $secret_code, $first_string) );

    my $played_string = $solver->issue_next;
    $solver->feedback( check_combination( $secret_code, $played_string) );

    #And so on until solution is found
  
=head1 DESCRIPTION

Includes common functions used in Mastermind solvers; it should not be
used directly, but from derived classes. See examples in
L<Algorithm::MasterMind::Random>, for instance.

=head1 INTERFACE 

=head2 new ( $options )

Normally to be called from derived classes

=head2 add_rule( $combination, $result)

Adds a rule (set of combination and its result as a hash) to the set
of rules. These rules represent the information we've got on the
secret code. 

=head2 check_combination( $secret_code, $combination )

Checks a combination against the secret code, returning a hashref with
the number of blacks (correct in position) and whites (correct in
color, not position)

=head2 distance( $object )

Computes distance to a consistent combination, computed as the number
of blacks and whites that need change to become a consistent
combination. 


=head2 check_combination_old ( $secret_code,
$combination )

Old way of checking combinations, eliminated after profiling

=head2 check_rule ($rule, $combination) 

Same as C<check_combination>, except that a rule contains a
combination and how it scored against the secret code

=head2 issue_first ()

Issues the first combination, which might be generated in a particular
way 

=head2 start_from ()

Used when you want to create an solver once it's been partially
solved; it contains partial solutions. 

=head2 issue_first_Knuth

First combination looking like AABC for the normal
mastermind. Proposed by Knuth in one of his original papers. 

=head2 issue_next()

Issues the next combination

=head2 feedback()

Obtain the result to the last combination played

=head2 guesses()

Total number of guesses

=head2 evaluated()

Total number of combinations checked to issue result

=head2 number_of_rules ()

Returns the number of rules in the algorithm

=head2 rules()

Returns the rules (combinations, blacks, whites played so far) as a
reference to array

=head2 matches( $string ) 

Returns a hash with the number of matches, and whether it matches
every rule with the number of blacks and whites it obtains with each
of them

=head2 hashify ( $string )

Turns a string into a hash, to help with comparisons. Used internally,
mainly.

=head2 not_in_combination( $string)

Returns the letters from the alphabet that are _not_ in this
combination. Might be useful for certain strategies.

=head2 random_combination

Combines randomly the alphabet, issuing, you guessed it, a random
combination. 

=head2 partitions

From a set of combinations, returns the "partitions", that is, the
number of combinations that would return every set of black and white
response. Inputs an array, returns a hash keyed to the combination,
each key containing a value corresponding to the number of elements in
each partition.

=head2 all_combinations

Returns all possible combinations of the current alphabet and length
in an array. Be careful with that, it could very easily fill up your
memory, depending on length and alphabet size.

=head2 entropy( $string )

Computes the string entropy

=head2 distance_taxicab( $string )

Computes the sums of taxicab distances to all combinations in the
game, and returns it as [$distance, $matches]

=head2 distance_chebyshev( $string )

Computes the Chebyshev distance, that is, the max of distances in all
dimensions. Returns as a arrayref with [$distance, matches]

=head2 all_responses()

Returns all possible responses (combination of black and white pegs)
for the combination length

=head2 random_string

Returns a random string in with the length and alphabet defined

=head2 response_as_string ( $response )

From a hash that uses keys C<blacks> and C<whites>, returns a string
"xb-yw" in a standard format that can be used for comparing.

=head1 CONFIGURATION AND ENVIRONMENT

Algorithm::MasterMind requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Algorithm::Evolutionary>, but only for one of the
strategies. L<Algorithm::Combinatorics>, used to generate combinations
and for exhaustive search strategies. 


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-algorithm-mastermind@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

Other modules in CPAN which you might find more useful than this one
are at L<Games::Mastermind::Solver>, which I didn't use and extend for
no reason, although I should have. Also L<Games::Mastermind::Cracker>. 

Formerly, you could try and play this game at
http://geneura.ugr.es/~jmerelo/GenMM/mm-eda.cgi, restricted to 4 pegs
and 6 colors. It's, for the time being, under reparations. The program C<mm-eda.cgi> should also be available in 
the C<apps> directory of this distribution.

The development of this projects is hosted at sourceforge,
https://sourceforge.net/projects/opeal/develop, check it out for the
latest bleeding edge release. In fact, right now this module is at
least a year away from the latest development. 

If you use any of these modules for your own research, we would very
grateful if you would reference the papers that describe this, such as
this one:

 @article{merelo2010finding,
  title={{Finding Better Solutions to the Mastermind Puzzle Using Evolutionary Algorithms}},
  author={Merelo-Guerv{\'o}s, J. and Runarsson, T.},
  journal={Applications of Evolutionary Computation},
  pages={121--130},
  year={2010},
  publisher={Springer}
 }

or


 @inproceedings{DBLP:conf/cec/GuervosMC11,
  author    = {Juan-J. Merelo-Guerv{\'o}s and
               Antonio-Miguel Mora and
               Carlos Cotta},
  title     = {Optimizing worst-case scenario in evolutionary solutions
               to the {MasterMind} puzzle},
  booktitle = {IEEE Congress on Evolutionary Computation},
  year      = {2011},
  pages     = {2669-2676},
  ee        = {http://dx.doi.org/10.1109/CEC.2011.5949952},
  crossref  = {DBLP:conf/cec/2011},
  bibsource = {DBLP, http://dblp.uni-trier.de}
 }

 @proceedings{DBLP:conf/cec/2011,
  title     = {Proceedings of the IEEE Congress on Evolutionary Computation,
               CEC 2011, New Orleans, LA, USA, 5-8 June, 2011},
  booktitle = {IEEE Congress on Evolutionary Computation},
  publisher = {IEEE},
  year      = {2011},
  isbn      = {978-1-4244-7834-7},
  ee        = {http://ieeexplore.ieee.org/xpl/mostRecentIssue.jsp?punumber=5936494},
  bibsource = {DBLP, http://dblp.uni-trier.de}
 }

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
