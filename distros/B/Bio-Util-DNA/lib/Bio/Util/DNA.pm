=head1 NAME

Bio::Util::DNA - Basic DNA utilities

=head1 SYNOPSES

    use Bio::Util::DNA qw(:all);

    my $clean_ref = cleanDNA($seq_ref);
    my $seq_ref = randomDNA(100);
    my $rev_ref = reverse_complement($seq_ref);

=head1 DESCRIPTION

Provides a set of functions and predefined variables which are handy when
working with DNA.

=cut

package Bio::Util::DNA;

use strict;
use warnings;

use version; our $VERSION = qv('0.2.1');

use Exporter 'import';

our %EXPORT_TAGS;
$EXPORT_TAGS{funcs} = [
    qw(
      cleanDNA
      randomDNA
      unrollDNA
      reverse_complement
      )
];
$EXPORT_TAGS{all} = [
    @{ $EXPORT_TAGS{funcs} },
    qw(
      $DNAs
      @DNAs
      $DNA_match
      $DNA_fail

      $RNAs
      @RNAs
      $RNA_match
      $RNA_fail

      $degenerates
      @degenerates
      $degenerate_match
      $degenerate_fail

      $all_nucleotides
      @all_nucleotides
      $all_nucleotide_match
      $all_nucleotide_fail

      %degenerate2nucleotides
      %nucleotides2degenerate
      %degenerate_hierarchy
      )
];

our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

=head1 VARIABLES

=head2 BASIC VARIABLES

Basic nucleotide variables that could be useful. All of the variables have a
prefix and a suffix;

=head3 Prefixes

=over

=item DNA [ACGT]

=item RNA [ACGU]

=item degenerate

=item all_nucleotide

=back

=head3 Suffixes

=over

=item ${prefix}s

String of the different nucleotides

=item @{prefix}s

Array of the different nucleotides

=item ${prefix}_match

Precompiled regular expression which matches nucleotide characters

=item ${prefix}_fail

Precompiled regular expression which matches non-nucleotide characters

=back

=cut

our $DNAs      = 'ACGT';
our @DNAs      = split //, $DNAs;
our $DNA_match = qr/[$DNAs]/i;
our $DNA_fail  = qr/[^$DNAs]/i;

our $RNAs      = 'ACGU';
our @RNAs      = split //, $RNAs;
our $RNA_match = qr/[$RNAs]/i;
our $RNA_fail  = qr/[^$RNAs]/i;

our $degenerates      = 'BDHKMNRSVWY';
our @degenerates      = split //, $degenerates;
our $degenerate_match = qr/[$degenerates]/i;
our $degenerate_fail  = qr/[^$degenerates]/i;

our $all_nucleotides      = 'ACGTUBDHKMNRSVWY';
our @all_nucleotides      = split //, $all_nucleotides;
our $all_nucleotide_match = qr/[$all_nucleotides]/i;
our $all_nucleotide_fail  = qr/[^$all_nucleotides]/i;

=head2 %degenerate2nucleotides

Hash of degenerate nucleotide definitions. Each entry contains a reference to
an array of DNA nucleotides that each degenerate nucleotide stands for.

=cut

our %degenerate2nucleotides = (
    N => [qw( A C G T )],
    B => [qw(   C G T )],    # !A
    D => [qw( A   G T )],    # !C
    H => [qw( A C   T )],    # !G
    V => [qw( A C G   )],    # !T
    M => [qw( A C     )],    # aroMatic
    R => [qw( A   G   )],    # puRine
    W => [qw( A     T )],
    S => [qw(   C G   )],
    Y => [qw(   C   T )],    # pYrimidine
    K => [qw(     G T )]     # Keto
);

=head2 %nucleotides2degenerate

Reverse of %degenerate2nucleotides. Keys are alphabetically-sorted DNA
nucleotides and values are the degenerate nucleotide that can represent those
nucleotides.

=cut

our %nucleotides2degenerate = (
    ACGT => 'N',
    CGT  => 'B',
    AGT  => 'D',
    ACT  => 'H',
    ACG  => 'V',
    AC   => 'M',
    AG   => 'R',
    AT   => 'W',
    CG   => 'S',
    CT   => 'Y',
    GT   => 'K'
);

=head2 %degenerate_hierarchy

Contains the heirarchy of degenerate nucleotides; N of course contains all the
other degenerates, and the four degenerates that can stand for three different
bases contain three of the two-base degenerates.

=cut

