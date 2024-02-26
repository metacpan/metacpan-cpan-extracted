package App::genpw::wordlist;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use App::genpw ();
use App::wordlist ();
use List::Util qw(shuffle);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-23'; # DATE
our $DIST = 'App-genpw-wordlist'; # DIST
our $VERSION = '0.010'; # VERSION

our %SPEC;

my $default_patterns = [
    '%w %w %w',
    '%w %w %w %w',
    '%w %w %w %w %w',
    '%w %w %w %w %w %w',
    '%w%4d%w',
    '%w%6d%s',
];

my %args = %{$App::genpw::SPEC{genpw}{args}};
delete $args{min_len};
delete $args{max_len};
delete $args{len};

$SPEC{genpw} = {
    v => 1.1,
    summary => 'Generate password with words from WordList::*',
    description => <<'_',

Using password from dictionary words (in this case, from WordList::*) can be
useful for humans when remembering the password. Note that using a string of
random characters is generally better because of the larger space (combination).
Using a password of two random words from a 5000-word wordlist has a space of
only ~25 million while an 8-character of random uppercase letters/lowercase
letters/numbers has a space of 62^8 = ~218 trillion. To increase the space
you'll need to use more words (e.g. 3 to 5 instead of just 2). This is important
if you are using the password for something that can be bruteforced quickly e.g.
for protecting on-disk ZIP/GnuPG file and the attacker has access to your file.
It is then recommended to use a high number of rounds for hashing to slow down
password cracking (e.g. `--s2k-count 65011712` in GnuPG).

_
    args => {
        %args,
        #%App::wordlist::argspecopt_wordlists,
        wordlists => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'wordlist',
            schema => ['array*' => {
                of => 'perl::wordlist::modname_with_optional_args*', # for the moment we need to use 'str' instead of 'perl::wordlist::modname_with_optional_args' due to Perinci::Sub::GetArgs::Argv limitation
                'x.perl.coerce_rules'=>[ ['From_str_or_array::expand_perl_modname_wildcard'=>{ns_prefix=>"WordList"}] ],
            }],
            cmdline_aliases => {w=>{}},
        },
    },
    examples => [
        {
            summary=>'Generate some passwords from the default English (EN::Enable) wordlist',
            argv => [qw/-w ID::KBBI -n8/],
            test => 0,
            'x.doc.show_result' => 0, # TODO: currently result generation fails with obscure error
        },
        {
            summary=>'Generate some passwords from Indonesian words',
            argv => [qw/-w ID::KBBI -n8/],
            test => 0,
            'x.doc.show_result' => 0, # TODO: currently result generation fails with obscure error
        },
        {
            summary=>'Generate some passwords with specified pattern (see genpw documentation for details of pattern)',
            argv => [qw/-w ID::KBBI -n5 -p/, '%w%8$10d-%w%8$10d-%8$10d%w'],
            test => 0,
            'x.doc.show_result' => 0, # TODO: currently result generation fails with obscure error
        },
    ],
};
sub genpw {
    my %args = @_;

    my $wordlists = delete($args{wordlists}) // ['EN::Enable'];
    my $patterns = delete($args{patterns}) // $default_patterns;

    my ($words, $wl);
    unless ($args{action} && $args{action} eq 'list-patterns') {
        # optimize: when there is only one wordlist, pass wordlist object to
        # App::wordlist so it can use pick() which can be more efficient than
        # getting all the words first
        if (@$wordlists == 1) {
            my $mod = "WordList::$wordlists->[0]";
            (my $modpm = "$mod.pm") =~ s!::!/!g;
            require $modpm;
            if (!${"$mod\::DYNAMIC"}) {
                $wl = $mod->new;
                goto GENPW;
            }
        }

        my $res = App::wordlist::wordlist(
            (wordlists => $wordlists) x !!defined($wordlists),
            random => 1,
        );

        return $res unless $res->[0] == 200;
        $words = $res->[2];
    }

  GENPW:
    App::genpw::genpw(
        %args,
        patterns => $patterns,
        ($words ? (_words => $words) : ()),
        ($wl    ? (_wl    => $wl   ) : ()),
    );
}

1;
# ABSTRACT: Generate password with words from WordList::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::genpw::wordlist - Generate password with words from WordList::*

=head1 VERSION

This document describes version 0.010 of App::genpw::wordlist (from Perl distribution App-genpw-wordlist), released on 2024-01-23.

=head1 SYNOPSIS

See the included script L<genpw-wordlist>.

=head1 FUNCTIONS


=head2 genpw

Usage:

 genpw(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate password with words from WordList::*.

Examples:

=over

=item * Generate some passwords from the default English (EN::Enable) wordlist:

 genpw(num => 8, wordlists => ["ID::KBBI"]);

=item * Generate some passwords from Indonesian words:

 genpw(num => 8, wordlists => ["ID::KBBI"]);

=item * Generate some passwords with specified pattern (see genpw documentation for details of pattern):

 genpw(
     num => 5,
   patterns => ["%w%8\$10d-%w%8\$10d-%8\$10d%w"],
   wordlists => ["ID::KBBI"]
 );

=back

Using password from dictionary words (in this case, from WordList::*) can be
useful for humans when remembering the password. Note that using a string of
random characters is generally better because of the larger space (combination).
Using a password of two random words from a 5000-word wordlist has a space of
only ~25 million while an 8-character of random uppercase letters/lowercase
letters/numbers has a space of 62^8 = ~218 trillion. To increase the space
you'll need to use more words (e.g. 3 to 5 instead of just 2). This is important
if you are using the password for something that can be bruteforced quickly e.g.
for protecting on-disk ZIP/GnuPG file and the attacker has access to your file.
It is then recommended to use a high number of rounds for hashing to slow down
password cracking (e.g. C<--s2k-count 65011712> in GnuPG).

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

=item * B<wordlists> => I<array[perl::wordlist::modname_with_optional_args]>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-genpw-wordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-genpw-wordlist>.

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

This software is copyright (c) 2024, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-genpw-wordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
