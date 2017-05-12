# Bio::fastAPD module
#
# Authors: Joseph D. Baugher, Phd, Fernando J. Pineda, PhD 
# Maintainer: Joseph D. Baugher, PhD (<joebaugher@hotmail.com>) 
#
# Copyright (c) 2014,2015 Joseph D. Baugher (<joebaugher@hotmail.com>). All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself. See L<perlartistic>.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 NAME

Bio::fastAPD -- rapid calculation of average pairwise difference (APD) for multiple sequence alignments

=head1 VERSION

Version 1.10.0

=head1 SYNOPSIS

    use Bio::fastAPD;
	
    my $file_name = "example_data.fasta";
    open(my $input_fh, '<', $file_name) or croak ("Could not open $file_name\n");
    chomp(my @fasta_lines = <$input_fh>);
    close $input_fh;

    # Create an array of aligned sequences
    my @sequences;
    my $curr_seq;
    foreach my $line (@fasta_lines) {
        if (substr($line, 0, 1) eq ">") { 
            if ($curr_seq) { push(@sequences, $curr_seq) }
            $curr_seq = ();
        }
        else { $curr_seq .= $line }
    }
    if ($curr_seq) { push(@sequences, $curr_seq) }       
    
    my $fastAPD_obj = Bio::fastAPD->new();
    $fastAPD_obj->initialize(seq_array_ref => \@sequences,
                             alphabet      => 'dna');

    my $apd = $fastAPD_obj->apd('gap_base');
                                            
    my $std_err = $fastAPD_obj->std_err('gap_base');

    my $num_reads     = $fastAPD_obj->n_reads;                                      
    my $num_positions = $fastAPD_obj->width;        
   
    print join("\t", qw(File APD StdErr Positions Reads)), "\n";      
    print join("\t", $file_name, $apd, $std_err, $num_positions, $num_reads), "\n";  

    # OR

    use Bio::fastAPD;
    use Bio::AlignIO;

    my $file_name = 'example_data.fasta';
    my $alignio_obj = Bio::AlignIO->new( -file     => $file_name,
                                         -format   => 'fasta',
                                         -alphabet => 'dna');
    my $aln_obj = $alignio_obj->next_aln();
    
    # Create an array of aligned sequences
    my @sequences;  
    foreach my $seq_obj ($aln_obj->each_seq) { push(@sequences, $seq_obj->seq()) }
        
    my $fastAPD_obj = Bio::fastAPD->new();
    $fastAPD_obj->initialize(seq_array_ref => \@sequences,
                             alphabet      => 'dna');
        
    my $apd = $fastAPD_obj->apd('gap_base');
                                                
    my $std_err = $fastAPD_obj->std_err('gap_base');
   
    my $num_reads     = $fastAPD_obj->n_reads;                                      
    my $num_positions = $fastAPD_obj->width;        
          
    print join("\t", qw(File APD StdErr Positions Reads)), "\n";      
    print join("\t", $file_name, $apd, $std_err, $num_positions, $num_reads), "\n";  
        
=head1 DESCRIPTION

The Bio::fastAPD module provides a computationally efficient method for the calculation of 
average pairwise difference (APD), a measure of nucleotide diversity, from multiple 
sequence alignment (MSA) data. This module also provides rapid standard error estimation
of the APD using an efficient jackknife resampling method. Further description of the
methods implemented in this module, including mathematical justification, will be
available in an upcoming peer-reviewed journal article.
 
=head1 CONSTRUCTOR

    my $fastAPD_obj = Bio::fastAPD->new();

=head1 INITIALIZER

The initialization subroutine accepts a reference to an array of sequence reads from a
multiple sequence alignment. It accepts alphabet designations of 'dna', 'rna' or 
'protein'. In order to ignore specific positions in the sequence alignment a binary mask 
variable may be supplied consisting of a string of 1's (evaluate) and 0's (ignore) 
of length equal to the length of the alignment. By default, all positions in the 
alignment are evaluated.

Acceptable characters - 

'dna' - ACGT, 'N' for missing base, '-', '~', or '.' for gaps (alignment padding)

'rna' - ACGU, 'N' for missing base, '-', '~', or '.' for gaps (alignment padding)

