package Algorithm::MasterMind::Canonical_GA;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../../Algorithm-Evolutionary/lib/ 
	   ../../../lib
	   ../../Algorithm-Evolutionary/lib/);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind::Evolutionary_Base';

use Algorithm::Evolutionary::Op::String_Mutation; 
use Algorithm::Evolutionary::Op::QuadXOver;
use Algorithm::Evolutionary::Op::CanonicalGA;
use Algorithm::Evolutionary::Individual::String;

# ---------------------------------------------------------------------------


sub initialize {
  my $self = shift;
  my $options = shift;
  for my $o ( keys %$options ) {
    $self->{"_$o"} = $options->{$o};
  }

  # Variation operators
  my $m = new Algorithm::Evolutionary::Op::String_Mutation; # Rate = 1
  my $c = Algorithm::Evolutionary::Op::QuadXOver->new( 1,2 ); 

  my $fitness = sub { $self->fitness_orig(@_) };
  my $ga = new Algorithm::Evolutionary::Op::CanonicalGA( $fitness, 
							 $options->{'replacement_rate'},
							 [ $m, $c] );
  $self->{'_fitness'} = $fitness;
  $self->{'_ga'} = $ga;

}


sub issue_next {
  my $self = shift;
  my $rules =  $self->number_of_rules();
  my @alphabet = @{$self->{'_alphabet'}};
  my $length = $self->{'_length'};
  my $pop = $self->{'_pop'};
  my $ga = $self->{'_ga'};
  map( $_->evaluate( $self->{'_fitness'}), @$pop );
  my @ranked_pop = sort { $b->{_fitness} <=> $a->{_fitness}; } @$pop;

  if ( $ranked_pop[0]->{'_matches'} == $rules ) { #Already found!
    return  $self->{'_last'} = $ranked_pop[0]->{'_str'};
  } else {
    my @pop_by_matches;
    my $best;
    do {
      $ga->apply( $pop );
      print "Población ", scalar @$pop, "\n";
      map( $_->{'_matches'} = $_->{'_matches'}?$_->{'_matches'}:-1, @$pop ); #To avoid warnings
      @pop_by_matches = sort { $b->{'_matches'} <=> $a->{'_matches'} } @$pop;
      $best = $pop_by_matches[0];
    } while ( $best->{'_matches'} < $rules );
    return  $self->{'_last'} = $best->{'_str'};
  }

}

"some blacks, 0 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Canonical_GA - Tries to compute new solution from last


=head1 SYNOPSIS

    use Algorithm::MasterMind::Canonical_GA;

  
=head1 DESCRIPTION

Mainly used in test functions, and as a way of instantiating base
class. 


=head1 INTERFACE 

=head2 fitness()

Returns the vectorial fitness for each combination, which combines
entropy and the distance to a consistent combination.

=head2 initialize()

Does nothing, really

=head2 new ( $options )

This function, and all the rest, are directly inherited from base

=head2 issue_first ()

Issues the first combination, which might be generated in a particular
way 

=head2 issue_next()

Issues the next combination

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
