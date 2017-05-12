package Bio::RNA::SpliceSites::Scoring::MaxEntScan;

use 5.008;
use strict;
use warnings;
use Carp;

#Data submodules; these names are from the original maxEntScan distribution.
use Bio::RNA::SpliceSites::Scoring::me2x3acc;
use Bio::RNA::SpliceSites::Scoring::me2x5;
use Bio::RNA::SpliceSites::Scoring::splice5sequences;

require Exporter;

our @ISA = qw/ Exporter /;
our $VERSION = '0.05';

my $functions = [ qw/ score5 score3 / ];
our %EXPORT_TAGS = ( 'all' => $functions , );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = '0.04';

sub log2 {
  my $number = shift;
  log($number)/log(2);
}

sub is_scalar_reference {
  my $reference_to_validate = shift;
  ref( $reference_to_validate ) eq "SCALAR" ? 1 : 0;
}

sub is_kmer {
  my ( $reference_to_validate , $valid_length ) = @_;
  length $$reference_to_validate == $valid_length ? 1 : 0;
}

sub is_genetic_alphabet {
  my $reference_to_validate = shift;
  $$reference_to_validate =~ /^[ACTGactg]+$/ ? 1 : 0;
}

sub split_sequence {
  #Split the provided splice site sequence into the splice donor/acceptor dinucleotide and the concatenated remainder.
  my ( $reference_to_sequence , $splice_site_type ) = @_;
  my @sequence_array = split // , uc( $$reference_to_sequence );
  my ( $dinucleotide , $outer_portion );
  if ( $splice_site_type == 5 ) {
    $dinucleotide  =   join "" , @sequence_array[3..4]; #Positions 4 and 5 are the splice donor dinucleotide.
    $outer_portion = ( join "" , @sequence_array[0..2] )  . ( join "" , @sequence_array[5..8] );
  }
  elsif ( $splice_site_type == 3 ) {
    $dinucleotide  =   join "" , @sequence_array[18..19]; #Positions 19 and 20 are the splice acceptor dinucleotide.
    $outer_portion = ( join "" , @sequence_array[0..17] ) . ( join "" , @sequence_array[20..22] ); #Join nucleotides 1-18 and 21-23.
  }
  else {
    croak "Invalid type of splice site to split: must be either 5 or 3.\n";
  }
  return ( $dinucleotide , $outer_portion );
}

sub get_splice_5_sequence_matrix_value {
  my $outer_portion = shift;
  exists $Bio::RNA::SpliceSites::Scoring::SpliceModels::splice5sequences::table->{ $outer_portion } ?
    return $Bio::RNA::SpliceSites::Scoring::SpliceModels::splice5sequences::table->{ $outer_portion } : carp "Unable to find sequence matrix for key $outer_portion.\n";
}

sub get_splice_5_score_matrix_value {
  my $sequence_matrix_value = shift; #The term "matrix" was used in the original maxEntScan programming and is retained here for clarity.
  exists $Bio::RNA::SpliceSites::Scoring::SpliceModels::me2x5::table->[ $sequence_matrix_value ] ?
    return $Bio::RNA::SpliceSites::Scoring::SpliceModels::me2x5::table->[ $sequence_matrix_value ] : carp "Index out of score matrix range: $sequence_matrix_value\n";
}