'protein' - ACDEFGHIKLMNPQRSTVWY, '*' for stop codon, 'X' for missing amino acid,
              '-', '~', or '.' for gaps (alignment padding)

    $fastAPD_obj->initialize(-seq_ref  => \@sequences,
                             -alphabet => 'dna',
                             -mask     => $mask);

=head1 OBJECT METHODS

Additional info in the Appendix.

    fastAPD_obj->apd('gap_base')  
                                        
        # Perform rapid APD calculation.   
 
    fastAPD_obj->std_err('gap_base')
                                       
        # Estimate standard error of the APD result.      
                                                   
    fastAPD_obj->gap_threshold()

        # Set or get max proportion of gap symbols (-,~,.) allowable for a valid position

    fastAPD_obj->null_threshold()

        # Set or get max proportion of N symbols allowable for a valid position

    fastAPD_obj->end_threshold()

        # Set or get max proportion of ragged end (-,~,.) symbols allowable for a valid position

    fastAPD_obj->n_reads()

        # Get the number of reads

    fastAPD_obj->n_valid_positions()

        # Get the number of positions in the alignment which meet the analysis criteria
           
    fastAPD_obj->valid_positions()

        # Get the positions in the alignment which meet the analysis criteria

    fastAPD_obj->width()

        # Get the width of the alignment

    fastAPD_obj->freqs()

        # Get the frequencies of each symbol at each position

    fastAPD_obj->consensus_alignment()

        # Get the consensus sequence of the aligned input sequences

=head1 AUTHORS

Joseph D. Baugher, PhD <joebaugher@hotmail.com>
Fernando J. Pineda, PhD <fernando.pineda@jhu.edu>

=head1 MAINTAINER

Joseph D. Baugher, PhD <joebaugher@hotmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Joseph D. Baugher (<joebaugher@hotmail.com>). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 APPENDIX

The following documentation describes the Bio::fastAPD module implementation.

=cut

package Bio::fastAPD;

use strict;
use warnings;
use Carp;
use 5.8.8;
our $VERSION = '1.10.0';

# ----------------------------------------
# symbols & matrices
# ----------------------------------------

my $_null;              # null symbol
my $_gap;               # gap symbol
my $_end;               # symbol for leading or trailing gaps or nulls due to read length
my $_gap_null;          # gap and null symbols
my @_residues;          # residues array
my $_residues;          # residues string
my @_alphabet;          # alphabet array
my $_alphabet;          # alphabet string
my @_observed_symbols;  # all symbols found in the alignment
my $_residues_and_gap;  # all symbols except null
my @_mask;              # binary mask defining which positions to analyze
my %_alpha_mask;        # binary mask hash defining which symbols to compare

# ----------------------------------------
# diversity and error calculation variables
# ----------------------------------------
my $_comparison_type; # gap_base      - pairwise deletion 
                      #               - valid comparisons = base_base and gap_base
                      # base_base     - pairwise deletion 
                      #               - valid comparisons = base_base only
                      # complete_del  - complete deletion
                      #               - positions containing any missing data ignored
my $_alphabet_type;   # 'dna', 'rna', or 'protein'

my $_K;               # number of reads in the alignment
my $_W;               # width (number of columns) of the alignment
my @_freq;            # symbol frequencies in the alignment
my @_valid_positions; # positions in the alignment which meet the analysis criteria
my $_gap_threshold;   # max proportion of gap symbols allowable for a valid position
my $_null_threshold;  # max proportion of N symbols allowable for a valid position
my $_end_threshold;   # max proportion of ragged end symbols allowable for a valid position

# ----------------------------------
# new -- initialize symbols and matrices
# ----------------------------------
my %_options=();

=pod 

B<new>

 Title   : new
 Usage   : my $fastAPD_obj = Bio::fastAPD->new()
 Function: Creates a Bio::fastAPD object
 Returns : A blessed reference
 Args    : No arguments

=cut

sub new 
{ 
    my $self = shift;

    $_gap_threshold  = 1;
    $_null_threshold = 1;
    $_end_threshold  = 1;
    
    return bless{};
}

# ----------------------------------
# initialize new diversity calculation
# ----------------------------------
my @_read_buffer; # holds preprocessed read strings

=pod 

