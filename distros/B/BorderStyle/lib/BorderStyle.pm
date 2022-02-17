# no code
## no critic: TestingAndDebugging::RequireUseStrict
package BorderStyle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.2'; # VERSION

1;
# ABSTRACT: Border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle - Border styles

=head1 SPECIFICATION VERSION

3

=head1 VERSION

This document describes version 3.0.2 of BorderStyle (from Perl distribution BorderStyle), released on 2022-02-14.

=head1 DESCRIPTION

This document specifies a way to create and use border styles

=head1 GLOSSARY

=head2 border style class

=head2 border style structure

=head1 SPECIFICATION

=head2 Border style class

Border style class must be put under C<BorderStyle::*>. Application-specific
border styles should be put under C<BorderStyle::MODULE::NAME::*> or
C<BorderStyle::APP::NAME::*>.

Border style class must also provide these methods:

=over

=item * new

Usage:

 my $bs_obj = BorderStyle::NAME->new( [ %style_args ] );

Arguments will depend on the border style class; each border style class can
define what arguments they want to accept.

=item * get_struct

Usage:

 my $bs_struct = BorderStyle::NAME->get_struct;
 my $bs_struct = $bs_obj->get_struct;

Provide a method way of getting the "border style structure". Must also work as
a static method. A client can also access the %BORDER package variable directly.

=item * get_args

Usage:

 my $args = $bs_obj->get_args;

Provide a method way of getting the arguments to the constructor (the style
arguments). The official implementation BorderStyleBase::Constructor stores this
in the 'args' key of the hash object, but the proper way to access the arguments
should be via this method.

=item * get_border_char

Usage:

 my $str = $bs->get_border_char(%args);

Get border character. Arguments include:

=over

=item * char

String. Required. Character name (see below).

=item * repeat

Uint. Optional, defaults to 1.

=item * rownum

Uint, row number of the table cell, starts from 0.

=item * colnum

Uint, column number of the table cell, starts from 0.

=item * for_header_row

Bool. True if drawing a header row, or a separator line between header rows, or
a separator between header row and data row.

=item * for_header_header_separator

Bool. True if drawing a separator line between header rows/columns.

=item * for_header_column

Bool. True if drawing a header column.

=item * for_header_data_separator

Bool. True if drawing a separator line between the last header row/column and
the first data row/column.

=item * for_data_row

Bool. True if drawing a data row, or a separator line between data rows, or a
separator between header row and data row.

=item * for_data_data_separator

Bool. True if drawing a separator line between data rows/columns.

=item * for_data_column

Bool. True if drawing a data column.

=item * for_data_footer_separator

Bool. True if drawing a separator line between the last data row/column and the
first footer row/column.

=item * for_footer_row

Bool. True if drawing a footer row, or separator between footer rows, or
separator between data row and footer row.

=item * for_footer_column

Bool. True if drawing a footer column.

=item * for_footer_footer_separator

Bool. True if drawing a separator line between footer rows/columns.

=back

B<Character names>. Names of known border characters are given below:

         rd_t  h_t   hd_t        ld_t
         | ____|     |           |
         vv          v           v
         ┏━━━━━━━━━━━┳━━━━━┳━━━━━┓
  v_l -->┃    v_i -->┃ hv_i┃     ┃<-- v_r
         ┃           ┃    \┃     ┃
         ┃   rv_i -->┣━━━━━╋━━━━━┫<-- lv_r
         ┃           ┃     ┃     ┃
         ┃           ┣━━━━━┻━━━━━┫
         ┃h_i  hd_i  ┃     ^     ┃
         ┃|    |     ┃     |     ┃
         ┃v    v     ┃     hu_i  ┃
 rv_l -->┣━━━━━┳━━━━━┫<-- lv_i   ┃
         ┃     ┃     ┃           ┃
 ru_l -->┗━━━━━┻━━━━━┻━━━━━━━━━━━┛
          ^    ^                 ^
          |    |                 |
          h_b  hu_b              lu_b

 no  border character name   description
 --  ---------------------   -----------
  1  h_b                     horizontal for top border
  2  h_i                     horizontal for top border
  3  h_t                     horizontal line, for top border
  4  hd_t                    horizontal down line, for top border
  5  hd_i                    horizontal down line, for inside border
  6  hu_b                    horizontal up line, for bottom border
  7  hu_i                    horizontal up line, for inside border
  8  hv_i                    horizontal vertical line, for inside border
  9  ld_t                    left down line, for top border
 10  lu_b                    left up line, for bottom border
 11  lv_i                    left vertical, for inside border
 12  lv_r                    left vertical, for right border
 13  rd_t                    right down line, for top border
 14  ru_b                    right up line, for bottom border
 15  rv_i                    right vertical line, for inside border
 16  rv_l                    right vertical line, for left border
 17  v_i                     vertical line, for inside border
 18  v_l                     vertical line, for left border
 19  v_r                     vertical line, for right border

The arguments to C<get_border_char()> will also be passed to border character
that is coderef, or to be interpreted by the class' C<get_border_char()> to vary
the character.

=back

=head2 Border style structure

Border style structure is a L<DefHash> containing these keys:

=over

=item * v

Float, from DefHash, must be set to 2 (this specification version)

=item * name

From DefHash.

=item * summary

From DefHash.

=item * utf8

Bool, must be set to true if the style uses non-ASCII UTF8 border character(s).

Cannot be mixed with L</box_chars>.

=item * box_chars

Bool, must be set to true if the style uses box-drawing character. When using
box-drawing character, the characters in L</chars> property must be specified
using the VT100-style escape sequence without the prefix. For example, the
top-left single border character must be specified as "l". For more details on
box-drawing character, including the list of escape sequneces, see
L<https://en.wikipedia.org/wiki/Box-drawing_character>.

Box-drawing characters must not be mixed with other characters (ASCII or UTF8).

=item * args

A hash of argument names and specifications (each specification a L<DefHash>) to
specify which arguments a border style accept. This is similar to how
L<Rinci::function> specifies function arguments. An argument specification can
contain these properties: C<summary>, C<description>, C<schema>, C<req>,
C<default>.

=back

Border style structure must be put in the C<%BORDER> package variable.

=head2 Border style character

A border style character can be a single-character string, or a coderef to allow
border style that is context-sensitive.

If border style character is a coderef, it must return a single-character string
and not another coderef. The coderef will be called with the same arguments
passed to L</get_border_char>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

=head1 HISTORY

=head2 v3

Incompatible change.

Remove C<chars> in border style structure and abstract it through
C<get_border_char()> to be more flexible, e.g. to allow for footer area,
vertical header (header columns), and so on.

Replace the positional arguments in C<get_border_char()> with named arguments to
be more flexible. Replace the C<x> and C<y> arguments that refer to character
with character C<name>, to be more readable.

=head2 v2

The first version of BorderStyle.

=head2 Border::Style

L<Border::Style> is an older specification, superseded by this document. The
older specification defines border style as just the border style structure, not
the class and thus lacks methods like C<get_struct()>, C<get_args()>, and
C<get_border_char()>.

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
