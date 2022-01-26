package BorderStyle::ASCII::Space;

use strict;
use parent 'BorderStyleBase';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-26'; # DATE
our $DIST = 'BorderStyles-Standard'; # DIST
our $VERSION = '0.011'; # VERSION

our %BORDER = (
    v => 2,
    summary => 'Space as borders, but data row separator is still drawn using dashes',
    chars => [
        [' ',' ',' ',' '], # 0
        [' ',' ',' '],     # 1
        [' ',' ',' ',' ', ' ',' ',' ',' '], # 2
        [' ',' ',' '],     # 3
        [' ','-','-',' ', '-','-','-','-'], # 4
        [' ',' ',' ',' '], # 5
    ],
);

1;
# ABSTRACT: Space as borders, but data row separator is still drawn using dashes

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::ASCII::Space - Space as borders, but data row separator is still drawn using dashes

=head1 VERSION

This document describes version 0.011 of BorderStyle::ASCII::Space (from Perl distribution BorderStyles-Standard), released on 2022-01-26.

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
 $t->border_style("ASCII::Space");
 $t->columns($rows->[0]);
 $t->add_row($rows->[$_]) for 1 .. $#{ $rows };
 print $t->draw;


Sample output:

                                           
   ColumName1   ColumnNameB   ColumnNameC  
                                           
   row1A        row1B         row1C        
   row2A        row2B         row2C        
   row3A        row3B         row3C        
                                           

To use with L<Text::Table::More>:

 use Text::Table::More qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"ASCII::Space");


Sample output:

                                           
   ColumName1   ColumnNameB   ColumnNameC  
                                           
   row1A        row1B         row1C        
  ---------------------------------------- 
   row2A        row2B         row2C        
  ---------------------------------------- 
   row3A        row3B         row3C        
                                           
 

To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BorderStyle::ASCII::Space");


Sample output:

                                           
   ColumName1   ColumnNameB   ColumnNameC  
                                           
   row1A        row1B         row1C        
  ---------------------------------------- 
   row2A        row2B         row2C        
  ---------------------------------------- 
   row3A        row3B         row3C        
                                           

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Standard>.

=head1 SEE ALSO

L<BorderStyle::BoxChar::Space>

L<BorderStyle::UTF8::Space>

L<BorderStyle::Custom>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