sub score_consensus {
  my ( $dinucleotide , $type ) = @_;
  my %bgd =  ( 'A' => 0.27   , 'C' => 0.23   , 'G' => 0.23   , 'T' => 0.27 ); #Shared between each type of splice site.
  my ( %cons1 , %cons2 ); #Populate conditional to splice site type: donor or acceptor.

  if ( $type == 5 ) {
    return 15.7507349436393 if $dinucleotide eq 'GT'; #Short circuit for the perfect GT splice donor dinucleotide.
    %cons1 = ( 'A' => 0.004  , 'C' => 0.0032 , 'G' => 0.9896 , 'T' => 0.0032 );
    %cons2 = ( 'A' => 0.0034 , 'C' => 0.0039 , 'G' => 0.0042 , 'T' => 0.9884 );
  }
  elsif ( $type == 3 ) {
    #return ????? if $dinucleotide eq 'AG'; #Short circuit for perfect AG splice acceptor dinucleotide.
    %cons1 = ( 'A' => 0.9903 , 'C' => 0.0032 , 'G' => 0.0034 , 'T' => 0.003 );
    %cons2 = ( 'A' => 0.0027 , 'C' => 0.0037 , 'G' => 0.9905 , 'T' => 0.003 );
  }
  else {
    croak "Invalid type of splice site to score consensus for: must be either 5 or 3.\n";
  }

  my ( $first_nucleotide , $second_nucleotide ) = split // , $dinucleotide;
  return ( $cons1{$first_nucleotide} * $cons2{$second_nucleotide} ) / ( $bgd{$first_nucleotide} * $bgd{$second_nucleotide} );
}

sub score5 {
  my $sequence_reference = shift;
  #Validate argument:
  unless ( is_scalar_reference( $sequence_reference ) ) {
    carp "Not a scalar reference.\n";
    return 'invalid_invocation';
  }
  unless ( is_kmer( $sequence_reference , 9 ) ) {
    carp "Invalid 5'ss length: must be 9 nucleotides long.\n";
    return 'invalid_length';
  }
  unless ( is_genetic_alphabet( $sequence_reference ) ) {
    carp "Invalid alphabet: must be only [ACTGactg] with no 'n' nucleotides.\n";
    return 'invalid_alphabet';
  }

  my ( $dinucleotide , $outer_portion ) = split_sequence( $sequence_reference , 5 );

  #Compute the log2 of the product of the score_5_consensus() subroutine return for the entire sequence (left_side_of_product)
  #  and the me2x5 (score matrix) value for the sequence matrix value of the "outer portion" of the splice site, which is the heptamer with the donor dinucleotide removed
  #  from the splice site nonamer, which is assigned to the scalar variable $outer_portion

  my $score = log2( score_consensus( $dinucleotide , 5 ) * get_splice_5_score_matrix_value( get_splice_5_sequence_matrix_value( $outer_portion ) ) );
  return sprintf( "%.2f" , $score ); #2 decimals.
}

sub hash_seq {
  #Returns a hash key for a sequence as a 4-radix integer.
  #E.g. given sequence 'CAGAAGT', returns 4619 as a scalar.
  my $sequence = shift;
  $sequence=~ y/ACGT/0123/;
  my @sequence_array = split // , $sequence;
  my $sum = 0;
  my $end = length( $sequence ) - 1;

  my @four_radix = qw/ 1 4 16 64 256 1024 4096 16384 /;
  $sum += $sequence_array[$_] * $four_radix[ $end - $_ ] for 0 .. $end;
  return $sum;
}

sub get_max_ent_score {
  my ( $sequence , $table_ref ) = @_; #Table ref is a reference to an array of references to hashes prepared in the me2x3acc submodule.
  my @partial_score = ( $table_ref->[0]{ hash_seq( substr $sequence , 0  , 7 ) } ,
			$table_ref->[1]{ hash_seq( substr $sequence , 7  , 7 ) } ,
			$table_ref->[2]{ hash_seq( substr $sequence , 14 , 7 ) } ,
			$table_ref->[3]{ hash_seq( substr $sequence , 4  , 7 ) } ,
			$table_ref->[4]{ hash_seq( substr $sequence , 11 , 7 ) } ,
			$table_ref->[5]{ hash_seq( substr $sequence , 4  , 3 ) } ,
			$table_ref->[6]{ hash_seq( substr $sequence , 7  , 4 ) } ,
			$table_ref->[7]{ hash_seq( substr $sequence , 11 , 3 ) } ,
			$table_ref->[8]{ hash_seq( substr $sequence , 14 , 4 ) } );
  my $final_score = $partial_score[0] * $partial_score[1] * $partial_score[2] * $partial_score[3] * $partial_score[4] /
    ( $partial_score[5] * $partial_score[6] * $partial_score[7] * $partial_score[8] );
  return $final_score;
}

