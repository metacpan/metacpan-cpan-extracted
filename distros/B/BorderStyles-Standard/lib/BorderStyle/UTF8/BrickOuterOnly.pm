package BorderStyle::UTF8::BrickOuterOnly;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-12'; # DATE
our $DIST = 'BorderStyles-Standard'; # DIST
our $VERSION = '0.007'; # VERSION

use strict;
use parent 'BorderStyleBase';
use utf8;

our %BORDER = (
    v => 2,
    summary => 'Single-line (outer only), bold on bottom right to give illusion of depth',
    chars => [
        ['┌','─','─','┒'], # 0
        ['│',' ','┃'],     # 1
        ['│',' ',' ','┃', ' ',' '], # 2
        ['│',' ','┃'],     # 3
        ['├','─','─','┨', '─','─','─','─'], # 4
        ['┕','━','━','┛'], # 5
    ],
    utf8 => 1,
);

1;
# ABSTRACT: Single-line (outer only), bold on bottom right to give illusion of depth

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::UTF8::BrickOuterOnly - Single-line (outer only), bold on bottom right to give illusion of depth

=head1 VERSION

This document describes version 0.007 of BorderStyle::UTF8::BrickOuterOnly (from Perl distribution BorderStyles-Standard), released on 2021-05-12.

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
 $t->border_style("UTF8::BrickOuterOnly");
 $t->columns($rows->[0]);
 $t->add_row($rows->[$_]) for 1 .. $#{ $rows };
 print $t->draw;


Sample output:

 ┌────────────────────────────────────────┒
 │ ColumName1   ColumnNameB   ColumnNameC ┃
 │                                        ┃
 │ row1A        row1B         row1C       ┃
 │ row2A        row2B         row2C       ┃
 │ row3A        row3B         row3C       ┃
 ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

To use with L<Text::Table::More>:

 use Text::Table::More qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"UTF8::BrickOuterOnly");


Sample output:

 ┌────────────────────────────────────────┒
   ColumName1   ColumnNameB   ColumnNameC ┃
 │                                        ┃
   row1A        row1B         row1C       ┃
 ├────────────────────────────────────────┨
   row2A        row2B         row2C       ┃
 ├────────────────────────────────────────┨
   row3A        row3B         row3C       ┃
 ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 

To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BorderStyle::UTF8::BrickOuterOnly");


Sample output:

 ┌────────────────────────────────────────┒
 │ ColumName1   ColumnNameB   ColumnNameC ┃
 │                                        ┃
 │ row1A        row1B         row1C       ┃
 ├────────────────────────────────────────┨
 │ row2A        row2B         row2C       ┃
 ├────────────────────────────────────────┨
 │ row3A        row3B         row3C       ┃
 ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<BorderStyle::UTF8::Brick>

L<BorderStyle::Custom>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
