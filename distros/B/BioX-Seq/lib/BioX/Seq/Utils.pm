package BioX::Seq::Utils;

use v5.10.1;

use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT_OK = qw/
    build_ORF_regex
    all_orfs
    rev_com
    is_nucleic
/;

sub build_ORF_regex {

    my ($mode, $min_len) = @_;

    die "Missing mode"
        if (! defined $mode);
    die "Missing minimum length"
        if (! defined $min_len);
    
    # mode 0 : any set of codons not STOP
    # mode 1 : must end with STOP codon
    # mode 2 : must start with START codon
    # mode 3 : START -> STOP


    my $aasize = int($min_len/3);
    my $tail_size = $aasize - 1 - ($mode & 0x2 ? 1 : 0);
    my $codon = ".{3}";
    my $first_codon = $mode & 0x2 ? 'A[TU]G' : '';
    my $stop_codon = "[TU](?:AA|AG|GA|AR|RA)";
    my $last_codon  = $mode & 0x1 ? $stop_codon : '';
    my $re_orf = qr/
        \G                    # anchor at pos() - forces codon boundaries
        (?:$codon)*?          # discard codons before start codon
        (                     # begin matching ORF
        $first_codon          # match start codon
            (?! $stop_codon ) # (but only if not followed by stop codon)
        (?: $codon           # match codon(s)
            (?! $stop_codon ) # (but only if not followed by stop codon)
        ) {$tail_size,}       # any only if >= $tail_size codons long
        $codon                # add final codon
        )                     # end matching ORF
        $last_codon
    /ix;

    return $re_orf;

}

sub all_orfs {

    my ($seq, $mode, $min_len) = @_;

    my $orf_re = build_ORF_regex($mode, $min_len);

    my $len  = length $seq;
    my @orfs;
    for my $strand (0..1) {
        my $str = $strand ? rev_com($seq) : $seq;
        for my $frame (0..2) {
            pos($str) = $frame;
            while ($str =~ /$orf_re/g) {
                my ($s, $e) = map {$strand ? $len-$_+1 : $_} ($-[1]+1, $+[1]);
                push @orfs, [$1, $s, $e];
            }
        }
    }

    return @orfs;

}

sub is_nucleic {

    my ($seq) = @_;
    return $seq !~ /[^ACGTUMRWSYKVHDBN.-]/i;

}

sub rev_com {

    my ($seq) = @_;
    $seq =~ tr/Xx/Nn/;
    die "Bad input sequence" if (! is_nucleic($seq));
    $seq = reverse $seq;
    $seq =~ tr
        {ACGTMRWSYKVHDBNacgtmrwsykvhdbn}
        {TGCAKYWSRMBDHVNtgcakywsrmbdhvn};

    return $seq;

}

1;


__END__

=head1 NAME

BioX::Seq::Utils - miscellaneous sequence-related functions

=head1 SYNOPSIS

    if ( is_nucleic($seq) ) {
        $seq = rev_com( $seq );
    }

    my @orfs = all_orfs(
        $seq,
        3,   # ORF mode
        200, # min length
    );

    my $re = build_ORF_regex(
        0,   # ORF mode
        300, # min length
    );
        

=head1 DESCRIPTION

C<BioX::Seq::Utils> contain a number of sequence-related functions. They are
general functions that are used often enough to warrant inclusion in a library
but not often enough to warrant addition to the core C<BioX::Seq> class. They
may also include commonly-used functions that do not make sense to include as
C<BioX::Seq> methods, as well as functions that mirror C<BioX::Seq> methods but
can be used on raw strings. They act on simple scalars and arrays rather
than objects.

NOTE: Use of this module is considered deprecated. It is retained within the
<BioX::Seq> package as a number of existing software tools rely on it, but at
some point in the future these functions will likely find a new home
elsewhere.

=head1 FUNCTIONS

=head2 rev_com

    my $re = rev_com($seq);

Takes a single scalar argument and returns a scalar containing the reverse
complement. Throws an exception if the input value doesn't look like a nucleic
acid sequence.

=head2 is_nucleic

    if ( is_nucleic($seq) ) {
        # do something
    }

Takes a single scalar argument and returns a boolean value indicating whether
the scalar "looks like" a nucleic acid string (i.e. contains no characters but
valid IUPAC nucleic acid codes).

=head2 all_orfs

    my @orfs = all_orfs(
        $seq,
        2,   # ORF mode
        100, # min length
    );
    for my $orf (@orfs) {
        my ($seq, $start, $end) = @{$orf};
    }

Takes one required argument (a sequence string) and two optional arguments
(ORF mode and minimum length) and returns an array of array references
representing all ORFs in all reading frames of the sequence. Each reference
contains three values: the sequence, the start position, and the stop
position. The strand can be determined by comparing start and stop position
(ORFs on the reverse strand will have start > stop). See C<build_ORF_regex()>
for an explanation for the possible values for ORF mode.

=head2 build_ORF_regex

    my $re = build_ORF_regex(
        3,
        300,
    );

Builds a regular expression for matching opening reading frames in a
nucleic acid sequence string. Takes two required arguments that are used for
building the regular expression:

=over 1

=item * mode - an integer from 0-3 defining the type of open reading frame
detected.

=over 1

=item * 0 - any set of codons not containing a start codon

=item * 1 - must end with stop codon

=item * 2 - must begin with start codon

=item * 3 - must begin with start codon and end with stop codon

=back

=item * C min_len - an integer representing the minimum number of nucleic
acids an open reading frame must contain to be returned (not including the
stop codon)

=back

The return value is a compiled expression that can be used to search a
sequence string. The C<pos()> function should be used on the string to set
the frame to be searched (0-2) prior to applying the regex.


=head1 CAVEATS AND BUGS

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jeremy *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

