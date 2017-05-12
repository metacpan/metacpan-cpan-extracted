package Algorithm::MasterMind::Consistent_Set;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../../Algorithm-Evolutionary/lib/ 
	   ../../Algorithm-Evolutionary/lib/
	   ../../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/g; 

use Algorithm::MasterMind qw(partitions);
use Algorithm::MasterMind::Secret;

sub new {
  my $class = shift;
  my $combinations = shift;
  my @secrets = map ( (new Algorithm::MasterMind::Secret $_), @$combinations );
  my $self = {  _combinations => \@secrets,
		_partitions => {}};
  bless $self, $class;
  $self->{'_partitions'} = compute_partitions( \@secrets );
  $self->{'_score'} = {}; # To store scores when they're available.
  return $self;
}

sub compute_partitions {
  my $secrets_ref = shift;
  my @secrets = @$secrets_ref;
  my %partitions;
  my %hash_results;
  for ( my $i = 0; $i <= $#secrets; $i ++ ) {
    for (my $j = 0; $j <= $#secrets; $j ++ ) {
      next if $i == $j;
      my $result = { blacks => 0,
		     whites => 0 } ;
      if ( $i < $j  ) {
	$secrets[$i]->check_secret ( $secrets[$j], $result );
	$hash_results{$secrets[$i]->{'_string'}}{$secrets[$j] ->{'_string'}} = $result;
      } else {
	$result = $hash_results{$secrets[$j]->{'_string'}}{$secrets[$i] ->{'_string'}} 
      }
      $partitions{$secrets[$i]->{'_string'}}{result_as_string($result)}++;
    }
  }
  return \%partitions
}

sub create_consistent_with {
  my $class = shift;
  my $combinations = shift;
  my $rules = shift;
  my @secrets = map ( (new Algorithm::MasterMind::Secret $_), @$combinations );
  my $self = {  _combinations => [],
		_partitions => {}};
  bless $self, $class;
  my %rule_secrets;
  map( ($rule_secrets{$_->{'combination'}} = new Algorithm::MasterMind::Secret $_->{'combination'}),
       @$rules );
  for my $s (@secrets ) {
    my $matches;
    for my $r (@$rules ) {
      my $this_result = { blacks => 0,
			  whites => 0 };
      $s->check_secret( $rule_secrets{$r->{'combination'}}, $this_result);
      $matches +=  result_as_string( $this_result ) eq result_as_string( $r );
    }
    if ( $matches == @$rules ) {
      push @{$self->{'_combinations'}}, $s
    }
  }
  $self->{'_partitions'} = compute_partitions( $self->{'_combinations'} );
  $self->{'_score'} = {}; # To store scores when they're available.
  return $self;
}

sub is_in {
  my $self = shift;
  my $combination = shift;
  return exists $self->{'_partitions'}{$combination};
}

sub add_combination {
  my $self = shift;
  my $new_combination = shift;
  return if $self->is_in( $new_combination );
  my $new_secret = new Algorithm::MasterMind::Secret $new_combination;
  for (my $i = 0; $i < @{$self->{'_combinations'}}; $i ++ ) {
    my $result = { blacks => 0,
		   whites => 0 };
    $self->{'_combinations'}[$i]->check_secret ( $new_secret, $result );
    $self->{'_partitions'}{$self->{'_combinations'}[$i]->{'_string'}}{result_as_string($result)}++;
    $self->{'_partitions'}{$new_combination}{result_as_string($result)}++;
  }
  push @{$self->{'_combinations'}}, $new_secret;
}

sub result_as_string {
  my $result = shift;
  return $result->{'blacks'}."b-".$result->{'whites'}."w";
}

sub partitions_for {
  my $self = shift;
  my $string = shift;
  return $self->{'_partitions'}->{$string};
}

sub cull_inconsistent_with {
  my $self = shift;
  my $string = shift;
  my $result = shift;

  my $secret = new Algorithm::MasterMind::Secret $string;
  my $result_string = result_as_string( $result );
  my @new_set;
  for my $s (@{$self->{'_combinations'}} ) {
    my $this_result = { blacks => 0,
			whites => 0 };
    $secret->check_secret( $s, $this_result);
#    print "Checking ", $s->string, " result " , result_as_string( $this_result), " with $result_string\n";
    if ( $result_string eq result_as_string($this_result) ) {
#      print "Added\n";
      push @new_set, $s;
    }
  }
  #Compute new partitions
  $self->{'_partitions'} = compute_partitions( \@new_set );
  $self->{'_combinations'} = \@new_set;
  $self->{'_score'} = {};
}

