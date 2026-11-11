package App::Greple::md::widen;

use 5.026;
use warnings;
use utf8;

our $VERSION = "1.18";

=encoding utf-8

=head1 NAME

App::Greple::md::widen - give some characters a column of their own

=head1 SYNOPSIS

    greple -Mmd --begin '&widen' -- file.md
    greple -Mmd --begin '&widen(chars=2460-24FF:3248-324F)' -- file.md

    mdee -t widen file.md

=head1 DESCRIPTION

Circled digits and the wastebasket (U+1F5D1) are one column wide to
Unicode and to the terminals, but macOS terminals draw them over two
columns, on top of the next character.  The function B<widen>, for the
C<--begin> option of L<App::Greple::md>, adds a no-break space after
such a character, so that its width is right for every tool.  A
no-break space is used because it stays at the end of a folded line,
where B<ansifold> removes spaces.  A variation selector (U+FE0E or
U+FE0F) after the character stays with it, and the space comes after
the selector.

Fenced code with a language, code spans, the addresses of links and
autolinks are left as they are, because a program must stay as it is
written.  Fenced code without a language is often a figure or an
output, and is changed.  Copying the text from the screen brings the
no-break spaces along.

=head1 PARAMETERS

=over 4

=item B<chars>

The characters as code points and ranges in hexadecimal, separated by
colons.  Default is C<2460-24FF:1F5D1>, the circled digits and the
wastebasket.

=back

=head1 SEE ALSO

L<App::Greple::md>, L<App::mdee>

=head1 LICENSE

This software is released under the MIT License.
L<https://opensource.org/licenses/MIT>

=cut

# Where the text must stay as written: fenced code with a language, code
# spans, and the addresses of links.
my $SKIP = qr{
    (?:
        ^ [ ]{0,3} (?<_fence> (?<_fc>[`~]) \g{_fc}{2,}+ ) \h* \S .* \n
        (?s:.*?)
        ^ [ ]{0,3} \g{_fence} \g{_fc}*+ \h* $
    |
        (?<_bt> `++ ) (?: (?! \g{_bt} ) . )+? \g{_bt}
    |
        \] \( [^)\n]* \)
    |
        < [a-zA-Z][\w+.-]*: [^>\s]* >
    )
    (*SKIP)(*FAIL)
}xm;

sub class {
    my $spec = shift;
    state %class;
    $class{$spec} //= do {
        my $ranges = join '', map {
            /\A([0-9a-fA-F]+)(?:-([0-9a-fA-F]+))?\z/ or die "widen: $spec: bad range\n";
            defined $2 ? "\\x{$1}-\\x{$2}" : "\\x{$1}";
        } split /:/, $spec;
        qr/[$ranges]/;
    };
}

sub widen {
    my %arg = @_;
    my $class = class($arg{chars} // '2460-24FF:1F5D1');
    s{ $SKIP | (?<char> $class [\x{FE0E}\x{FE0F}]?+ ) (?!\x{A0}) }{$+{char}\x{A0}}xmg;
}

1;
