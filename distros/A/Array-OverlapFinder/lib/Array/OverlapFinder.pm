package Array::OverlapFinder;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-25'; # DATE
our $DIST = 'Array-OverlapFinder'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(find_overlap combine_overlap);

sub _find_or_combine_overlap {
    my ($action, $seq1, $seq2, $detail) = @_;

    my @overlap_items;
    my $index_at_seq1;

  L1:
    for my $i (0 .. $#{$seq1}) {
        my $j = $i;
        while ($j <= $#{$seq1} && ($j-$i) <= $#{$seq2}) {
            if ($seq1->[$j] ne $seq2->[$j - $i]) {
                next L1;
            }
            $j++;
        }
        @overlap_items = @{$seq1}[$i .. $#{$seq1}];
        $index_at_seq1 = $i;
        last L1;
    }

    if ($action eq 'find') {
        # find
        if ($detail) { return (\@overlap_items, $index_at_seq1) } else { return @overlap_items }
    } else {
        # combine
        my @combined;
        if (defined $index_at_seq1) {
            @combined = (@$seq1, @{$seq2}[ ($#{$seq1} - $index_at_seq1 + 1) .. $#{$seq2} ]);
        } else {
            @combined = (@$seq1, @$seq2);
        }
        if ($detail) { return (\@combined, \@overlap_items, $index_at_seq1) } else { return @combined }
    }
}

sub find_overlap    { _find_or_combine_overlap('find', @_) }

sub combine_overlap { _find_or_combine_overlap('combine', @_) }

1;
# ABSTRACT: Find/remove overlapping items between two ordered sequences

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::OverlapFinder - Find/remove overlapping items between two ordered sequences

=head1 VERSION

This document describes version 0.002 of Array::OverlapFinder (from Perl distribution Array-OverlapFinder), released on 2020-12-25.

=head1 SYNOPSIS

 use Array::OverlapFinder qw(
     find_overlap
     combine_overlap
 );

 # sequence is array of strings (compared with 'eq' operator; if you have array
 # of records/structures, you can encode each record as JSON or using Data::Dmp,
 # for example)
 my @seq1 = qw(1 2 3 4 5 6);
 my @seq2 = qw(4 5 6 7 8 9);

 my @overlap_items                   = find_overlap(\@seq1, \@seq2);              # => (4, 5, 6)
 my ($overlap_items, $index_at_seq1) = find_overlap(\@seq1, \@seq2, 'detail');    # => ([4, 5, 6], 3)

 my @combined_seq                                   = combine_overlap(\@seq1, \@seq2);           # => (1, 2, 3, 4, 5, 6, 7, 8, 9)
 my ($combined_seq, $overlap_items, $index_at_seq1) = combine_overlap(\@seq1, \@seq2, 'detail'); # => ([1, 2, 3, 4, 5, 6, 7, 8, 9], [4, 5, 6], 3)

=head1 DESCRIPTION

Assuming you have two ordered sequences of items that might or might not
overlap, where the first sequence contains "earlier" items and the second
contains possibly "later" items, the functions in this module can find the
overlapping items for you or remove them combining the two sequence into one:

 # condition A, no overlaps
 sequence1: 1 2 3 4 5 6
 sequence2:              8 9 10
 overlap  :
 combined : 1 2 3 4 5 6  8 9 10

 # condition B, overlaps
 sequence1: 1 2 3 4 5 6
 sequence2:       4 5 6 7 8 9
 overlap  :       4 5 6
 combined : 1 2 3 4 5 6 7 8 9

 # condition C, overlaps
 sequence1: 1 2 3 4 5 6
 sequence2:       4 5
 overlap  : 4 5
 combined : 1 2 3 4 5 6

 # condition D, overlaps
 sequence1: 1 2 3 4 5 6
 sequence2:       4 5 6
 overlap  :       4 5 6
 combined : 1 2 3 4 5 6

 # condition E, overlaps (identical)
 sequence1: 1 2 3 4 5 6
 sequence2: 1 2 3 4 5 6
 overlap  : 1 2 3 4 5 6
 combined : 1 2 3 4 5 6

 # condition F, overlaps
 sequence1: 1 2 3 4 5 6
 sequence2: 1 2 3 4 5 6 7 8
 overlap  : 1 2 3 4 5 6
 combined : 1 2 3 4 5 6 7 8

 # condition G1, overlaps in the middle of second sequence will be assumed as non-overlapping
 sequence1: 1 2 3 4 5 6
 sequence2:   2 3 4 x x 5 6
 overlap  :
 combined : 1 2 3 4 5 6 2 3 4 x x 5 6

 # condition G2, multiple overlaps will be assumed as non-overlapping
 sequence1: 1 2 3 4 5 6
 sequence2: 2 3 4 x x 5 6 y y
 overlap  :
 combined : 1 2 3 4 5 6 2 3 4 x x 5 6 y y

=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 find_overlap

Usage:

 find_overlap(\@seq1, \@seq2 [ , $detail ])

=head2 combine_overlap

Usage:

 combine_overlap(\@seq1, \@seq2 [ , $detail ])

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-OverlapFinder>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-OverlapFinder>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Array-OverlapFinder/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Algorithm::Diff>

L<Text::OverlapFinder> has a similar name, but the two modules are not that
related.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