sub score3 {
  my $sequence_reference = shift; #Should be 23nt long.
  #Validate argument:
  unless ( is_scalar_reference( $sequence_reference ) ) {
    carp "Not a scalar reference.\n";
    return 'invalid_invocation';
  }
  unless ( is_kmer( $sequence_reference , 23 ) ) {
    carp "Invalid 3'ss length: must be 23nt long.\n";
    return 'invalid_length';
  }
  unless ( is_genetic_alphabet( $sequence_reference ) ) {
    carp "Invalid alphabet: must be only [ACTGactg] with no 'n' nucleotides.\n";
    return 'invalid_alphabet';
  }

  my ( $dinucleotide , $outer_portion ) = split_sequence( $sequence_reference , 3 );
  my $score = log2( score_consensus( $dinucleotide , 3 ) * get_max_ent_score( $outer_portion , $Bio::RNA::SpliceSites::Scoring::SpliceModels::me2x3acc::table ) );
  return sprintf( "%.2f" , $score ); #2 decimals.
}

1;

__END__

=head1 NAME

Bio::RNA::SpliceSites::Scoring::MaxEntScan - Perl module for pre-mRNA splice site scoring by the maxEntScan algorithm of Gene Yeo and Chris Burge.

=head1 SYNOPSIS

use Bio::RNA::SpliceSites::Scoring::MaxEntScan qw/ score5 /;

my $five_prime_splice_site = q/ CAGGTTGGC /;

my $five_prime_splice_site_score = score5( \$five_prime_splice_site ); #Return value is a scalar, not a reference.

use Bio::RNA::SpliceSites::Scoring::MaxEntScan qw/ score3 /;

my $three_prime_splice_site = q/ ctctactactatctatctagatc /; #Both scoring subroutines are case-insensitive.

my $three_prime_splice_site_score = score3( \$three_prime_splice_site ); #Returns 6.71.

use Bio::MaxEntScan::SpliceSites::Scoring::MaxEntScan qw/ :all /; #Imports both subroutines.

=head1 DESCRIPTION

This module scores 5' and 3' splice sites using the maxEntScan algorithm.  See the original publication (citattion below) for details on the scoring algorithm.

=head2 EXPORT

None by default.  The following two functions are available for export:

score5
score3

Both of these functions emulate the original maxEntScan scripts of the same names, except that they do not return a sequence string, only the score.  See below for descriptions.

The all tag:

:all

...imports both subroutines.

5' splice sites must be 9 nucleotides long  and must contain the 3' (terminal) 3 nucleotides of the exon and the first 6 nucleotides of the 5' end of the intron.
3' splice sites must be 23 nucleotides long and must contain the 3' (terminal) 20 nucleotides of the intron and the first 2 nucleotides of the 5' end of the exon.

Both functions will provide error messages on the standard error stream if a splice site of improper length is passed by reference.

Additional errors include an invalid genetic alphabet (must contain only [ACTGactg] nucleotides, no 'N' nucleotides are allowed by the algorithm) or passing a non-reference to the scoring subroutine(s).

The function will still return a value for errors to maintain output file structure.  These are:

'invalid_length'      An invalid splice site length is provided.
'invalid_alphabet'    Nucleotides other than [ACTGactg] were encountered, and the splice site cannot be scored.
'invalid_invocation'  A value that was not a scalar reference was passed to the scoring subroutine.

=head2 SUBROUTINES FOR SPLICE SITE SCORING

=over 1

=item score5

