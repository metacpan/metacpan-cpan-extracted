use strict; #-*-CPerl-*-
use warnings;

use lib qw( ../../../lib );

=head1 NAME

Algorithm::Evolutionary::Utils - Container module with a hodgepodge of functions
                 
=head1 SYNOPSIS
  
  use Algorithm::Evolutionary::Utils qw(entropy genotypic_entropy hamming consensus average random_bitstring random_number_array decode_string vector_compare );

  my $this_entropy = entropy( $population );

  #Computes consensus sequence (for binary chromosomes
  my $this_consensus = consensus( $population); 

=head1 DESCRIPTION

Miscellaneous class that contains functions that might be useful
    somewhere else, especially when computing EA statistics.  

=cut


=head1 METHODS

=cut

package Algorithm::Evolutionary::Utils;

use Exporter;
our @ISA = qw(Exporter);

our $VERSION =   sprintf "3.4";

our @EXPORT_OK = qw( entropy genotypic_entropy consensus hamming 
		     random_bitstring random_number_array average 
		     parse_xml decode_string vector_compare);

use Carp;
use String::Random;
use XML::Parser;
use Statistics::Basic qw(mean);

=head2 entropy( $population)

Computes the entropy using the well known Shannon's formula: L<http://en.wikipedia.org/wiki/Information_entropy>
'to avoid botching highlighting

=cut

sub entropy {
  my $population = shift;
  my %frequencies;
  map( (defined $_->Fitness())?$frequencies{$_->Fitness()}++:1, @$population );
  my $entropy = 0;
  my $gente = scalar(@$population); # Population size
  for my $f ( keys %frequencies ) {
    my $this_freq = $frequencies{$f}/$gente;
    $entropy -= $this_freq*log( $this_freq );
  }
  return $entropy;
}

=head2 genotypic_entropy( $population)

Computes the entropy using the well known Shannon's formula:
L<http://en.wikipedia.org/wiki/Information_entropy> 'to avoid botching
highlighting; in this case we use chromosome frequencies instead of
fitness. 

=cut

sub genotypic_entropy {
  my $population = shift;
  my %frequencies;
  map( $frequencies{$_->{'_str'}}++, @$population );
  my $entropy = 0;
  my $gente = scalar(@$population); # Population size
  for my $f ( keys %frequencies ) {
    my $this_freq = $frequencies{$f}/$gente;
    $entropy -= $this_freq*log( $this_freq );
  }
  return $entropy;
}

=head2 hamming( $string_a, $string_b )

Computes the number of positions that are different among two strings, the well known Hamming distance. 

=cut

sub hamming {
    my ($string_a, $string_b) = @_;
    return ( ( $string_a ^ $string_b ) =~ tr/\1//);
}

=head2 consensus( $population, $rough = 0 )

Consensus sequence representing the majoritary value for each bit;
returns the consensus binary string. If "rough", then the bit is set only if the 
difference is bigger than 0.4 (60/40 proportion).

=cut

sub consensus {
  my $population = shift;
  my $rough = shift;
  my @frequencies;
  for ( @$population ) {
      for ( my $i = 0; $i < $_->size(); $i ++ ) {
	  if ( !$frequencies[$i] ) {
	      $frequencies[$i]={ 0 => 0,
			     1 => 0};
	  }
	  $frequencies[$i]->{substr($_->{'_str'}, $i, 1)}++;
      }
  }
  my $consensus;
  for my $f ( @frequencies ) {
    if ( !$rough ) {
      if ( $f->{'0'} > $f->{'1'} ) {
	$consensus.='0';
      } else {
	$consensus.='1';
      }
    } else {
      my $difference = abs( $f->{'0'} - $f->{'1'} );
      if ( $difference < 0.4 ) {
	$consensus .= '-';
      } else {
	if ( $f->{'0'} > $f->{'1'} ) {
	  $consensus.='0';
	} else {
	  $consensus.='1';
	}
      }
    }
  }
  return $consensus;
}

=head2 average( $population )

Computes an average of population fitness

=cut

sub average {
  my $population = shift;
  my @frequencies;
  my @fitnesses = map( $_->Fitness(), @$population );
  return mean( @fitnesses );

}

=head2 random_bitstring( $bits )

Returns a random bitstring with the stated number of bits. Useful for testing,mainly

=cut

sub random_bitstring {
  my $bits = shift || croak "No bits!";
  my $generator = new String::Random;
  my $regex = "\[01\]{$bits}";
  return $generator->randregex($regex);
}

=head2 random_number_array( $dimensions [, $min = -1] [, $range = 2] )

Returns a random number array with the stated length. Useful for testing, mainly.

=cut

sub random_number_array {
  my $dimensions = shift || croak "No bits!";
  my $min = shift || -1;
  my $range = shift || 2;

  my @array;
  for ( my $i = 0; $i < $dimensions; $i ++ ) {
    push @array, $min + rand($range);
  }
  return @array;
}

=head2 parse_xml( $string ) 

Parses the string and returns an XML tree

=cut

sub parse_xml {
  my $string = shift || croak "No string to parse!\n";
  my $p=new XML::Parser(Style=>'EasyTree');
  $XML::Parser::EasyTree::Noempty=1;
  my $xml_dom = $p->parse($string) || croak "Problems parsing $string: $!\n";
  return $xml_dom;
}

=head2 decode_string( $chromosome, $gene_size, $min, $range )

Decodes to a vector, each one of whose components ranges between $min
and $max. Returns that vector.

It does not work for $gene_size too big. Certainly not for 64, maybe for 32.

=cut

sub decode_string {
  my ( $chromosome, $gene_size, $min, $range ) = @_;

  my @output_vector;
  my $max_range = eval "0b"."1"x$gene_size;
  for (my $i = 0; $i < length($chromosome)/$gene_size; $i ++ ) {
    my $substr = substr( $chromosome, $i*$gene_size, $gene_size );
    push @output_vector, (($range - $min) * eval("0b$substr") / $max_range) + $min; 
  }
  return @output_vector;
}

=head2 vector_compare( $vector_1, $vector_2 )

Compares vectors, returns 1 if 1 dominates 2, -1 if it's the other way
round, and 0 if neither dominates the other. Both vectors are supposed
to be numeric. Returns C<undef> if neither is bigger, and they are not
equal. Fails if the length is not the same. 

=cut

sub vector_compare {
  my ( $vector_1, $vector_2 ) = @_;

  if ( scalar @$vector_1 != scalar @$vector_2 ) {
    croak "Different lengths, can't compare\n";
  }

  my $length = scalar @$vector_1;
  my @results = map( $vector_1->[$_] <=> $vector_2->[$_], 0..($length-1));
  my %comparisons;
  map( $comparisons{$_}++, @results );
  if ( $comparisons{1} && !$comparisons{-1} ) {
    return 1;
  }
  if ( !$comparisons{1} && $comparisons{-1} ) {
    return -1;
  }
  if ( defined $comparisons{0} && $comparisons{0} == $length ) {
    return 0;
  }
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"Still there?";
