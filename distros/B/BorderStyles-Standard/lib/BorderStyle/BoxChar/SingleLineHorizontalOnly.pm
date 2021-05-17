package BorderStyle::BoxChar::SingleLineHorizontalOnly;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-19'; # DATE
our $DIST = 'BorderStyles-Standard'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'Single line border with box-drawing characters, horizontal only',
    chars => [
        ['q','q','q','q'], # 0
        [' ',' ',' '],     # 1
        ['q','q','q','q', 'q','q'], # 2
        [' ',' ',' '],     # 3
        ['q','q','q','q', 'q','q','q','q'], # 4
        ['q','q','q','q'], # 5
    ],
    box_chars => 1,
);

1;
# ABSTRACT: Single line border with box-drawing characters, horizontal only

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::BoxChar::SingleLineHorizontalOnly - Single line border with box-drawing characters, horizontal only

=head1 VERSION

This document describes version 0.006 of BorderStyle::BoxChar::SingleLineHorizontalOnly (from Perl distribution BorderStyles-Standard), released on 2021-02-19.

=head1 SYNOPSIS

To use with L<Text::ANSITable>:

 use Text::ANSITable;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 my $t = Text::ANSITable->new;
 $t->border_style("BoxChar::SingleLineHorizontalOnly");
 $t->columns($rows->[0]);
 $t->add_row($rows->[$_]) for 1 .. $#{ $rows };
 print $t->draw;

To use with L<Text::Table::Span>:

 use Text::Table::Span qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BoxChar::SingleLineHorizontalOnly");

To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BorderStyle::BoxChar::SingleLineHorizontalOnly");

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-BorderStyles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<BorderStyle::BoxChar::SingleLineVerticalOnly>

L<BorderStyle::ASCII::SingleLineHorizontalOnly>

L<BorderStyle::UTF8::SingleLineHorizontalOnly>

L<BorderStyle::Custom>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
