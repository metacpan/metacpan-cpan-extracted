package Algorithm::MasterMind::Partition_Worst;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind';

use Algorithm::MasterMind qw( partitions );

sub initialize {
  my $self = shift;
  my $options = shift;
  for my $o ( keys %$options ) {
    $self->{"_$o"} = $options->{$o};
  }
  $self->{'_partitions'} = {};
}

sub issue_first {
  my $self = shift;
  my @combinations = $self->all_combinations();
  $self->{'_consistent'} = \@combinations;
  return $self->{'_last'} = $self->issue_first_Knuth();

}

sub issue_next {
  my $self = shift;
  my $rules =  $self->number_of_rules();

  # Check consistency
  for ( my $i = 0; $i <= $#{$self->{'_consistent'}}; $i++ ) {
     my $match = $self->matches($self->{'_consistent'}->[$i]);
     $self->{'_evaluated'}++;
     if ( $match->{'matches'} < $rules ) {
       delete $self->{'_consistent'}->[$i];
     }
  }

  #Eliminate null
  @{$self->{'_consistent'}} = grep( $_, @{$self->{'_consistent'}} );

  if ( @{$self->{'_consistent'}}  > 1 ) {
    # Compute partitions
    my $partitions  = partitions( @{$self->{'_consistent'}} );
    
    # Obtain best
    my %min_c;
    my $min_max = keys %$partitions ;
    for my $c ( keys %$partitions ) {
      my $this_max = 0;
      for my $p ( keys %{$partitions->{$c}} ) {
	if ( $partitions->{$c}{$p} > $this_max ) {
	  $this_max = $partitions->{$c}{$p};
	}
      }
      $min_c{ $c } = $this_max;
      if ( $this_max < $min_max ) {
	$min_max = $this_max;
      }
    }
    
    # Find all partitions with that max
    my @minimal_c = grep( $min_c{$_} == $min_max, keys %min_c );
    
    # Break ties
    my $string = $minimal_c[ rand( @minimal_c )];
    # Obtain next
    if ( $string eq '' ) {
      warn "Something is wrong\n";
    }
    return  $self->{'_last'} = $string;
  } else {
    return  $self->{'_last'} = $self->{'_consistent'}->[0];
  }
}

"some blacks, 0 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Partition_Worst - Plays by Knuth's playbook


=head1 SYNOPSIS

    use Algorithm::MasterMind::Partition_Worst;
    my $secret_code = 'EAFC';
    my @alphabet = qw( A B C D E F );
    my $solver = new Algorithm::MasterMind::Partition_Worst { alphabet => \@alphabet,
						   length => length( $secret_code ) };

  
=head1 DESCRIPTION

Solves the algorithm by issuing each time a combination that minimizes
the size of the worst partition. This intends to maximally reduce the
search space each time; it was the first algorithm used to play
mastermind, but it's no longer state of the art, and does not work
very well for spaces higher than 4-6. In fact, it will probably take a
lot of time (and use a lot of memory) for 5-9 already, so use it
carefully. 

=head1 INTERFACE 

=head2 initialize()

Called from C<new>, initializes data structures.

=head2 issue_first ()

Issues it in the Knuth way, AABC. This should probably be computed
from scratch (to be coherent with the algorithm), but it's already
    published, so what the hell. 

=head2 issue_next()

Issues the next combination

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>, and obviously, Donald Knuth as
    author of the algorithm.


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
