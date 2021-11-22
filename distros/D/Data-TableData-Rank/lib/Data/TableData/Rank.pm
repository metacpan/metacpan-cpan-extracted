package Data::TableData::Rank;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-17'; # DATE
our $DIST = 'Data-TableData-Rank'; # DIST
our $VERSION = '0.001'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(add_rank_column_to_table);

our %SPEC;

$SPEC{add_rank_column_to_table} = {
    v => 1.1,
    summary => 'Add a rank column to a table',
    description => <<'_',

Will modify the table by adding a rank column. An example, with this table:

    | name       | gold | silver | bronze |
    |------------+------+--------+--------|
    | E          |  2   |  5     |  7     |
    | A          | 10   | 20     | 15     |
    | H          |  0   |  0     |  1     |
    | B          |  8   | 23     | 17     |
    | G          |  0   |  0     |  1     |
    | J          |  0   |  0     |  0     |
    | C          |  4   | 10     |  8     |
    | D          |  4   |  9     | 13     |
    | I          |  0   |  0     |  1     |
    | F          |  2   |  5     |  1     |

the result of ranking the table with data columns of C<<
["gold","silver","bronze"] >> will be:

    | name       | gold | silver | bronze | rank |
    |------------+------+--------+--------+------|
    | A          | 10   | 20     | 15     |  1   |
    | B          |  8   | 23     | 17     |  2   |
    | C          |  4   | 10     |  8     |  3   |
    | D          |  4   |  9     | 13     |  4   |
    | E          |  2   |  5     |  7     |  5   |
    | F          |  2   |  5     |  1     |  6   |
    | G          |  0   |  0     |  1     | =7   |
    | H          |  0   |  0     |  1     | =7   |
    | I          |  0   |  0     |  1     | =7   |
    | J          |  0   |  0     |  0     | 10   |

_
    args => {
        table => {
            summary => 'A table data (either aoaos, aohos, or its Data::TableData::Object wrapper)',
            schema => 'any*',
            req => 1,
        },
        data_columns => {
            summary => 'Array of names (or indices) of columns which contain the data to be compared, which must all be numeric',
            schema => [array => {of => 'str*', min_len=>1}],
            req => 1,
        },
        smaller_wins => {
            summary => 'Whether a smaller number in the data wins; normally a bigger name means a higher rank',
            schema => 'bool*',
            default => 0,
        },
        rank_column_name => {
            schema => 'str*',
            default => 'rank',
        },
        add_equal_prefix => {
            schema => 'bool*',
            default => 1,
        },
        rank_column_idx => {
            schema => 'int*',
        },
    },
};
sub add_rank_column_to_table {
    require Data::TableData::Object;

    my %args = @_;
    my $data_columns = $args{data_columns};
    my $smaller_wins = $args{smaller_wins} // 0;
    my $add_equal_prefix = $args{add_equal_prefix} // 1;
    my $rank_column_name = $args{rank_column_name} // 'rank';

    my $td = Data::TableData::Object->new($args{table});
    my @colidxs = map { $td->col_idx($_) } @$data_columns;
    #use DD; print "D:colidxs "; dd \@colidxs;

    my $aoaos = $td->rows_as_aoaos;
    my $cmp_row = sub {
        my ($row1, $row2) = @_;
        #use DD; print "D:comparing: "; dd {a=>$row1, b=>$row2};
        my $res = 0;
        for (@colidxs) {
            my $cmp = $row1->[$_] <=> $row2->[$_];
            $cmp = -$cmp unless $smaller_wins;
            if ($cmp) { $res = $cmp; last }
        }
        #print "D:comparison result: $res\n";
        $res;
    };
    my @sorted_indices = sort { $cmp_row->($aoaos->[$a], $aoaos->[$b]) } 0 .. $#{$aoaos};
    #use DD; print "D:sorted_indices: "; dd \@sorted_indices;
    #use DD; print "D:sorted table: "; dd [map {$aoaos->[$_]} @sorted_indices];
    my @sorted_aoaos   = map { $aoaos->[$_] } @sorted_indices;
    my @ranks;
    my %num_has_rank; # key=rank, val=num of rows
    for my $rownum (0 .. $#sorted_aoaos) {
        if ($rownum) {
            if ($cmp_row->($sorted_aoaos[$rownum-1], $sorted_aoaos[$rownum])) {
                my $rank = @ranks + 1;
                push @ranks, $rank;
                $num_has_rank{$rank}++;
            } else {
                push @ranks, $ranks[-1];
                $num_has_rank{ $ranks[-1] }++;
            }
        } else {
            push @ranks, 1;
            $num_has_rank{1}++;
        }
    }

    if ($add_equal_prefix) {
        for my $i (0..$#ranks) {
            if ($num_has_rank{ $ranks[$i] } > 1) { $ranks[$i] = "=$ranks[$i]" }
        }
    }
    #use DD; print "D:ranks: "; dd \@ranks;

    # assign the ranks to the original, unsorted rows
    my @ranks_orig = map { undef } @ranks;
    for my $i (0 .. $#sorted_indices) {
        $ranks_orig[ $sorted_indices[$i] ] = $ranks[ $i ];
        #use DD; dd \@ranks_orig;
    }
    #use DD; print "D:ranks_orig: "; dd \@ranks_orig;

    $td->add_col($rank_column_name, $args{rank_column_idx}, {}, \@ranks_orig);
    $td;
}