our %degenerate_hierarchy = (
    N => [qw( M R W S Y K   V H D B )],
    B => [qw(       S Y K )],             # !A = [CG],[CT],[GT]
    D => [qw(   R W     K )],             # !C = [AT],[AG],[GT]
    H => [qw( M   W   Y   )],             # !G = [AC],[AT],[CT]
    V => [qw( M R   S     )]              # !T = [AC],[AG],[CG]
);

=head1 FUNCTIONS

=head2 cleanDNA

    my $clean_ref = cleanDNA($seq_ref);

Cleans the sequence for use. Strips out comments (lines starting with '>') and
whitespace, converts uracil to thymine, and capitalizes all characters.

Examples:

    my $clean_ref = cleanDNA($seq_ref);

    my $seq_ref = cleanDNA(\'actg');
    my $seq_ref = cleanDNA(\'act tag cta');
    my $seq_ref = cleanDNA(\'>some mRNA
                             acugauauagau
                             uauagacgaucc');

=cut

sub cleanDNA {
    my $seq_ref = shift;

    my $clean = uc $$seq_ref;
    $clean =~ s/^>.*//m;
    $clean =~ s/$all_nucleotide_fail+//g;
    $clean =~ tr/U/T/;

    return \$clean;
}

=head2 randomDNA

    my $seq_ref = randomDNA($length);

Generate random DNA for testing this module or your own scripts. Default length
is 100 nucleotides.

Example:

    my $seq_ref = randomDNA();
    my $seq_ref = randomDNA(600);

=cut

sub randomDNA {
    my $length = shift;
    $length = $length || 100;

    my $seq;
    $seq .= int rand 4 while ( $length-- > 0 );
    $seq =~ tr/0123/ACGT/;

    return \$seq;
}

=head2 reverse_complement

=head2 rev_comp

    my $reverse_ref = reverse_complement($seq_ref);

Finds the reverse complement of the sequence and handles degenerate
nucleotides.

Example:

    $reverse_ref = reverse_complement(\'act');

=cut

sub reverse_complement {
    my $seq_ref = shift;

    my $reverse = reverse $$seq_ref;
    $reverse =~ tr/acgtmrykvhdbnACGTMRYKVHDBN/tgcakyrmbdhvnTGCAKYRMBDHVN/;

    return \$reverse;
}

=head2 unrollDNA

    my $seq_arrayref = unrollDNA( $seq_ref );

Unroll a DNA string containing degenerate nucleotides. The first entry of the
arrayref will be the actual sequence. 

Example:

    my $seq_arrayref = unrollDNA( \'ACSTAD' ) =
        [
            'ACSTAD', 'ACCTAD', 'ACGTAD',
            'ACSTAR', 'ACCTAR', 'ACGTAR',
            'ACSTAW', 'ACCTAW', 'ACGTAW',
            'ACSTAK', 'ACCTAK', 'ACGTAK',
            'ACSTAA', 'ACCTAA', 'ACGTAA',
            'ACSTAG', 'ACCTAG', 'ACGTAG',
            'ACSTAT', 'ACCTAT', 'ACGTAT'
        ]; 

=cut

sub unrollDNA {
    my ($seq_ref) = @_;

    my @nucleotides = map {
        [
            $_,
            (
                $degenerate_hierarchy{$_} ? @{ $degenerate_hierarchy{$_} }
                : ()
            ),
            (
                $degenerate2nucleotides{$_} ? @{ $degenerate2nucleotides{$_} }
                : ()
            ),
        ]
    } split //, uc $$seq_ref;

    my @possibilities = ( [ (undef) x @nucleotides ] );

    for ( my $i = 0 ; $i < @nucleotides ; $i++ ) {
        my $variants = $nucleotides[$i];
        
        push @possibilities, map {
            map { [@$_] }
              @possibilities
        } (undef) x $#$variants;

        my $block_size = @possibilities / @$variants;
        for ( my $j = 0 ; $j < @$variants ; $j++ ) {
            my $variant = $variants->[$j];
            for ( my $k = $block_size * $j; $k < $block_size * ($j + 1); $k++ ) {
                $possibilities[$k][$i] = $variant;
            }
        }
    }

    return [ map { join( '', @$_ ) } @possibilities ];
}

1;

=head1 AUTHOR

Kevin Galinsky, <first initial last name plus cpan at gmail dot com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2011, Broad Institute.

Copyright (c) 2008-2009, J. Craig Venter Institute.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
