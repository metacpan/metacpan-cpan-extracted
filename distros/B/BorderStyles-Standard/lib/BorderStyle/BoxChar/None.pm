package BorderStyle::BoxChar::None;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-31'; # DATE
our $DIST = 'BorderStyles-Standard'; # DIST
our $VERSION = '0.005'; # VERSION

use strict;
use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'No borders, but data row separator is still drawn using horizontal line',
    chars => [
        ['','','',''],     # 0
        ['','',''],        # 1
        ['','','','', '',''],     # 2
        ['','',''],        # 3
        ['','q','q','', '','','',''],   # 4
        ['','','',''],     # 5
    ],
    box_chars => 1,
);

1;
# ABSTRACT: No borders, but data row separator is still drawn using horizontal line

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::BoxChar::None - No borders, but data row separator is still drawn using horizontal line

=head1 VERSION

This document describes version 0.005 of BorderStyle::BoxChar::None (from Perl distribution BorderStyles-Standard), released on 2021-01-31.

=head1 SYNOPSIS

To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BorderStyle::BoxChar::None");

To use with L<Text::ANSITable>:

 # TODO

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

L<BorderStyle::ASCII::None>

L<BorderStyle::UTF8::None>

L<BorderStyle::Custom>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
