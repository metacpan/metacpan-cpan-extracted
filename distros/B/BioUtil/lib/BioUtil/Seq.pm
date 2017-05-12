package BioUtil::Seq;

require Exporter;
@ISA    = (Exporter);
@EXPORT = qw(
    FastaReader
    read_sequence_from_fasta_file
    write_sequence_to_fasta_file
    format_seq

    validate_sequence
    complement
    revcom
    base_content
    degenerate_seq_to_regexp
    match_regexp
    dna2peptide
    codon2aa
    generate_random_seqence

    shuffle_sequences
    rename_fasta_header
    clean_fasta_header
);

use vars qw($VERSION);

use 5.010_000;
use strict;
use warnings FATAL => 'all';

use List::Util qw(shuffle);

=head1 NAME

BioUtil::Seq - Utilities for sequence

Some great modules like BioPerl provide many robust solutions. 
However, it is not easy to install for someone in some platforms.
And for some simple task scripts, a lite module may be a good choice.
So I reinvented some wheels and added some useful utilities into this module,
hoping it would be helpful.

=head1 VERSION

Version 2015.0309

=cut

our $VERSION = 2015.0728;

=head1 EXPORT

    FastaReader
    read_sequence_from_fasta_file 
    write_sequence_to_fasta_file 
    format_seq

    validate_sequence 
    complement
    revcom 
    base_content 
    degenerate_seq_to_regexp
    match_regexp
    dna2peptide 
    codon2aa 
    generate_random_seqence

    shuffle_sequences 
    rename_fasta_header 
    clean_fasta_header 

=head1 SYNOPSIS

  use BioUtil::Seq;


=head1 SUBROUTINES/METHODS


=head2 FastaReader

FastaReader is a fasta file parser using closure.
FastaReader returns an anonymous subroutine, when called, it
return a fasta record which is reference of an array
containing fasta header and sequence.

FastaReader could also read from STDIN when the file name is "STDIN" or "stdin".

A boolean argument is optional. If set as "true", spaces including blank, tab, 
"return" ("\r") and "new line" ("\n") symbols in sequence will not be trimed.

