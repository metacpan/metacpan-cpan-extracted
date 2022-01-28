# no code
## no critic: TestingAndDebugging::RequireUseStrict
package BorderStyle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-27'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '2.0.9'; # VERSION

1;
# ABSTRACT: Border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle - Border styles

=head1 SPECIFICATION VERSION

2

=head1 VERSION

This document describes version 2.0.9 of BorderStyle (from Perl distribution BorderStyle), released on 2022-01-27.

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

Border style structure must be put in the C<%BORDER> package variable.

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

 my $str = $bs->get_border_char($y, $x, $n, \%char_args);

Get border character at a particular C<$y> and C<$x> position, duplicated C<$n>
times (defaults to 1). Per-character arguments can also be passed. Known
per-character arguments: C<rownum> (uint, row number, starts from 0), C<colnum>
(uint, column number, starts from 0).

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

=item * chars

An array. Required. Format for the characters in C<chars>:

 [                           # y
 #x 0  1  2  3  4  5  6  7
   [A, B, C, D],             # 0 Top border characters (if drawing header rows)
   [E, F, G],                # 1 Vertical separators for header row
   [H, I, J, K, a, b, c, d], # 2 Separator between header row and first data row
   [L, M, N],                # 3 Vertical separators for data row
   [O, P, Q, R, e, f, g, h], # 4 Separator between data rows
   [S, T, U, V],             # 5 Bottom border characters

   [Ȧ, Ḃ, Ċ, Ḋ],             # 6 Top border characters (if not drawing header rows)
   [Ṣ, Ṭ, Ụ, Ṿ],             # 7 Bottom border characters (if drawing header rows but there are no data rows)

   [Ȯ, Ṗ, Ꝙ, Ṙ, ė, ḟ, ġ, ḣ], # 8 Separator between header rows
 ]

When drawing border, below is how the border characters will be used:

 ABBBCBBBD        #0 Top border characters
 E   F   G        #1 Vertical separators for header row
 ȮṖṖṖꝘṖṖṖṘ        #8 Separator between header rows (if there are multiple header rows)
 E   F   G        #1 (another header row, if there are multiple header rows)
 HIIIJIIIK        #2 Separator between last header row and first data row
 L   M   N        #3 Vertical separators for data row
 OPPPQPPPR        #4 Separator between data rows
 L   M   N        #3 (another data row)
 STTTUTTTV        #5 Bottom border characters

When not drawing header rows, these characters will be used instead:

 ȦḂḂḂĊḂḂḂḊ        #6 Top border characters (when not drawing header rows)
 L   M   N        #3 Vertical separators for data row
 OPPPQPPPR        #4 Separator between data rows
 L   M   N        #3 (another data row)
 OPPPQPPPR        #4 (another separator between data rows)
 L   M   N        #3 (another data row)
 STTTUTTTV        #5 Bottom border characters

When drawing header rows and there are no data rows, these characters will be
used:

 ABBBCBBBD        #0 Top border characters
 E   F   G        #1 Vertical separators for header row
 ȮṖṖṖꝘṖṖṖṘ        #8 Separator between header rows (if there are multiple header rows)
 E   F   G        #1 (another header row, if there are multiple header rows)
 ṢṬṬṬỤṬṬṬṾ        #7 Bottom border characters (when there are header rows but no data row)

In table with column and row spans (demonstrates characters C<a>, C<b>, C<e>,
C<f>, C<g>, C<h>):

 ABBBBBBBCBBBCBBBD  ^
 E       F   F   G  |
 ȮṖṖṖṖṖṖṖꝘṖṖṖėṖṖṖṘ  |      # ė=no top line, ḟ=no bottom line
 E       F   F   G  |
 ȮṖṖṖṖṖṖṖꝘṖṖṖḟṖṖṖṘ  +------> header area
 E       F       G  |
 E       ġṖṖṖṖṖṖṖṘ  |      # ġ=no left line
 E       F       G  |
 ȮṖṖṖṖṖṖṖḣ       G  |      # h=on right line
 E       F       G  |
 HIIIaIIIJIIIbIIIK  v ^    # a=no top line, b=no bottom line
 L   M   M       N    |
 OPPPfPPPQPPPePPPR    |    # e=no top line, f=no bottom line
 L       M   M   N    |
 OPPPPPPPQPPPePPPR    +----> data area
 L       M       N    |
 L       gPPPPPPPR    |    # g=no left line
 L       M       N    |
 OPPPPPPPh       N    |    # h=on right line
 L       M       N    |
 STTTTTTTUTTTTTTTV    v

In the case of a header-data separator line also having been cut by a multirow
cell (note the C<c> and C<d> border character):

 ABBBBBBBBBCBBBBBBBBBBBBBBBBBBBBBCBBBBBBBBBD  ^
 F         F                     F         G  |
 F         cIIIIIIIIIIaIIIIIIIIIId         G  +-------> header area
 L         M          M          F         N  |
 OPPPPPPPPPQPPPPPPPPPPQPPPPPPPPPPQPPPPPPPPPR  v  ^
 M         M          M          M         N     |
 M         M          M          M         N     +----> data area
 M         M          M          M         N     |
 STTTTTTTTTUTTTTTTTTTTUTTTTTTTTTTUTTTTTTTTTV     v

A character can also be a coderef that will be called with C<< ($self, $y, $x,
$n, \%args) >>. See L</Border style character>.

=back

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

L<Border::Style> is an older specification, superseded by this document.

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
