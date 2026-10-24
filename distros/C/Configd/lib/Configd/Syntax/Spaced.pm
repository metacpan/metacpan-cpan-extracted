package Configd::Syntax::Spaced;
$Configd::Syntax::Spaced::VERSION = '0.005';
#ABSTRACT: Config files that are a directive, some whitespace and a value.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use parent qw{Configd::Language};


sub parse {
    my ( $self, $text ) = @_;

    my @directives;
    foreach my $line ( split( qq{\n}, $text ) ) {
        if ( $line =~ m/\A\s*(?:#.*)?\z/ ) {
            push @directives, { text => $line };
            next;
        }

        # Tabs as often as spaces in these files, and a value that runs to the
        # end of the line: opendkim's Canonicalization is one word, its
        # InternalHosts is a list, and neither is quoted.
        my ( $key, $value ) = $line =~ m/\A\s*(\S+)\s+(.*?)\s*\z/;

        # A directive on its own is legal in some of these -- redis has bare
        # flags -- and means itself.
        ( $key, $value ) = ( $line =~ s/\A\s+|\s+\z//gr, q{} ) if !defined $key;

        push @directives, { key => $key, value => $value };
    }

    return \@directives;
}


sub emit {
    my ( $self, $directives ) = @_;

    my $out = q{};
    foreach my $directive (@$directives) {
        if ( !defined $directive->{key} ) {
            $out .= ( $directive->{text} // q{} ) . "\n";
            next;
        }

        $out .=
          length $directive->{value}
          ? "$directive->{key} $directive->{value}\n"
          : "$directive->{key}\n";
    }

    return $out;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Syntax::Spaced - Config files that are a directive, some whitespace and a value.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package Configd::Language::spaced_example;

    use parent qw{Configd::Syntax::Spaced};

    sub files   { return ( { path => '/etc/example.conf', mode => 0o644 } ) }
    sub units   { return ('example.service') }
    sub repeats { my ( $self, $key ) = @_; return $key eq 'listen' }

=head1 DESCRIPTION

Four of the files here are the same shape:

    Syslog                  yes
    Canonicalization        relaxed/simple

opendkim, opendmarc, redis and chrony all write configuration this way -- a
directive, whitespace, and the rest of the line -- and differ only in which
directives may be said twice, and which are lists that fragments add to.  One reader and one writer between them, rather
than four that drift apart.

A language in this shape subclasses this rather than L<Configd::Language>, and
says only what is its own: its files, its units, and which of its directives may
be said more than once or accumulate.

It lives under C<Configd::Syntax::> rather than C<Configd::Language::> because
L<Configd> finds languages by looking for modules under the latter, and a base
class put there would be offered as a language somebody could adopt.

=head1 NAME

Configd::Syntax::Spaced - config files that are a directive, some whitespace and
a value.

=head1 METHODS

=head2 $language->parse($text)

The directives in a fragment.  Comments and blank lines come back as text with
no key, so they keep their place in a file that is not merged.

=head2 $language->emit($directives)

The file those directives make.

Written as C<directive value>, one space, rather than reproducing whatever
column alignment the original had.  Alignment is a property of a file somebody
maintained by hand, and this file is generated from several of them.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Language>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
