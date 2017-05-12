use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Permutation - Per-mutation. Got it? 

=head1 SYNOPSIS

  use Algorithm::Evolutionary::Op::Permutation;

  my $op = new Algorithm::Evolutionary::Op::Permutation ; #Create from scratch
  my $bit_chromosome =  new Algorithm::Evolutionary::Individual::BitString 10;
  $op->apply( $bit_chromosome );

  my $priority = 2;
  my $max_iterations = 100; # Less than 10!, absolute maximum number
			    # of permutations
  $op = new Algorithm::Evolutionary::Op::Permutation $priority, $max_iterations;

  my $xmlStr=<<EOC;
  <op name='Permutation' type='unary' rate='2' />
  EOC
  my $ref = XMLin($xmlStr);

  my $op = Algorithm::Evolutionary::Op::->fromXML( $ref );
  print $op->asXML(), "\n*Arity ->", $op->arity(), "\n";

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Class independent permutation operator; any individual that has the
    C<_str> instance variable (like
    L<Algorithm::Evolutionary::Individual::String> and
    L<Algorithm::Evolutionary::Individual::BitString>)  will have some
    of its elements swapped. Each string of length l has l!
    permutations; the C<max_iterations> parameter should not be higher
    than that. 

This kind of operator is used extensively in combinatorial
    optimization problems. See, for instance, 
  @article{prins2004simple,
   title={{A simple and effective evolutionary algorithm for the vehicle routing problem}},
   author={Prins, C.},
   journal={Computers \& Operations Research},
   volume={31},
   number={12},
   pages={1985--2002},
   issn={0305-0548},
   year={2004},
   publisher={Elsevier}
  }

And, of course, L<Algorithm::MasterMind>, where it is used in the
    evolutionary algorithms solutions. 


=cut

package  Algorithm::Evolutionary::Op::Permutation;

use lib qw( ../../.. );

our ($VERSION) = ( '$Revision: 3.7 $ ' =~ /(\d+\.\d+)/ );

use Carp;
use Clone qw(clone);
use List::Util qw(shuffle); 

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 1;

=head1 METHODS

=head2 new( [$rate = 1][, $max_iterations = 10] )

Creates a new permutation operator; see 
    L<Algorithm::Evolutionary::Op::Base> for details common to all
    operators. The chromosome will undergo a random number of at most
    C<$max_iterations>. By default, it equals 10. 

=cut

sub new {
  my $class = shift;
  my $rate = shift || 1;

  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::Permutation', $rate );
  return $self;
}


=head2 create

Creates a new mutation operator with an application priority, which
    defaults to 1.

Called create to distinguish from the classwide ctor, new. It just
makes simpler to create an Operator

=cut

sub create {
  my $class = shift;
  my $rate = shift || 1; 

  my $self =  { rate => $rate,
	        max_iterations => shift || 10 };

  bless $self, $class;
  return $self;
}

=head2 apply( $chromosome )

Applies at most C<max_iterations> permutations to a "Chromosome" that includes the C<_str>
    instance variable. The number of iterations will be random, so
    that applications of the operator on the same individual will
    create diverse offspring. 

=cut

sub apply ($;$) {
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $victim = clone($arg);
  croak "Incorrect type ".(ref $victim) if ! $self->check( $victim );
  my @arr = split("",$victim->{_str});
  my $how_many = 2+rand(@arr -1 ); # min two points
  my @points;
  my @indices = 0..$#arr;
  for (1..$how_many) {
    my $this_point = rand(@indices);
    push @points, $indices[$this_point];
    splice( @indices, $this_point, 1 );
  }
  my @copy_points;
  do {
    @copy_points = shuffle(@points );
  } while ( $copy_points[0] == $points[0] );
  while ( @points ) {
    my $this_point = shift @points;
    my $other_point = shift @copy_points ;
    substr( $victim->{'_str'}, $this_point, 1, $arr[$other_point]);
  }

#   my $p = new Algorithm::Permute( \@arr );
#   my $iterations = 1+rand($self->{'_max_iterations'}-1);
#   for (1..$iterations) {
#     @arr = $p->next;
#   }
#   if ( !@arr) {
#     croak "I broke \@arr $iterations ", $self->{'_max_iterations'}, " ", $victim->{'_str'},  "\n";
#   }
#   if ( join( "", @arr ) eq $arg->{'_str'} ) {
#     # Check for all equal
#     my %letters;
#     map( $letters{$_}=1, @arr );
#     if ( scalar keys %letters  > 1) {
#       $p->reset; # We are looking for anything different, after all
#       do {
# 	@arr = $p->next;
#       } until ( join( "", @arr ) ne $arg->{'_str'} );
# #      print "Vaya tela $iterations ", $self->{'_max_iterations'}, " ", $victim->{'_str'},  "\n";
#  #     print $victim->{'_str'}, "\n";
#     }
#   }
#   if ( !@arr) {
#     croak "Gosh $iterations ", $self->{'_max_iterations'}, " ", $victim->{'_str'},  "\n";
#   }
  return $victim;
}

=head2 SEE ALSO

Uses L<Algorithm::Permute>, which is purported to be the fastest
    permutation library around. Might change it in the future to
    L<Algorithm::Combinatorics>, which is much more comprehensive.

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2013/01/09 07:22:50 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Permutation.pm,v 3.7 2013/01/09 07:22:50 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.7 $

=cut

