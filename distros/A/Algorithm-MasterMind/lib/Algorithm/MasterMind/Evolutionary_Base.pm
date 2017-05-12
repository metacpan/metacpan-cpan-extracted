package Algorithm::MasterMind::Evolutionary_Base;

use warnings;
use strict;
use Carp;

use lib qw(../../lib 
	   ../../../lib
	   ../../../../Algorithm-Evolutionary/lib/ 
	   ../../../Algorithm-Evolutionary/lib/ 
	   ../../Algorithm-Evolutionary/lib/
	   ../Algorithm-Evolutionary/lib/);

our $VERSION = sprintf "%d.%03d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind';

use Algorithm::MasterMind qw(entropy);

use Algorithm::Evolutionary::Individual::String;

# ---------------------------------------------------------------------------

sub fitness_compress {
  my $self = shift;
  my $object = shift;
  my $combination = $object->{'_str'};
  my $matches = $self->matches( $combination );
  $object->{'_matches'} = $matches->{'matches'};
  my $fitness = 1;
  my @rules = @{$self->{'_rules'}};
  my $rules_string = $combination;
  for ( my $r = 0; $r <= $#rules; $r++) {
    $rules_string .= $rules[$r]->{'combination'};
    $fitness += abs( $rules[$r]->{'blacks'} 
		     - $matches->{'result'}->[$r]->{'blacks'} ) 
      + abs( $rules[$r]->{'whites'} - $matches->{'result'}->[$r]->{'whites'} );
  }
  
  return entropy($rules_string)/$fitness;
}

sub fitness_orig {
  my $self = shift;
  my $object = shift;
  my $combination = $object->{'_str'};
  my $matches = $self->matches( $combination );
  $object->{'_matches'} = $matches->{'matches'};

  my $fitness = 1;
  my @rules = @{$self->{'_rules'}};
  for ( my $r = 0; $r <= $#rules; $r++) {
    $fitness += abs( $rules[$r]->{'blacks'} - $matches->{'result'}->[$r]->{'blacks'} ) +
      abs( $rules[$r]->{'whites'} - $matches->{'result'}->[$r]->{'whites'} );
  }
  return 1/$fitness;
}

sub issue_first {
  my $self = shift;
  #Initialize population for next step
  $self->reset();
  $self->{'_first'} = 1; # flag for first
  return $self->{'_last'} = $self->issue_first_Knuth();
}

sub reset {
  my $self=shift;
  my %pop;
  if (  scalar( (@{$self->{'_alphabet'}})** $self->{'_length'} ) < $self->{'_pop_size'} ) {
      croak( "Can't do, population bigger than space" );
  }
  while ( scalar ( keys %pop ) < $self->{'_pop_size'} ) {
      my $indi = Algorithm::Evolutionary::Individual::String->new( $self->{'_alphabet'}, $self->{'_length'} );
      $pop{ $indi->{'_str'}} = $indi;
  }
  my @pop = values %pop;
  $self->{'_pop'}= \@pop;
}

sub reset_old {
  my $self=shift;
  my @pop;
  for ( 0.. ($self->{'_pop_size'}-1) ) {
    my $indi = Algorithm::Evolutionary::Individual::String->new( $self->{'_alphabet'}, 
								 $self->{'_length'} );
    push( @pop, $indi );
  }
  $self->{'_pop'}= \@pop;
}

sub realphabet {
    my $self = shift;
    my $alphabet = $self->{'_alphabet'};
    my $pop = $self->{'_pop'};
     
    my %alphabet_hash;
    map ( $alphabet_hash{$_} = 1, @$alphabet );

    for my $p ( @$pop ) {
	for ( my $i = 0; $i < length( $p->{'_str'} ); $i++ ) {
	    if ( !$alphabet_hash{substr($p->{'_str'},$i,1)} ) {
		substr($p->{'_str'},$i,1, $alphabet->[rand( @$alphabet )]);
	    }
	}
	$p->{'_chars'} = $alphabet;
    }
}

sub shrink_to {
  my $self = shift;
  my $new_size = shift || croak "Need a new size" ;

  do  {
    splice( @{$self->{'_pop'}}, rand( @{$self->{'_pop'}} ), 1 )
  } until (@{$self->{'_pop'}} < $new_size );
}

# sub distance {
#     my $self = shift;
#     my $evo_comb = shift || croak "Need somebody to love\n"; 

#     my @rules = @{$self->{'_rules'}};
#     my $matches = 0;
#     my $distance = 0;
# #  print "Checking $string, ", $self->{'_evaluated'}, "\n";
#     my $string = $evo_comb->{'_str'};
#     for my $r ( @rules ) {    
# 	my $rule_result; 
# 	if ( !$evo_comb->{'_results'}->{$r->{'combination'}} ) {
# 	    $rule_result = check_rule( $r, $string );
# 	    $evo_comb->{'_results'}->{$r->{'combination'}} = $rule_result;
# 	} else {
# 	    $rule_result = $evo_comb->{'_results'}->{$r->{'combination'}};
# 	}
# 	$matches++ if ( $rule_result->{'match'} );
# 	$distance -= abs( $r->{'blacks'} - $rule_result->{'blacks'} ) +
# 	    abs( $r->{'whites'} - $rule_result->{'whites'} );
#     }

#     return [$distance, $matches];
    
# }
"some blacks, 0 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Evolutionary_Base - Base class for evolutionary-based algorithms


=head1 SYNOPSIS

    use base 'Algorithm::MasterMind::Evolutionary::Evolutionary_Base';

  
=head1 DESCRIPTION

Base class with some default functions for evolutionary algorithm
based classes. 

=head1 INTERFACE 

=head2 fitness_compress()

Returns the  fitness for each combination, which combines
entropy and the distance to a consistent combination.

=head2 fitness_orig()

Original fitness, used in one of the former papers

=head2 reset_old()

Create a new population, old version

=head2 reset()

Create a new population making sure that all strings appear only once. 

=head2 realphabet()

Convert the whole population to a new alphabet, changing no-existent
letters to random letters in the new alphabet. 

=head2 shrink_to( $new_size )

Reduce population size (in case a partial solution has been found).


=head2 issue_first ()

Issues the first combination, which might be generated in a particular
way; in this case Knuth's way. Might be used as a default. 

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