FastaReader speeds up by utilizing the special Perl variable $/ (set to "\n>"),
with kind help of Mario Roy, author of MCE 
(https://code.google.com/p/many-core-engine-perl/). A lot of optimizations were
also done by him.

Example:

   # do not trim the spaces and \n
   # $not_trim = 1;
   # my $next_seq = FastaReader("test.fa", $not_trim);
   
   # read from STDIN
   # my $next_seq = FastaReader('STDIN');
   
   # read from file
   my $next_seq = FastaReader("test.fa");

   while ( my $fa = &$next_seq() ) {
       my ( $header, $seq ) = @$fa;

       print ">$header\n$seq\n";
   }

=cut

sub FastaReader {
    my ( $file, $not_trim ) = @_;

    my ( $open_flg, $finished ) = ( 0, 0 );
    my ( $fh, $pos, $head ) = (undef) x 3;

    if ( $file =~ /^STDIN$/i ) {    # from stdin
        $fh = *STDIN;
    }
    elsif ( ref $file eq '' or ref $file eq 'SCALAR' ) {    # from file
        open $fh, '<', $file or die "fail to open file: $file!\n";
        $open_flg = 1;
    }
    else {    # glob, i.e. given file handler
        $fh = $file;
    }

    local $/ = \1;     ## read one byte
    while (<$fh>) {    ## until reaching ">"
        last if $_ eq '>';
    }
    return sub {
        return if $finished;

        local $/ = "\n>";    ## set input record separator
        while (<$fh>) {
            ## trim trailing ">", part of $/. faster than s/\r?\n>$//
            substr( $_, -1, 1, '' ) if substr( $_, -1, 1 ) eq '>';

            ## extract header and sequence
            # faster than  ( $head, $seq ) = split( /\n/, $_, 2 );
            $pos = index( $_, "\n" ) + 1;
            $head = substr( $_, 0, $pos - 1 );

            # $_ becomes sequence, to save memory
            # $seq = substr( $_, $pos );
            substr( $_, 0, $pos, '' );

            ## trim trailing "\r" in header
            chop $head if substr( $head, -1, 1 ) eq "\r";

            if ( length $head > 0 ) {

                # faster than $seq =~ s/\s//g unless $not_trim;
                # $seq =~ tr/\t\r\n //d unless $not_trim;
                $_ =~ tr/\t\r\n //d unless $not_trim;
                return [ $head, $_ ];
            }
        }

        close $fh if $open_flg;
        $finished = 1;
        return;
    };
}

sub FastaReader_old {
    my ( $file, $not_trim ) = @_;

    my ( $last_header, $seq_buffer ) = ( '', '' ); # buffer for header and seq
    my ( $header,      $seq )        = ( '', '' ); # current header and seq
    my $finished = 0;

    my ( $fh, $is_stdin ) = ( undef, 0 );
    if ( $file =~ /^STDIN$/i ) {
        ( $fh, $is_stdin ) = ( *STDIN, 1 );
    }
    else {
        open $fh, "<", $file or die "fail to open file: $file!\n";
    }

    return sub {
        return undef if $finished;                 # end of file

        while (<$fh>) {
            s/^\s+//;    # remove the space at the front of line

            if (/^>(.*)/) {    # header line
                ( $header, $last_header ) = ( $last_header, $1 );
                ( $seq,    $seq_buffer )  = ( $seq_buffer,  '' );

                # only output fasta records with non-blank header
                if ( $header ne '' ) {
                    $seq =~ s/\s+//g unless $not_trim;
                    return [ $header, $seq ];
                }
            }
            else {
                $seq_buffer .= $_;    # append seq
            }
        }
        close $fh unless $is_stdin;
        $finished = 1;

        # last record. only output fasta records with non-blank header
        if ( $last_header ne '' ) {
            $seq_buffer =~ s/\s+//g unless $not_trim;
            return [ $last_header, $seq_buffer ];
        }
    };
}

=head2 read_sequence_from_fasta_file

Read all sequences from fasta file.

Example:

    my $seqs = read_sequence_from_fasta_file($file);
    for my $header (keys %$seqs) {
        my $seq = $$seqs{$header};
        print ">$header\n$seq\n";
    }

=cut

sub read_sequence_from_fasta_file {
    my ( $file, $not_trim ) = @_;
    my $seqs = {};

    my $next_seq = FastaReader( $file, $not_trim );
    while ( my $fa = &$next_seq() ) {

        # my ( $header, $seq ) = @$fa;
        # $$seqs{$header} = $seq;
        $$seqs{ $fa->[0] } = $fa->[1];
    }

    return $seqs;
}

=head2 write_sequence_to_fasta_file

Example:

    my $seq = {"seq1" => "acgagaggag"};
    write_sequence_to_fasta_file($seq, "seq.fa");

=cut

sub write_sequence_to_fasta_file {
    my ( $seqs, $file, $n ) = @_;
    unless ( ref $seqs eq 'HASH' ) {
        warn "seqs should be reference of hash\n";
        return 0;
    }
    $n = 70 unless defined $n;

    open my $fh2, ">$file" or die "failed to write to $file\n";
    for ( keys %$seqs ) {
        print $fh2 ">$_\n", format_seq( $$seqs{$_}, $n ), "\n";
    }
    close $fh2;
}

=head2 format_seq

Format sequence to readable text

Example:

    printf ">%s\n%s", $head, format_seq($seq, 60);

=cut

sub format_seq {
    my ( $s, $n ) = @_;
    $n = 70 unless defined $n;
    unless ( $n =~ /^\d+$/ and $n > 0 ) {
        warn "n should be positive integer\n";
        return $s;
    }

    my $s2 = '';
    my ( $j, $int );
    $int = int( ( length $s ) / $n );
    for ( $j = 0; $j <= $int; $j++ ) {
        $s2 .= substr( $s, $j * $n, $n ) . "\n";
    }
    return $s2;
}

=head2 validate_sequence

Validate a sequence.

Legale symbols:

    DNA: ACGTRYSWKMBDHV
    RNA: ACGURYSWKMBDHV
    Protein: ACDEFGHIKLMNPQRSTVWY
    gap and space: - *.

Example:

    if (validate_sequence($seq)) {
        # do some thing
    }

=cut

sub validate_sequence {
    my ($seq) = @_;
    return 0 if $seq =~ /[^\.\-\s_*ABCDEFGHIKLMNPQRSTUVWY]/i;
    return 1;
}

=head2 complement

Complement sequence

IUPAC nucleotide code: ACGTURYSWKMBDHVN

http://droog.gs.washington.edu/parc/images/iupac.html

    code    base    Complement
    A   A   T
    C   C   G
    G   G   C
    T/U T   A

    R   A/G Y
    Y   C/T R
    S   C/G S
    W   A/T W
    K   G/T M
    M   A/C K

    B   C/G/T   V
    D   A/G/T   H
    H   A/C/T   D
    V   A/C/G   B

    X/N A/C/G/T X
    .   not A/C/G/T
     or-    gap

my $comp = complement($seq);

=cut

sub complement {
    my ($s) = @_;
    $s
        =~ tr/ACGTURYMKSWBDHVNacgturymkswbdhvn/TGCAAYRKMSWVHDBNtgcaayrkmswvhdbn/;
    return $s;
}

=head2 revcom

Reverse complement sequence

my $recom = revcom($seq);

=cut

sub revcom {
    my $rc = reverse complement( $_[0] );
    return $rc;
}

=head2 base_content

Example:

    my $gc_cotent = base_content('gc', $seq);

=cut

sub base_content {
    my ( $bases, $seq ) = @_;
    if ( $seq eq '' ) {
        return 0;
    }

    my $sum = 0;
    $sum += $seq =~ s/$_/$_/ig for split "", $bases;
    return sprintf "%.4f", $sum / length $seq;
}

=head2 degenerate_seq_to_regexp

Translate degenerate sequence to regular expression

=cut

sub degenerate_seq_to_regexp {
    my ($seq) = @_;
    my %bases = (
        'A' => 'A',
        'T' => 'T',
        'U' => 'U',
        'C' => 'C',
        'G' => 'G',
        'R' => '[AG]',
        'Y' => '[CT]',
        'M' => '[AC]',
        'K' => '[GT]',
        'S' => '[CG]',
        'W' => '[AT]',
        'H' => '[ACT]',
        'B' => '[CGT]',
        'V' => '[ACG]',
        'D' => '[AGT]',
        'N' => '[ACGT]',
    );
    return join '', map { exists $bases{$_} ? $bases{$_} : $_ }
        split //, uc $seq;
}

=head2 match_regexp

Find all sites matching the regular expression.

See https://github.com/shenwei356/bio_scripts/blob/master/sequence/fasta_locate_motif.pl

=cut

sub match_regexp {
    my ( $r, $s ) = @_;
    my @matched = ();
    my $pos     = -1;
    while ( $s =~ /($r)/ig ) {
        $pos = pos $s;

        # return start, end, matched string
        # start and end are 0-based
        push @matched, [ $pos - length($1), $pos - 1, $1 ];
        pos $s = $pos - length($1) + 1;
    }
    return \@matched;
}

=head2 dna2peptide

Translate DNA sequence into a peptide

=cut

sub dna2peptide {
    my ($dna) = @_;
    my $protein = '';

   # Translate each three-base codon to an amino acid, and append to a protein
    for ( my $i = 0; $i < ( length($dna) - 2 ); $i += 3 ) {
        $protein .= codon2aa( substr( $dna, $i, 3 ) );
    }
    return $protein;
}

=head2 codon2aa

Translate a DNA 3-character codon to an amino acid

=cut

sub codon2aa {
    my ($codon) = @_;
    $codon = uc $codon;
    my %genetic_code = (
        'TCA' => 'S',    # Serine
        'TCC' => 'S',    # Serine
        'TCG' => 'S',    # Serine
        'TCT' => 'S',    # Serine
        'TTC' => 'F',    # Phenylalanine
        'TTT' => 'F',    # Phenylalanine
        'TTA' => 'L',    # Leucine
        'TTG' => 'L',    # Leucine
        'TAC' => 'Y',    # Tyrosine
        'TAT' => 'Y',    # Tyrosine
        'TAA' => '_',    # Stop
        'TAG' => '_',    # Stop
        'TGC' => 'C',    # Cysteine
        'TGT' => 'C',    # Cysteine
        'TGA' => '_',    # Stop
        'TGG' => 'W',    # Tryptophan
        'CTA' => 'L',    # Leucine
        'CTC' => 'L',    # Leucine
        'CTG' => 'L',    # Leucine
        'CTT' => 'L',    # Leucine
        'CCA' => 'P',    # Proline
        'CCC' => 'P',    # Proline
        'CCG' => 'P',    # Proline
        'CCT' => 'P',    # Proline
        'CAC' => 'H',    # Histidine
        'CAT' => 'H',    # Histidine
        'CAA' => 'Q',    # Glutamine
        'CAG' => 'Q',    # Glutamine
        'CGA' => 'R',    # Arginine
        'CGC' => 'R',    # Arginine
        'CGG' => 'R',    # Arginine
        'CGT' => 'R',    # Arginine
        'ATA' => 'I',    # Isoleucine
        'ATC' => 'I',    # Isoleucine
        'ATT' => 'I',    # Isoleucine
        'ATG' => 'M',    # Methionine
        'ACA' => 'T',    # Threonine
        'ACC' => 'T',    # Threonine
        'ACG' => 'T',    # Threonine
        'ACT' => 'T',    # Threonine
        'AAC' => 'N',    # Asparagine
        'AAT' => 'N',    # Asparagine
        'AAA' => 'K',    # Lysine
        'AAG' => 'K',    # Lysine
        'AGC' => 'S',    # Serine
        'AGT' => 'S',    # Serine
        'AGA' => 'R',    # Arginine
        'AGG' => 'R',    # Arginine
        'GTA' => 'V',    # Valine
        'GTC' => 'V',    # Valine
        'GTG' => 'V',    # Valine
        'GTT' => 'V',    # Valine
        'GCA' => 'A',    # Alanine
        'GCC' => 'A',    # Alanine
        'GCG' => 'A',    # Alanine
        'GCT' => 'A',    # Alanine
        'GAC' => 'D',    # Aspartic Acid
        'GAT' => 'D',    # Aspartic Acid
        'GAA' => 'E',    # Glutamic Acid
        'GAG' => 'E',    # Glutamic Acid
        'GGA' => 'G',    # Glycine
        'GGC' => 'G',    # Glycine
        'GGG' => 'G',    # Glycine
        'GGT' => 'G',    # Glycine
    );

    if ( exists $genetic_code{$codon} ) {
        return $genetic_code{$codon};
    }
    else {
        print STDERR "Bad codon \"$codon\"!!\n";
        exit;
    }
}

=head2 generate_random_seqence

Example:

    my @alphabet = qw/a c g t/;
    my $seq = generate_random_seqence( \@alphabet, 50 );

=cut

sub generate_random_seqence {
    my ( $alphabet, $length ) = @_;
    unless ( ref $alphabet eq 'ARRAY' ) {
        warn "alphabet should be ref of array\n";
        return 0;
    }

    my $n = @$alphabet;
    my $seq;
    $seq .= $$alphabet[ int rand($n) ] for ( 1 .. $length );
    return $seq;
}

=head2 shuffle sequences

Example:

    shuffle_sequences($file, "$file.shuf.fa");

=cut

sub shuffle_sequences {
    my ( $file, $file_out, $not_trim ) = @_;
    my $seqs = read_sequence_from_fasta_file( $file, $not_trim );
    my @keys = shuffle( keys %$seqs );

    $file_out = "$file.shuffled.fa" unless defined $file_out;
    open my $fh2, ">$file_out" or die "fail to write file $file_out\n";
    print $fh2 ">$_\n$$seqs{$_}\n" for @keys;
    close $fh2;

    return $file_out;
}

=head2 rename_fasta_header

Rename fasta header with regexp.

Example:
    
    # delete some symbols
    my $n = rename_fasta_header('[^a-z\d\s\-\_\(\)\[\]\|]', '', $file, "$file.rename.fa");
    print "$n records renamed\n";

=cut

sub rename_fasta_header {
    my ( $regex, $repalcement, $file, $outfile ) = @_;

    open my $fh,  "<", $file    or die "fail to open file: $file\n";
    open my $fh2, ">", $outfile or die "fail to wirte file: $outfile\n";

    my $head = '';
    my $n    = 0;
    while (<$fh>) {
        if (/^\s*>(.*)\r?\n/) {
            $head = $1;
            if ( $head =~ /$regex/ ) {
                $head =~ s/$regex/$repalcement/g;
                $n++;
            }
            print $fh2 ">$head\n";
        }
        else {
            print $fh2 $_;
        }
    }
    close $fh;
    close $fh2;

    return $n;
}

=head2 clean_fasta_header

Rename given symbols to repalcement string. 
Because, some symbols in fasta header will cause unexpected result.

Example:

    my  $file = "test.fa";
    my $n = clean_fasta_header($file, "$file.rename.fa");
    # replace any symbol in (\/:*?"<>|) with '', i.e. deleting.
    # my $n = clean_fasta_header($file, "$file.rename.fa", '',  '\/:*?"<>|');
    print "$n records renamed\n";

=cut

sub clean_fasta_header {
    my ( $file, $outfile, $replacement, $symbols ) = @_;
    $replacement = "_" unless defined $replacement;

    my @default = split //, '\/:*?"<>|';
    $symbols = \@default unless defined $symbols;
    unless ( ref $symbols eq 'ARRAY' ) {
        warn "symbols should be ref of array\n";
        return 0;
    }
    my $re = join '', map { quotemeta $_ } @$symbols;
    open my $fh,  "<", $file    or die "fail to open file: $file\n";
    open my $fh2, ">", $outfile or die "fail to wirte file: $outfile\n";

    my $head = '';
    my $n    = 0;
    while (<$fh>) {
        if (/^\s*>(.*)\r?\n/) {
            $head = $1;
            if ( $head =~ /[$re]/ ) {
                $head =~ s/[$re]/$replacement/g;
                $n++;
            }
            print $fh2 ">$head\n";
        }
        else {
            print $fh2 $_;
        }
    }
    close $fh;
    close $fh2;

    return $n;
}

1;