sub compute_most_score {
  my $self = shift;
  $self->{'_score'}->{'_most'} = {};
  for my $s (keys %{$self->{'_partitions'}} ) {
    $self->{'_score'}->{'_most'}->{$s} = keys %{$self->{'_partitions'}->{$s}};
  }
}

sub compute_entropy_score {
  my $self = shift;
  $self->{'_score'}->{'_entropy'} = {};
  for my $s (keys %{$self->{'_partitions'}} ) {
    my $sum;
    map( ($sum += $self->{'_partitions'}->{$s}->{$_}), keys %{$self->{'_partitions'}->{$s}} );
    my $entropy = 0;
    for my $k ( keys %{$self->{'_partitions'}->{$s}} ) {
      my $fraction = $self->{'_partitions'}->{$s}->{$k}/ $sum;
      $entropy -= $fraction * log( $fraction );
    }
    $self->{'_score'}->{'_entropy'}->{$s} = $entropy; 
  }
}
   
sub score_most {
  my $self = shift;
  my $str = shift;
  return $self->{'_score'}->{'_most'}->{ $str };
}

sub score_entropy {
  my $self = shift;
  my $str = shift;
  return $self->{'_score'}->{'_entropy'}->{ $str };
}

sub top_scorers {
  my $self = shift;
  my $score = "_".shift; # No checks
  my @keys = keys %{$self->{'_partitions'}};
  my @top_scorers;
  if ( $#keys > 1 ) {
    my $top_score = 0;
    for my $s ( @keys  ) {
      my $this_score = $self->{'_score'}->{$score}->{ $s } ;
      if ( $this_score > $top_score ) {
	$top_score = $this_score;
      }
    } 
    for my $s ( @keys  ) {
      if ( $self->{'_score'}{$score}->{ $s }  == $top_score ) {
	push @top_scorers, $s;
      }
    }
  } else { # either 0 or 1
    @top_scorers = @keys;
  } 
  return @top_scorers;
}

sub consistent_strings {
  return keys %{shift->{'_partitions'}};
}   

"As Jack the Ripper said..."; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Consistent_Set - Class for handling the set of consistent combinations


=head1 SYNOPSIS

    use Algorithm::MasterMind::Consistent_Set;

  
=head1 DESCRIPTION

The consistent set in Mastermind contains the set of strings that
could possibly be a solution, that is, those that meet all partitions
made so far. 

=head1 INTERFACE 

=head2 new( @string_array )

Creates set and associated data structures

=head2 compute_partitions ( \@secrets ) 

Computes partitions for an array of secrets, returns a hashref to the
partition set.

=head2 is_in ( $string )

Checks whether the combination is in the consistent set already

=head2 add_combination ( $string )

Adds another combination checking it against previous combinations

=head2 result_to_string ( $result )

Converts result hash into string in a more or less standard way, to
avoid conversion errors

=head2 partitions_for ( $string )

Returns the partition hash for combination $string

=head2 cull_inconsistent_with ( $string, $result )

After a move, eliminates inconsistent elements, recomputing the partitions.

=head2 compute_entropy_score

Computes the entropy score of existent partitions

=head2 compute_most_score

Computes the Most Parts score of existent partitions, that is, the number of non-zero parts

=head2 consistent_strings

Returns the consistent set

=head2 create_consistent_with( $combinations, $rules )

Creates a consistent eliminating from the set of combinations those
not consistent with the rules

=head2 result_as_string

Returns the response as a fixed format string, for comparisons

=head2 score_entropy ($string)

Returns the Entropy score of the C<$string>, if it's in the consistent
set. 

=head2 score_most ($string)

Returns the Most Parts score of the C<$string>, if it's in the consistent
set. 

=head2 top_scorers ( $mode )

Returns the set of top scorers for a particular mode. Now $mode can be
"most" or "entropy"

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009-2012 JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

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