When passed a reference to a scalar containing a nonamer sequence representing a 5' splice site to score, returns a scalar containing the score.

5' splice sites must be 9 nucleotides long  and must contain the 3' (terminal) 3 nucleotides of the exon and the first 6 nucleotides of the 5' end of the intron.

Both splice site scoring functions will provide error messages on the standard error stream if a splice site of improper length is passed by reference.

Additional errors include an invalid genetic alphabet (must contain only [ACTGactg] nucleotides, no 'N' nucleotides are allowed by the algorithm) or passing a non-reference to the scoring subroutine(s).

The function will still return a value for errors to maintain output file structure.  These are:

'invalid_length'      An invalid splice site length is provided.
'invalid_alphabet'    Nucleotides other than [ACTGactg] were encountered, and the splice site cannot be scored.
'invalid_invocation'  A value that was not a scalar reference was passed to the scoring subroutine.

=item score3

When passed a reference to a scalar containing a 23mer sequence representing a 3' splice site to score, returns a scalar containing the score.

3' splice sites must be 23 nucleotides long and must contain the 3' (terminal) 20 nucleotides of the intron and the first 2 nucleotides of the 5' end of the exon.

The same error messages generated by score5() will be returned for an invalid subroutine invocation, and invalid 3'ss length, or an invalid genetic alphabet.

=back

=head2 INTERNAL SUBROUTINES

The following subroutines are used internally by the above splice site scoring functions.

=over 1

=item get_max_ent_score

Returns the maxEntScore for the 3'ss.  This subroutine was developed from the getmaxentscore() subroutine in the original score3.pl script provided with maxEntScan from MIT.

=item get_splice_5_score_matrix_value

Returns the score matrix value for a provided 5'ss.

=item get_splice_5_sequence_matrix_value

Returns the sequence matrix value for a provided 5'ss.

=item hash_seq

Converts an oligonucleotide sequence (all uppercase) to a 4-radix integer.  This approach was used in the original maxEntScan score3.pl program.

=item is_genetic_alphabet

Returns 1 (TRUE) if the sequence passed to the subroutine is in a valid genetic alphabet, 0 (FALSE) otherwise.

=item is_kmer

When passed a sequence and an expected length, returns 1 (TRUE) if the sequence is the expected length, and 0 (FALSE) otherwise.

=item is_scalar_reference

Checks the first argument to see if it is a reference, returning 1 (TRUE) if yes, otherwise 0 (FALSE).

=item log2

Converts its argument into a log2.  See the documentation for the `log` function.

=item score_consensus

When passed a splice site consensus dinucleotide and the splice site type as an integer (either 5 or 3), scores the splice donor or splice acceptor dinucleotide according to background values specific for the specified splice site type.  This subroutine is used by both score5() and score3() subroutines.

=item split_sequence

When passed a scalar splice site sequence and the splice site type as an integer (either 5 or 3), splits the splice site into the splice donor/acceptor dinucleotide and the concatenated remainder of the scalar.  This subroutine is used by both the score5() and score3() subroutines.

=back

=head1 SEE ALSO

Algorithm:  

J Comput biol. 2004;11(2-3):377-94
Maximum entropy modeling of short sequence motifs with applications to RNA splicing signals.
Yeo G, Burge CB
PMID: 15285897

=head1 AUTHOR

Brian Sebastian Cole, E<lt>colebr@mail.med.upenn.eduE<gt>

=head1 COPYRIGHT AND LICENSE

maxEntScan algorithm:
Copyright (C) 2004 by Gene Yeo and Chris Burge

This distrubtion:
Copyright (C) 2014,2015 by Brian Sebastian Cole

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 ACKNOWLEDGEMENTS

The author would like to acknowledge the support of his thesis advisor Dr. Kristen Lynch, PhD.

Thanks go to John Karr of the Philadelphia Perl Mongers for the sagacious suggestion of using data submodules to hold splice models.

=cut
