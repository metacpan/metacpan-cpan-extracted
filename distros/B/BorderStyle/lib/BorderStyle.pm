package BorderStyle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-23'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '2.0.4'; # VERSION

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

This document describes version 2.0.4 of BorderStyle (from Perl distribution BorderStyle), released on 2021-01-23.

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

 my $bs_obj = BorderStyle::NAME->new( [ %args ] );

Arguments will depend on the border style class (see L</args>).

=item * get_struct

Usage:

 my $bs_struct = BorderStyle::NAME->get_struct;
 my $bs_struct = $bs_obj->get_struct;

Provide a method way of getting the "border style structure". Must also work as
a static method. A client can also access the %BORDER package variable directly.

=item * get_args

Usage:

 my $args = $bs_obj->get_args;

Provide a method way of getting the arguments to the constructor. The official
implementation BorderStyleBase::Constructor stores this in the 'args' key of the
hash object, but the proper way to access the arguments should be via this
method.

=item * get_border_char

Usage:

 my $str = $bs->get_border_char($y, $x, $n, \%args);

Get border character at a particular C<$y> and C<$x> position, duplicated C<$n>
times (defaults to 1). Arguments can be passed to border character that is a
coderef.

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

=item * chars

An array. Required. Format for the characters in C<chars>:

 [                           # y
 #x 0  1  2  3  4  5  6  7
   [A, B, C, D,              # 0 Top border characters
   [E, F, G],                # 1 Vertical separators for header row
   [H, I, J, K, a, b],       # 2 Separator between header row and first data row
   [L, M, N],                # 3 Vertical separators for data row
   [O, P, Q, R, e, f, g, h], # 4 Separator between data rows
   [S, T, U, V],             # 5 Bottom border characters
 ]

When drawing border, below is how the border characters will be used:

 ABBBCBBBD        #0 Top border characters
 E   F   G        #1 Vertical separators for header row
 HIIIJIIIK        #2 Separator between header row and first data row
 L   M   N        #3 Vertical separators for data row
 OPPPQPPPR        #4 Separator between data rows
 L   M   N        #3
 STTTUTTTV        #5 Bottom border characters

In table with column and row spans (demonstrates characters C<a>, C<b>, C<e>,
C<f>, C<g>, C<h>):

 ABBBCBBBCBBBCBBBD
 E       F   F   G
 HIIIaIIIJIIIbIIIK         # a=no top line, b=no bottom line
 L   M   M       N
 OPPPfPPPQPPPePPPR         # e=no top line, f=no bottom line
 L       M   M   N
 OPPPPPPPQPPPePPPR
 L       M       N
 L       gPPPPPPPR         # g=no left line
 L       M       N
 OPPPPPPPh       N         # h=on right line
 L       M       N
 STTTTTTTUTTTTTTTV

A character can also be a coderef that will be called with C<< ($self, $y, $x,
$n, \%args) >>. See L</Border style character>.

=back

=head1 Border style character

A border style character can be a single-character string, or a coderef to allow
border style that is context-sensitive.

If border style character is a coderef, it must return a single-character string
and not another coderef. The coderef will be called with the same arguments
passed to L</get_border_char>.

=head1 HISTORY

L<Border::Style> is an older specification, superseded by this document.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-BorderStyle/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
