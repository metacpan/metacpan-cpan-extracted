package Algorithm::MLCS;

use strict;
use warnings FATAL => 'all';

use vars qw/ $VERSION @ISA @EXPORT /;

require Exporter;

@ISA     = qw/ Exporter /;
@EXPORT  = qw/ lcs /;
$VERSION = '1.02';

# Gets arrayref of sequences (arrayrefs) and return LCS array in list context
# or length of LCS in scalar context
sub lcs {
    my ( @seq, @lcs ) = map { _build_seq($_) } _get_dict( $_[0] );

    while ( @seq && !( grep { !@$_ } @seq ) ) {
        my %dict = ( %{ $seq[0][0] } );

        for my $s ( @seq[ 1 .. $#seq ] ) {
            %dict = map {
                      $_ => $dict{$_} > $s->[0]{$_}
                    ? $s->[0]{$_} : $dict{$_}
            } grep { $s->[0]{$_} } keys %dict;
        }

        last unless %dict;

        push @lcs, ( sort { $dict{$b} <=> $dict{$a} } keys %dict )[0];

        for (@seq) {
            while (@$_) { last if @$_ == ( shift @$_ )->{ $lcs[-1] } }
        }
    }

    wantarray ? @lcs : scalar @lcs;
}

# Auxiliary function that gets single sequence arrayref and
# build specific data structure for further processing
# in order to find LCS
sub _build_seq {
    my ( $seq, %dict, @seq_st ) = @_;

    for ( 0 .. $#{$seq} ) { push @{ $dict{ $seq->[$_] } }, $_ }

    for my $i ( 0 .. $#{$seq} ) {
        my %tok;
        for ( keys %dict ) {
            $tok{$_} = @{$seq} - $dict{$_}[0];
            if ( $dict{$_}[0] == $i ) {
                shift @{ $dict{$_} };
                delete $dict{$_} if !@{ $dict{$_} };
            }
        }
        $seq_st[$i] = \%tok;
    }

    return \@seq_st;
}

# Auxiliary function that gets arrayref of sequences (arrayrefs),
# builds dictionary of unique tokens presented in all given sequences
# and returns the arrayref of new sequences with only tokens from dictionary
sub _get_dict {
    my $seq = shift;
    my %dict = map { $_ => 1 } @{ $seq->[0] };

    for ( @{$seq}[ 1 .. $#{$seq} ] ) {
        %dict = map { $_ => 1 } grep { $dict{$_} } @$_;
        last unless %dict;
    }

    return map { [ grep { $dict{$_} } @$_ ] } @{$seq};
}

1;

=head1 NAME

Algorithm::MLCS - Fast heuristic algorithm for finding Longest Common Subsequence
of multiple sequences

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use Data::Dumper;
    use Algorithm::MLCS;

    my @seqs = (
        [ qw/a b c d f g h j q z/ ],
        [ qw/a b c d f g h j q z/ ],
        [ qw/a b c x f h j q z/   ],
        [ qw/a b c f g j q z/     ],
    );

    my @lcs = lcs( \@seqs );
    my $lcs_length = lcs( \@seqs );
    print Dumper( \@lcs );

=head1 ABSTRACT

Finding the longest common subsequence (LCS) for the general case of an arbitrary
number of input sequences is an NP-hard problem. Algorithm::MLCS implements a fast
heuristic algorithm that addresses the general case of multiple sequences.
It is able to extract common subsequence that is close to the optimal ones.

=head1 METHODS

=head2 lcs ( \@seqs )

Finds a Longest Common Subsequence of multiple sequences given by @seqs arrayref.
Each element of @seqs is arrayref that represents the one of multiple sequences
(e.g. [ ['a', 'b', 'c'], ['a', 'c', 'd', 'e'], ... ]). In list context it returns
LCS array, in scalar - the length of LCS.

=head1 SEE ALSO

Algorithm::LCS

=head1 AUTHOR

Slava Moiseev, C<< <slava.moiseev at yahoo.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Slava Moiseev.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

