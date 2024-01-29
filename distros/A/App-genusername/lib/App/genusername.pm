package App::genusername;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use App::genpw ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-16'; # DATE
our $DIST = 'App-genusername'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

my $default_patterns = [
    '%(wordlist:EN::Adjective::TalkEnglish)w%(wordlist:EN::Noun::TalkEnglish)(Str::ucfirst)w%4d',
];

my %args = %{$App::genpw::SPEC{genpw}{args}};
delete $args{min_len};
delete $args{max_len};
delete $args{len};

$SPEC{genusername} = {
    v => 1.1,
    summary => 'Generate random username',
    description => <<'MARKDOWN',

This is a thin wrapper for <prog:genpw>.

MARKDOWN
    args => {
        %args,
    },
    examples => [
    ],
};
sub genusername {
    my %args = @_;

    my $patterns = delete($args{patterns}) // $default_patterns;
    App::genpw::genpw(
        %args,
        patterns => $patterns,
    );
}

1;
# ABSTRACT: Generate random username

__END__

=pod

=encoding UTF-8

=head1 NAME

App::genusername - Generate random username

=head1 VERSION

This document describes version 0.001 of App::genusername (from Perl distribution App-genusername), released on 2024-01-16.

=head1 SYNOPSIS

See the included script L<genusername>.

=head1 FUNCTIONS


=head2 genusername

Usage:

 genusername(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate random username.

This is a thin wrapper for L<genpw>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "gen")

(No description)

=item * B<case> => I<str> (default: "default")

Force casing.

C<default> means to not change case. C<random> changes casing some letters
randomly to lower-/uppercase. C<lower> forces lower case. C<upper> forces
UPPER CASE. C<title> forces Title case.

=item * B<num> => I<int> (default: 1)

(No description)

=item * B<patterns> => I<array[str]>

Pattern(s) to use.

CONVERSION (C<%P>). A pattern is string that is roughly similar to a printf
pattern:

 %P

where C<P> is certain letter signifying a conversion. This will be replaced with
some other string according to the conversion. An example is the C<%h> conversion
which will be replaced with hexdigit.

LENGTH (C<%NP>). A non-negative integer (C<N>) can be specified before the
conversion to signify desired length, for example, C<%4w> will return a random
word of length 4.

MINIMUM AND MAXIMUM LENGTH (C<%M$NP>). If two non-negative integers separated by
C<$> is specified before the conversion, this specify desired minimum and maximum
length. For example, C<%4$10h> will be replaced with between 4 and 10 hexdigits.

ARGUMENT AND FILTERS (C<%(arg)P>, C<%(arg)(filter1)(...)P>). Finally, an argument
followed by zero or more filters can be specified (before the lengths) and
before the conversion. For example, C<%(wordlist:ID::KBBI)w> will be replaced by
a random word from the wordlist L<WordList::ID::KBBI>. Another example,
C<%()(Str::uc)4$10h> will be replaced by between 4-10 uppercase hexdigits, and
C<%(arraydata:Sample::DeNiro)(Str::underscore_non_latin_alphanums)(Str::lc)(Str::ucfirst)w>
will be replaced with a random movie title of Robert De Niro, where symbols are
replaced with underscore then the string will be converted into lowercase and
the first character uppercased, e.g. C<Dear_america_letters_home_from_vietnam>.

Anything else will be left as-is.

Available conversions:

 %l   Random Latin letter (A-Z, a-z)
 %d   Random digit (0-9)
 %h   Random hexdigit (0-9a-f in lowercase [default] or 0-9A-F in uppercase).
      Known arguments:
      - "u" (to use the uppercase instead of the default lowercase digits)
 %a   Random letter/digit (Alphanum) (A-Z, a-z, 0-9; combination of %l and %d)
 %s   Random ASCII symbol, e.g. "-" (dash), "_" (underscore), etc.
 %x   Random letter/digit/ASCII symbol (combination of %a and %s)
 %m   Base64 character (A-Z, a-z, 0-9, +, /)
 %b   Base58 character (A-Z, a-z, 0-9 minus IOl0)
 %B   Base56 character (A-Z, a-z, 0-9 minus IOol01)
 %%   A literal percent sign
 %w   Random word. Known arguments:
      - "stdin:" (for getting the words from stdin, the default)
      - "wordlist:NAME" (for getting the words from a L<WordList> module)
      - "arraydata:NAME" (for getting the words from an L<ArrayData> module, the
        Role::TinyCommons::Collection::PickItems::RandomPos will be applied).

Filters are modules in the C<Data::Sah::Filter::perl::> namespace.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-genusername>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-genusername>.

=head1 SEE ALSO

L<genpw> (from L<App::genpw>)

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-genusername>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
