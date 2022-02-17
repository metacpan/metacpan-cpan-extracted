package BorderStyle::Test::Labeled;

use strict;
use utf8;
use warnings;

use Role::Tiny::With;
with 'BorderStyleRole::Source::Hash';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.2'; # VERSION

our %BORDER = (
    v => 3,
    summary => 'A border style that uses labeled characters',
    utf8 => 1,
);

our @MULTI_CHARS = (
    {
        for_header_data_separator => 1,
        chars => {
            h_b => 'Ȧ',
            h_i => 'Ḃ',
            h_t => 'Ċ',
            hd_i => 'Ḋ',
            hd_t => 'Ė',
            hu_b => 'Ḟ',
            hu_i => 'Ġ',
            hv_i => 'Ḣ',
            ld_t => 'İ',
            lu_b => 'Ĵ',
            lv_i => 'Ḱ',
            lv_r => 'Ĺ',
            rd_t => 'Ṁ',
            ru_b => 'Ṅ',
            rv_i => 'Ȯ',
            rv_l => 'Ṗ',
            v_i => 'Ꝙ',
            v_l => 'Ṙ',
            v_r => 'Ṡ',
        },
    },
    {
        for_header_row => 1,
        chars => {
            h_b => 'A',
            h_i => 'B',
            h_t => 'C',
            hd_i => 'D',
            hd_t => 'E',
            hu_b => 'F',
            hu_i => 'G',
            hv_i => 'H',
            ld_t => 'I',
            lu_b => 'J',
            lv_i => 'K',
            lv_r => 'L',
            rd_t => 'M',
            ru_b => 'N',
            rv_i => 'O',
            rv_l => 'P',
            v_i => 'Q',
            v_l => 'R',
            v_r => 'S',
        },
    },
    {
        chars => {
            h_b => 'a',
            h_i => 'b',
            h_t => 'c',
            hd_i => 'd',
            hd_t => 'e',
            hu_b => 'f',
            hu_i => 'g',
            hv_i => 'h',
            ld_t => 'i',
            lu_b => 'j',
            lv_i => 'k',
            lv_r => 'l',
            rd_t => 'm',
            ru_b => 'n',
            rv_i => 'o',
            rv_l => 'p',
            v_i => 'q',
            v_l => 'r',
            v_r => 's',
        },
    },
);

1;
# ABSTRACT: A border style that uses labeled characters

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::Labeled - A border style that uses labeled characters

=head1 VERSION

This document describes version 3.0.2 of BorderStyle::Test::Labeled (from Perl distribution BorderStyle), released on 2022-02-14.

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
 $t->border_style("Test::Labeled");
 $t->columns($rows->[0]);
 $t->add_row($rows->[$_]) for 1 .. $#{ $rows };
 print $t->draw;


Sample output:

 mcccccccccccceccccccccccccceccccccccccccci
 r ColumName1 q ColumnNameB q ColumnNameC s
 pbbbbbbbbbbbbhbbbbbbbbbbbbbhbbbbbbbbbbbbbl
 r row1A      q row1B       q row1C       s
 r row2A      q row2B       q row2C       s
 r row3A      q row3B       q row3C       s
 naaaaaaaaaaaafaaaaaaaaaaaaafaaaaaaaaaaaaaj

To use with L<Text::Table::More>:

 use Text::Table::More qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"Test::Labeled");


Sample output:

 MCCCCCCCCCCCCECCCCCCCCCCCCCECCCCCCCCCCCCCI
 Q ColumName1 Q ColumnNameB Q ColumnNameC S
 ṖḂḂḂḂḂḂḂḂḂḂḂḂḢḂḂḂḂḂḂḂḂḂḂḂḂḂḢḂḂḂḂḂḂḂḂḂḂḂḂḂĹ
 q row1A      q row1B       q row1C       s
 pbbbbbbbbbbbbhbbbbbbbbbbbbbhbbbbbbbbbbbbbl
 q row2A      q row2B       q row2C       s
 pbbbbbbbbbbbbhbbbbbbbbbbbbbhbbbbbbbbbbbbbl
 q row3A      q row3B       q row3C       s
 naaaaaaaaaaaafaaaaaaaaaaaaafaaaaaaaaaaaaaj
 

To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BorderStyle::Test::Labeled");


Sample output:

 MCCCCCCCCCCCCECCCCCCCCCCCCCECCCCCCCCCCCCCI
 R ColumName1 Q ColumnNameB Q ColumnNameC S
 ṖḂḂḂḂḂḂḂḂḂḂḂḂḢḂḂḂḂḂḂḂḂḂḂḂḂḂḢḂḂḂḂḂḂḂḂḂḂḂḂḂĹ
 r row1A      q row1B       q row1C       s
 pbbbbbbbbbbbbhbbbbbbbbbbbbbhbbbbbbbbbbbbbl
 r row2A      q row2B       q row2C       s
 pbbbbbbbbbbbbhbbbbbbbbbbbbbhbbbbbbbbbbbbbl
 r row3A      q row3B       q row3C       s
 naaaaaaaaaaaafaaaaaaaaaaaaafaaaaaaaaaaaaaj

=head1 DESCRIPTION

This border style uses a different label character for each border character.

For header row:

 h_b => 'A',
 h_i => 'B',
 h_t => 'C',
 hd_i => 'D',
 hd_t => 'E',
 hu_b => 'F',
 hu_i => 'G',
 hv_i => 'H',
 ld_t => 'I',
 lu_b => 'J',
 lv_i => 'K',
 lv_r => 'L',
 rd_t => 'M',
 ru_b => 'N',
 rv_i => 'O',
 rv_l => 'P',
 v_i => 'Q',
 v_l => 'R',
 v_r => 'S',

For header-data separator:

 h_b => 'Ȧ',
 h_i => 'Ḃ',
 h_t => 'Ċ',
 hd_i => 'Ḋ',
 hd_t => 'Ė',
 hu_b => 'Ḟ',
 hu_i => 'Ġ',
 hv_i => 'Ḣ',
 ld_t => 'İ',
 lu_b => 'Ĵ',
 lv_i => 'Ḱ',
 lv_r => 'Ĺ',
 rd_t => 'Ṁ',
 ru_b => 'Ṅ',
 rv_i => 'Ȯ',
 rv_l => 'Ṗ',
 v_i => 'Ꝙ',
 v_l => 'Ṙ',
 v_r => 'Ṡ',

For data row:

 h_b => 'a',
 h_i => 'b',
 h_t => 'c',
 hd_i => 'd',
 hd_t => 'e',
 hu_b => 'f',
 hu_i => 'g',
 hv_i => 'h',
 ld_t => 'i',
 lu_b => 'j',
 lv_i => 'k',
 lv_r => 'l',
 rd_t => 'm',
 ru_b => 'n',
 rv_i => 'o',
 rv_l => 'p',
 v_i => 'q',
 v_l => 'r',
 v_r => 's',

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

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

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
