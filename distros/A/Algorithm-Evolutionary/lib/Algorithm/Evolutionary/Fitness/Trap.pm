use strict; # -*- cperl -*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Fitness::Trap - 'Trap' fitness function for evolutionary algorithms

=head1 SYNOPSIS

    my $number_of_bits = 5;
    my $a = $number_of_bits -1; # Usual default values follow
    my $b = $number_of_bits;
    my $z = $number_of_bits -1;
    my $trap = Algorithm::Evolutionary::Fitness::Trap->new( $number_of_bits, $a, $b, $z );

=head1 DESCRIPTION

Trap function act as "yucky" or deceptive for evolutionary algorithms;
they "trap" population into going to easier, but local, optima.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::Trap;

our $VERSION = '3.2';

use String::Random;
use Carp qw(croak);

use lib qw(../../.. ../.. ..);

use base qw(Algorithm::Evolutionary::Fitness::String);
use Algorithm::Evolutionary::Utils qw(hamming);

=head2 new( $number_of_bits, [$a = $number_of_bits -1, $b = $number_of_bits, $z=$number_of_bits-1])

Creates a new instance of the problem, with the said number of bits
and traps. Uses default values from C<$number_of_bits> if needed

=cut 

sub new {
  my $class = shift;
  my $number_of_bits = shift || croak "Need non-null number of bits\n";
  my $a = shift || $number_of_bits - 1;
  my $b = shift || $number_of_bits;
  my $z = shift || $number_of_bits - 1;

  croak "Z too big" if $z >= $number_of_bits;
  croak "Z too small" if $z < 1;
  croak "A must be less than B" if $a > $b;
  my $self = $class->SUPER::new();
  bless $self, $class;
  $self->initialize();
  $self->{'l'} = $number_of_bits;
  $self->{'a'} = $a;
  $self->{'b'} = $b;
  $self->{'z'} = $z;
  return $self;
}

=head2 _really_apply

Applies the instantiated problem to a chromosome

=cut

sub _really_apply {
  my $self = shift;
  return $self->trap( @_ );
}

=head2 trap( $string )

Computes the value of the trap function on the C<$string>. Optimum is
number_of_blocs * $b (by default, $b = $l or number of ones) 

=cut

sub trap {
    my $self = shift;
    my $string = shift;
    my $cache = $self->{'_cache'};
    if ( $cache->{$string} ) {
	return $cache->{$string};
    }
    my $l = $self->{'l'};
    my $z = $self->{'z'};
    my $total = 0;
    for ( my $i = 0; $i < length( $string); $i+= $l ) {
      my $substr = substr( $string, $i, $l );
      my $key = $substr;
      if ( !$cache->{$substr} ) {
	my $num_ones = 0;
	while ( $substr ) {
	  $num_ones += chop( $substr );
	}
	if ( $num_ones <= $z ) {
	  $cache->{$key} = $self->{'a'}*($z-$num_ones)/$z;
	} else {
	  $cache->{$key} = $self->{'b'}*($num_ones -$z)/($l-$z);
	}
      }
      $total += $cache->{$key};
    }
    $cache->{$string} = $total;
    return $cache->{$string};

}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"Gotcha trapped!";

