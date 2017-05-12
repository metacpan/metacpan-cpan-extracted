use strict; # -*- cperl -*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Fitness::ECC - Error Correcting codes problem generator

=head1 SYNOPSIS

    my $number_of_codewords = 10;
    my $min_distance = 1;
    my $p_peaks = Algorithm::Evolutionary::Fitness::ECC->new( $number_of_codewords, $min_distance );

=head1 DESCRIPTION

Extracted from article "Effects of scale-free and small-world topologies on binary coded self-adaptive CEA", by Giacobini et al [Ga]. Quoting:

"                                                    The ECC problem was presented in
[MW]. We will consider a three-tuple (n, M, d), where n is the length of each codeword
(number of bits), M is the number of codewords, and d is the minimum Hamming
distance between any pair of codewords. Our objective will be to find a code which
has a value for d as large as possible (reflecting greater tolerance to noise and errors),
given previously fixed values for n and M . The problem we have studied is a simplified
version of that in [MW]. In our case we search half of the codewords (M/2) that will
compose the code, and the other half is made up by the complement of the codewords
computed by the algorithm"

[Ga] Mario Giacobini, Mike Preuss, Marco Tomassini: Effects of Scale-Free and Small-World Topologies on Binary Coded Self-adaptive CEA. EvoCOP 2006: 86-98.

[MW] F. J. MacWilliams and N. J. A. Sloane. The Theory of Error-Correcting Codes. North-
    Holland, Amsterdam, 1977.


=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::ECC;

our $VERSION = '3.2';

use Carp qw(croak);

use lib qw(../../.. ../.. ..);

use base qw(Algorithm::Evolutionary::Fitness::String);
use Algorithm::Evolutionary::Utils qw(hamming);

=head2 new

Creates a new instance of the problem, with the said number of bits and peaks

=cut 

sub new {
  my $class = shift;
  my ($number_of_codewords, $min_distance ) = @_;
  croak "Too few codewords" if !$number_of_codewords;
  croak "Distance too small" if !$min_distance;
  my $self = $class->SUPER::new();
  bless $self, $class;
  $self->initialize();
  $self->{'number_of_codewords'} = $number_of_codewords;
  return $self;
}

=head2 _really_apply

Applies the instantiated problem to a chromosome

=cut

sub _really_apply {
  my $self = shift;
  return $self->ecc( @_ );
}

=head2 ecc

Applies the instantiated problem to a string

=cut

sub ecc {
    my $self = shift;
    my $string = shift || croak "Can't work with a null string";
    my $cache = $self->{'_cache'};
    if ( $cache->{$string} ) {
	return $cache->{$string};
    }
    my $length = length($string)/$self->{'number_of_codewords'};
    my @codewords = ( $string =~ /.{$length}/gs );
    my $distance;
    for ( my $i = 0; $i <= $#codewords; $i ++ ) {
      for ( my $j = $i+1; $j <= $#codewords; $j ++ ) {
	my $this_distance = hamming( $codewords[$i], $codewords[$j] );
	$distance += 1/(1+$this_distance*$this_distance);
      }
    }
    $cache->{$string} = 1/$distance;
    return $cache->{$string};

}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"What???";