B<initialize>

 Title   : initialize
 Usage   : $fastAPD_obj->initialize(seq_ref  => \@sequences,
                                    alphabet => 'dna',
                                    mask     => $mask);
 Function: Initializes a Bio::fastAPD object.
              1. Initializes internal variables. 
              2. Prepares sequence reads for analysis. 
              3. Counts symbol frequencies.
              4. Performs quality checks for erroneous symbols
              5. Defines valid positions for analysis
 Returns : 
 Args    : -seq_ref => \@sequences
             a reference to an array of sequences from an MSA
           -alphabet => 'dna'
             Alphabet designations of 'dna', 'rna' or 'protein'.
             
             Acceptable characters - 
             'dna' - 'ACGT', 'N' for missing base, '-', '~', or '.' for gaps(padding)
             'rna' - 'ACGU', 'N' for missing base, '-', '~', or '.' for gaps(padding)
             'protein' - 'ACDEFGHIKLMNPQRSTVWY', '*' for stop codon, 'X' for missing 
                          amino acid, '-', '~', or '.' for gaps (alignment padding)
           -mask => $mask
             In order to ignore specific positions in the sequence alignment a mask 
             variable should be created consisting of a string of 1's (evaluate) and 0's 
             (ignore) of length equal to the length of the alignment. By default, all 
             positions in the alignment are evaluated.
 Calls   : _standardize_the_read, _accumulate_symbol_frequencies, _qc_symbols,
           _define_valid_positions

=cut