1;
# ABSTRACT: Add a rank column to a table

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableData::Rank - Add a rank column to a table

=head1 VERSION

This document describes version 0.001 of Data::TableData::Rank (from Perl distribution Data-TableData-Rank), released on 2021-11-17.

=head1 FUNCTIONS


=head2 add_rank_column_to_table

Usage:

 add_rank_column_to_table(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add a rank column to a table.

Will modify the table by adding a rank column. An example, with this table:

 | name       | gold | silver | bronze |
 |------------+------+--------+--------|
 | E          |  2   |  5     |  7     |
 | A          | 10   | 20     | 15     |
 | H          |  0   |  0     |  1     |
 | B          |  8   | 23     | 17     |
 | G          |  0   |  0     |  1     |
 | J          |  0   |  0     |  0     |
 | C          |  4   | 10     |  8     |
 | D          |  4   |  9     | 13     |
 | I          |  0   |  0     |  1     |
 | F          |  2   |  5     |  1     |

the result of ranking the table with data columns of C<<
["gold","silver","bronze"] >> will be:

 | name       | gold | silver | bronze | rank |
 |------------+------+--------+--------+------|
 | A          | 10   | 20     | 15     |  1   |
 | B          |  8   | 23     | 17     |  2   |
 | C          |  4   | 10     |  8     |  3   |
 | D          |  4   |  9     | 13     |  4   |
 | E          |  2   |  5     |  7     |  5   |
 | F          |  2   |  5     |  1     |  6   |
 | G          |  0   |  0     |  1     | =7   |
 | H          |  0   |  0     |  1     | =7   |
 | I          |  0   |  0     |  1     | =7   |
 | J          |  0   |  0     |  0     | 10   |

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_equal_prefix> => I<bool> (default: 1)

=item * B<data_columns>* => I<array[str]>

Array of names (or indices) of columns which contain the data to be compared, which must all be numeric.

=item * B<rank_column_idx> => I<int>

=item * B<rank_column_name> => I<str> (default: "rank")

=item * B<smaller_wins> => I<bool> (default: 0)

Whether a smaller number in the data wins; normally a bigger name means a higher rank.

=item * B<table>* => I<any>

A table data (either aoaos, aohos, or its Data::TableData::Object wrapper).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-TableData-Rank>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-TableData-Rank>.

=head1 SEE ALSO

L<Data::TableData::Object>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-TableData-Rank>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
