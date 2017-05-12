use strict; # -*- cperl -*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Fitness::ZDT1 - Zitzler-Deb-Thiele #1 Multiobjective test function

=head1 SYNOPSIS

    my $number_of_bits = 5;
    my $z = Algorithm::Evolutionary::Fitness::ZDT1->new( $number_of_bits);
    my $string = "10101"x30;
    $z->zdt1( $string);
    #Previously created binary chromosome with 5x30 bits
    $z->apply( $chromosome );

=head1 DESCRIPTION

Implementation of the first ZDT test function, found at "Comparison of Multiobjective Evolutionary
Algorithms: Empirical Results" by Zitzler, Deb and Thiele


=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::ZDT1;

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/g; 

use Carp qw(croak);

use lib qw(../../.. ../.. ..);

use base qw(Algorithm::Evolutionary::Fitness::String);
use Algorithm::Evolutionary::Utils qw(decode_string);

use constant { M => 30,
               NINE => 9 };

=head2 new

Creates a new instance of the problem, with the said number of bits and peaks

=cut 

sub new {
  my $class = shift;
  my $number_of_bits = shift || croak "Need non-null number of bits\n";
  my $self = { '_number_of_bits'  => $number_of_bits };
  bless $self, $class;
  $self->initialize();

  return $self;
}

=head2 _really_apply

Applies the instantiated problem to a chromosome

=cut

sub _really_apply {
  my $self = shift;
  my $chromosome_string = shift || croak "No chromosome!!!\n";
  return $self->zdt1( $chromosome_string );
}

=head2 zdt1

Computes ZDT1, returning an array hash with the values of f1 and f2.

=cut

sub zdt1 {
    my $self = shift;
    my $string = shift;
    my @vector = decode_string( $string, 
				$self->{'_number_of_bits'},
				0, 1 );
    my $g = g( @vector );
    my $h = 1-sqrt($vector[0]/$g);
    return [ $vector[0], $g*$h ];
}

=head2 g

G function in ZDT

=cut

sub g {
  my @x = @_;
  my $sum =0;
  map( $sum += $_, @x[1..$#x] );
  return 1+NINE*$sum/(M-1);
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"What???";