sub initialize {
    my $self = shift;
    my %args = @_;
    my $seq_array_ref = $args{seq_array_ref};
    $_alphabet_type   = $args{alphabet};
    my $mask          = $args{mask};

    if($_alphabet_type eq 'dna') {
        $_null     = 'N';
        @_residues = qw(A C G T);
    }
    elsif($_alphabet_type eq 'rna') {
        $_null     = 'N';
        @_residues = qw(A C G U);
    }
    elsif($_alphabet_type eq 'protein') {
        $_null     = 'X';
        @_residues = qw(A C D E F G H I K L M N P Q R S T V W Y *);
    }
    else {
        $_alphabet_type = 'dna';
        $_null     = 'N';
        @_residues = qw(A C G T);
    }    
    $_gap      = '-~.';
    $_end      = '#';
    $_gap_null = $_gap.$_null;
    $_residues = join '',@_residues;

    # reset variables
    $_K     = 0;
    $_W     = 0;
    @_valid_positions = ();   
    
    # load the read buffer with standardized reads
    # and count the positions ($_W) and rows ($_K) in the alignment
    @_read_buffer = ();    
    foreach my $seq_string (@$seq_array_ref) {
        $_read_buffer[$_K] =  _standardize_the_read($seq_string);
        $_K++;
    }
    
    _accumulate_symbol_frequencies();

    # detect which of the possible gap symbols is present
    foreach my $symbol (@_observed_symbols) {
        if($symbol =~ /[$_gap]/) { $_gap = $symbol }
        else{ $_gap = "-" }
    }

    $_gap_null = $_gap.$_null;
    $_residues_and_gap = $_residues.$_gap;
    @_alphabet = sort (@_residues, $_gap, $_null, $_end);
    $_alphabet = join("", @_alphabet);

    _qc_symbols();

    # populate the analysis mask array: 0 = skip; 1 = analyze; (default = analyze all positions)
    if ($mask) { @_mask = split(//,$mask) }
    else { @_mask = (1) x $_W }
    
    _define_valid_positions();
}

# ----------------------------------
# processing and analysis functions
# ----------------------------------

=pod 

B<_standardize_the_read>

 Title   : _standardize_the_read
 Usage   : $standardized_seq_string = _standardize_the_read($seq_string);
 Function: Replaces ragged end (-) padding symbols with (#) symbols to differentiate
             between internal gaps. Converts all symbols to uppercase.
 Returns : A variable containing the standardized sequence
 Args    : A variable containing the input sequence

=cut

sub _standardize_the_read {
    my $seq_string = shift;
    $_W = length($seq_string); # width of the alignment (should be the same for all reads in the alignment)

    # 1) trim leading nonresidue symbols with end symbol (because could be masked or padded with gaps)
    my ($leader) = ($seq_string =~ m/^([$_gap_null]+)/);
    if(defined($leader)) {
        my $len     = length($leader);
        $seq_string = ($_end x $len) . substr($seq_string, $len); 
    }

    # 2) trim trailing nonresidue symbols with end symbol (because could be masked or padded with gaps)
    my ($trailer) = ($seq_string =~ m/([$_gap_null]+)$/);
    if(defined($trailer)) {
        my $len     = length($trailer);
        $seq_string = substr($seq_string, 0, -$len) . ($_end x $len);
    }
    
    # Convert any lowercase alphabet symbols to uppercase
    $seq_string = uc $seq_string;    
    
    return $seq_string;
}

=pod 

B<_accumulate_symbol_frequencies>

 Title   : _accumulate_symbol_frequencies
 Usage   : _accumulate_symbol_frequencies();
 Function: Counts and stores frequencies of each symbol at each position.
 Returns : 1
 Args    : None

=cut

sub _accumulate_symbol_frequencies {
    @_freq =();
    my %counts=();

    # initialize the accumulators
    for(my $i=0; $i<$_W; $i++) {
        $_freq[$i]=undef;
    }
    
    # accumulate symbol counts    
    for(my $k=0; $k<$_K; $k++) { 
        my @symbol_sequence = split //,$_read_buffer[$k];
        for(my $i=0; $i<$_W; $i++) {
            my $symbol = $symbol_sequence[$i];            
            $_freq[$i]{$symbol}++;
            $counts{$symbol}++;
        }
    }
    @_observed_symbols = keys %counts;

    return(1);
}

=pod 

B<_qc_symbols>

 Title   : _qc_symbols
 Usage   : _qc_symbols();
 Function: Performs error checking for acceptable symbols. May carp(warn) or croak(die).
 Returns : 1
 Args    : None

=cut

sub _qc_symbols {
    
    # remove end symbol for printing
    my  (@no_end_alpha, @no_end_obs);
    for (@_observed_symbols) {unless ($_ eq $_end) {push(@no_end_obs, $_)}}
    for (@_alphabet) {unless ($_ eq $_end) {push(@no_end_alpha, $_)}}    

    # warn if alphabet type is 'protein' but input looks like nucleic acid
    if ($_alphabet_type eq 'protein' && @_observed_symbols <= length("ACGT$_gap$_null$_end")) {
        my $msg = "\nWarning: You have specified the alphabet type as 'protein', \n";
        $msg .=  "  but the input data may be dna or rna.\n"; 
        $msg .= "An incorrect alphabet will cause erroneous results.\n";
        $msg .= "Expected alphabet: @no_end_alpha\n";
        $msg .= "Found alphabet: @no_end_obs\n\n";
        carp($msg);
    } 
    
    # croak if unexpected symbols are detected
    my $observed_symbols = join("", @_observed_symbols);
    if ($observed_symbols =~ /[^$_alphabet]/) {
        my $msg = "\nUnexpected symbols detected in the input sequences!\n";
        $msg .= "Expected alphabet: @no_end_alpha\n";
        $msg .= "Found alphabet: @no_end_obs\n\n";
        croak($msg);
    }
    
    # fill-in with 0 the frequency of missing symbols in positions that don't 
    # have the full complement of symbols
    for(my $i=0; $i<$_W; $i++) {
        foreach my $symbol (@_observed_symbols) {
            unless(defined($_freq[$i]{$symbol})) {
                $_freq[$i]{$symbol} = 0; 
            }
        }
    }

    # fill-in with 0's the frequency of any alphabet symbols that did not appear
    # in the input sequences
    for(my $i=0; $i<$_W; $i++) {
        #foreach my $alpha (@_residues) {
        foreach my $alpha (@_alphabet) {
            if(!defined($_freq[$i]{$alpha})) {
                $_freq[$i]{$alpha} = 0;
            }
        }    
    }    

    return(1);
}

=pod 

B<_define_valid_positions>

 Title   : _define_valid_positions
 Usage   : _define_valid_positions();
 Function: Builds array of valid alignment positions for analysis (below the null, gap, 
           and end thresholds and are not masked).  
 Returns : 1 or undef if no positions are valid
 Args    : None

=cut

sub _define_valid_positions {
    @_valid_positions = ();
    for(my $i=0; $i< $_W; $i++) {
        if(  ($_freq[$i]{$_gap}   <= $_gap_threshold * $_K) 
            & ($_freq[$i]{$_null} <= $_null_threshold * $_K)
            & ($_freq[$i]{$_end}  <= $_end_threshold * $_K)            
            & $_mask[$i]) {
            push @_valid_positions, $i;
        }
    }
    
    # if there are no valid positions to analyze return undef    
    unless (@_valid_positions) {
        return undef;
    }
    return(1);
}

# ----------------------------------
# Fast nucleotide diversity
# ----------------------------------    

=pod 

B<apd>

 Title   : apd
 Usage   : $apd = $fastAPD_obj->apd('gap_base');
 Function: Returns the APD value            
 Returns : APD
 Args    : Comparison algorithm
               Default = 'gap_base'.
               Defines acceptable pairwise comparisons
               'gap_base'     - pairwise deletion
                              - valid comparisons = base to base and gap to base
               'base_base'    - pairwise deletion
                              - valid comparisons = base to base only
               'complete_del' - complete deletion
                              - all positions containing any missing data ignored
 Calls   :  _create_alpha_mask, _calculate_apd
 
=cut

sub apd {
    my $self = shift;
    $_comparison_type = shift;
	
    return( _calculate_apd() );
}

=pod 

B<_calculate_apd>

 Title   : _calculate_apd
 Usage   : _calculate_apd();
 Function: Performs the fast APD calculation - nucleotide diversity per pair of bases 
             (ratio of sums). 
             APD ($d) = Total Mismatches ($m) / Total Pairwise comparisons ($p)
               where $m = $p - Total Matches (%matches)
               where matches = binomial coefficient(frequency of a given symbol, 2) 
                               summed over appropriate symbols and valid positions
               where $p      = binomial coefficient(number of rows at a given position, 2)
                               summed over valid positions                 
 Returns : The APD value ($d)
 Args    : None
 Calls   : _create_alpha_mask, choose_2
 
=cut

sub _calculate_apd {
    my ($p, $sum_freqs);
    my %matches;       

    _create_alpha_mask();

    # sum the number of matches and pairs
    foreach my $i (@_valid_positions) {
        foreach my $alpha (@_alphabet) {
            $sum_freqs += $_freq[$i]{$alpha}*$_alpha_mask{$alpha};
            $matches{$alpha} += _choose_2($_freq[$i]{$alpha}*$_alpha_mask{$alpha});
        }
        $p += _choose_2($sum_freqs);
        $sum_freqs = 0;
    }
    
    # remove gap_gap comparisons
    $p -= $matches{$_gap};
    
    # calculate mismatches
    my $sum_matches = 0;
    foreach (@_residues) {$sum_matches += $matches{$_}}
    my $m = $p - $sum_matches;
	my $d = 0;
    $d = $m / $p unless $m == 0;
    return($d);
}

=pod

B<std_err>

 Title   : std_err
 Usage   : $se = $fastAPD_obj->std_err('gap_base');
 Function: Iterates over the number of reads ($_K) adjusting the original frequency
             counts to ignore one read at each iteration. Calls an APD subroutine at each
             iteration and stores the diversity values. Calls _jackknifeSE to calculate
             the standard error.
 Returns : The standard error of the APD ($_seD) as estimated by jackknife resampling.
 Args    : Comparison method
               Default = 'gap_base'.
 Calls   : _calculate_apd, _jackknifeSE

=cut

sub std_err {
    my $self = shift;
    $_comparison_type = shift;
	
    # Iterate over the number of reads ($_K) adjusting the original frequency
    # counts to ignore one read at each iteration
    my @_orig_freq = @_freq;
    my $stop = $_K;
    my @indices = 1..$_K;
    $_K--;
    my @diversities = (0) x $stop;
    
    for(my $k=0; $k<$stop; $k++) {
        my @symbol_sequence = split //,$_read_buffer[$k];
        for(my $i=0; $i<$_W; $i++) {
            my $symbol = $symbol_sequence[$i];
            $_freq[$i]{$symbol}--;
        }

        # Calculate diversity and store for each iteration
        $diversities[$k] = _calculate_apd();
        for(my $i=0; $i<$_W; $i++) {
            my $symbol = $symbol_sequence[$i];
            $_freq[$i]{$symbol}++;
        }
    }
        
    $_K++;
    _create_alpha_mask();
    my $_seD = _jackknifeSE(@diversities);
    return($_seD);
}

=pod 

B<_create_alpha_mask>

 Title   : _create_alpha_mask
 Usage   : _create_alpha_mask();
 Function: Creates a binary mask (1 = valid for pairwise comparisons; 0 = invalid) 
             corresponding to all symbols, dependent on the comparison_type input.
             Calls _define_valid_positions in case the valid positions should be
             refined for complete_del comparison type.                
 Returns : 1
 Args    : None
 Calls   : _define_valid_positions
 
=cut

sub _create_alpha_mask {
#print $_comparison_type, "\n";
    foreach my $res (@_residues) {$_alpha_mask{$res} = 1}

    if(!defined($_comparison_type)) {
        $_comparison_type = 'base_base';
        @_alpha_mask{$_gap, $_null, $_end} = (0,0,0);
    }
     elsif($_comparison_type eq 'base_base') {
        @_alpha_mask{$_gap, $_null, $_end} = (0,0,0);
    }
    elsif($_comparison_type eq 'gap_base') {
        @_alpha_mask{$_gap, $_null, $_end} = (1,0,0);
    }
    elsif($_comparison_type eq 'complete_del') {
        $_gap_threshold  = 0;
        $_null_threshold = 0;
        $_end_threshold  = 0;
        $_comparison_type = 'base_base';
        @_alpha_mask{$_gap, $_null, $_end} = (0,0,0);
    }    
    else {
        croak("Unknown comparison type: '$_comparison_type'");
    }
    _define_valid_positions();
    return(1);
}

# ----------------------------------
# math functions
# ----------------------------------

=pod 

B<_choose_2>

 Title   : _choose_2
 Usage   : _choose_2($number_of_pairs);
 Function: A simplified binomial coefficient calculation - the number of ways of 
             choosing k outcomes from n possibilities, where k = 2.              
 Returns : the value of the binomial coefficient
 Args    : the number of possibilities, n
 
=cut

sub _choose_2 {
    my $n = shift;
    return($n * ($n - 1) / 2);
}

=pod 

B<_jackknifeSE>

 Title   : _jackknifeSE
 Usage   : _jackknifeSE(@diversity_values);
 Function: Calculates the standard error based on jackknife resampling             
 Returns : the standard error
 Args    : an array of values obtained from the iterative jackknife leave-one-out process
 Calls   : _mean
 
=cut

sub _jackknifeSE {
    my @values = @_;
    my $n = scalar(@values);
      my $jack_mean = _mean(@values);
      my $jack_sum;
      for (my $i = 0; $i < $n; $i++) {
          $jack_sum += ($values[$i] - $jack_mean)**2;
      }
      my $jack_se = sqrt((($n - 1) / $n) * $jack_sum);
  
      return($jack_se);
}

=pod 

B<_mean>
    
 Title   : _mean
 Usage   : _mean(@values);
 Function: Calculates the mean of an array of values            
 Returns : the mean
 Args    : an array of values 
 
=cut
    
sub _mean {
    my @values = @_;
    unless(scalar(@values)) { return undef }
    my $sum;
    map{$sum += $_} @values;
    my $mean = $sum / scalar(@values);
    return($mean);
}

# ----------------------------------
# setters and getters
# ----------------------------------

=pod 

B<gap_threshold>

 Title   : gap_threshold
 Usage   : $fastAPD_obj->gap_threshold(0.1) or $fastAPD_obj->gap_threshold();
 Function: If an argument is provided, this function sets the gap threshold. 
            Returns the gap threshold.            
 Returns : the gap threshold
 Args    : optional value for setting the gap threshold 
 
=cut

sub gap_threshold {
    my $self = shift;
    my $set_thresh = shift;
    if ($set_thresh) {$_gap_threshold = $set_thresh}
    return($_gap_threshold);
}

=pod 

B<null_threshold>

 Title   : null_threshold
 Usage   : $fastAPD_obj->null_threshold(0.1) or $fastAPD_obj->null_threshold();
 Function: If an argument is provided, this function sets the null threshold. 
            Returns the null threshold.            
 Returns : the null threshold
 Args    : optional value for setting the null threshold 
 
=cut

sub null_threshold {
    my $self = shift;
    my $set_thresh = shift;
    if ($set_thresh) {$_null_threshold = $set_thresh}
    return($_null_threshold);
}

=pod 

B<end_threshold>

 Title   : end_threshold
 Usage   : $fastAPD_obj->end_threshold(0.1) or $fastAPD_obj->end_threshold();
 Function: If an argument is provided, this function sets the ragged end threshold. 
            Returns the ragged end threshold.            
 Returns : the ragged end threshold
 Args    : optional value for setting the ragged end threshold 
 
=cut

sub end_threshold {
    my $self = shift;
    my $set_thresh = shift;
    if ($set_thresh) {$_end_threshold = $set_thresh}
    return($_end_threshold);
}

=pod 

B<n_reads>

 Title   : n_reads
 Usage   : $fastAPD_obj->n_reads();
 Function: Returns the number of reads in the input alignment            
 Returns : the number of reads
 Args    : none
 
=cut

sub n_reads {
    my $self=shift;
    return $_K;
}

=pod 

B<n_valid_positions>

 Title   : n_valid_positions
 Usage   : $fastAPD_obj->n_valid_positions();
 Function: Returns the number of positions in the alignment which meet the analysis 
           criteria         
 Returns : the number of valid positions
 Args    : none
 
=cut

sub n_valid_positions {
    my $self=shift;
    my $size = @_valid_positions;
    return $size;
}

=pod 

B<valid_positions>

 Title   : valid_positions
 Usage   : $fastAPD_obj->valid_positions();
 Function: Returns an array reference to the positions in the alignment which meet 
           the analysis criteria      
 Returns : an array reference to the valid positions 
 Args    : none
 
=cut

sub valid_positions {
    my $self=shift;
    my @vp = @_valid_positions;
    return \@vp;
}

=pod 

B<width>

 Title   : width
 Usage   : $fastAPD_obj->width();
 Function: Returns the width of the alignment   
 Returns : the width of the alignment   
 Args    : none

=cut

sub width {
    my $self=shift;
    return $_W;
}

=pod 

B<freqs>

 Title   : freqs
 Usage   : $fastAPD_obj->freqs();
 Function: Returns frequencies of each symbol at each position   
 Returns : a reference to an array containing frequencies of each symbol at each position    
 Args    : none

=cut

sub freqs {
    my $self=shift;
    my (@freq_array, @_curr_freqs);
    push(@freq_array, join("\t",@_alphabet));
    
    for (my $pos = 0; $pos < $_W; $pos++){
        foreach my $symbol (@_alphabet) {
            push(@_curr_freqs, $_freq[$pos]{$symbol});
        }
        push(@freq_array, join("\t", @_curr_freqs));
        @_curr_freqs = ();
    }
    return \@freq_array;
}

# -----------------------------------------------------
# consensus sequences
# -----------------------------------------------------

=pod 

B<consensus_alignment>

 Title   : consensus_alignment
 Usage   : $fastAPD_obj->consensus_alignment();
 Function: Returns a consensus sequence based on the aligned reads  
 Returns : a consensus sequence based on the aligned reads      
 Args    : none
 Calls   : _calculate_aligned_consensus

=cut

sub consensus_alignment {
    my $self;
    return _calculate_aligned_consensus();
}

=pod 

B<_calculate_aligned_consensus>

 Title   : _calculate_aligned_consensus
 Usage   : _calculate_aligned_consensus();
 Function: Creates a consensus sequence by calling _argmax to detect the most
             frequent symbol at each position in the alignment
 Returns : a consensus sequence based on the aligned reads      
 Args    : none
 Calls   : _argmax

=cut

sub _calculate_aligned_consensus {
    my $seq_string='';
    for(my $i=0; $i < $_W; $i++) {
        my $symbol;
        $symbol = _argmax($_freq[$i]);
        $seq_string .= $symbol;
    }
    return $seq_string;
}

=pod 

B<_argmax>

 Title   : _argmax
 Usage   : _argmax($_freq[$i]);
 Function: Detects the most frequently occurring symbol at a position
 Returns : the most frequently occurring symbol      
 Args    : a hash containing the frequencies of each symbol at a given position

=cut

sub _argmax {
    my $freqs = shift;
    my $argmax = ' '; 
    my $max   = -1;
    foreach my $symbol ($_end, $_gap, $_null, @_residues) {
        if($freqs->{$symbol} >= $max) {
            $max = $freqs->{$symbol};
            if ($symbol eq '#') {$argmax = '-'}
            else {$argmax = $symbol}
        }
    }
    return $argmax;
}

1;


__END__


