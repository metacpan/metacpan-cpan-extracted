use strict;
use warnings;
package B::Hooks::Parser; # git description: v0.20-4-g44a7b86
# ABSTRACT: Interface to perl's parser variables
# KEYWORDS: perl internals API parser hooks modify

use B::Hooks::OP::Check;
use parent qw/DynaLoader/;

our $VERSION = '0.21';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

sub inject {
    my ($code) = @_;

    setup();

    my $line   = get_linestr();
    my $offset = get_linestr_offset();

    substr($line, $offset, 0) = $code;

    set_linestr($line);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B::Hooks::Parser - Interface to perl's parser variables

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This module provides an API for parts of the perl parser. It can be used to
modify code while it's being parsed.

=head1 Perl API

=head2 C<setup()>

Does some initialization work. This must be called before any other functions
of this module if you intend to use C<set_linestr>. Returns an id that can be
used to disable the magic using C<teardown>.

=head2 C<teardown($id)>

Disables magic registered using C<setup>.

=head2 C<get_linestr()>

Returns the line the parser is currently working on, or undef if perl isn't
parsing anything right now.

=head2 C<get_linestr_offset()>

Returns the position within the current line to which perl has already parsed
the input, or -1 if nothing is being parsed currently.

=head2 C<set_linestr($string)>

Sets the line the perl parser is currently working on to C<$string>.

Note that perl won't notice any changes in the line string after the position
returned by C<get_linestr_offset>.

Throws an exception when nothing is being compiled.

=head2 C<inject($string)>

Convenience function to insert a piece of perl code into the current line
string (as returned by C<get_linestr>) at the current offset (as returned by
C<get_linestr_offset>).

=head2 C<get_lex_stuff()>

Returns the string of additional stuff resulting from recent lexing that
is being held onto by the lexer.  For example, the content of a quoted
string goes here.  Returns C<undef> if there is no such stuff.

=head2 C<clear_lex_stuff()>

Discard the string of additional stuff resulting from recent lexing that
is being held onto by the lexer.

=head1 C API

The following functions work just like their equivalent in the Perl API,
except that they can't handle embedded C<NUL> bytes in strings.

=head2 C<hook_op_check_id hook_parser_setup (void)>

Note: may be implemented as a macro.

=head2 C<void hook_parser_teardown (hook_op_check_id id)>

=head2 C<const char *hook_parser_get_linestr (pTHX)>

=head2 C<IV hook_parser_get_linestr_offset (pTHX)>

=head2 C<void hook_parser_set_linestr (pTHX_ const char *new_value)>

=head2 C<char *hook_parser_get_lex_stuff (pTHX)>

=head2 C<void hook_parser_clear_lex_stuff (pTHX)>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=B-Hooks-Parser>
(or L<bug-B-Hooks-Parser@rt.cpan.org|mailto:bug-B-Hooks-Parser@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Zefram Vincent Pit Alexandr Ciornii Karl Williamson Liu Kang-min

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Zefram <zefram@fysh.org>

=item *

Vincent Pit <perl@profvince.com>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Karl Williamson <khw@cpan.org>

=item *

Liu Kang-min <gugod@gugod.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
