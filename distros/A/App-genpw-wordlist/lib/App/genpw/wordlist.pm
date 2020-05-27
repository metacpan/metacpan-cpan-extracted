package App::genpw::wordlist;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-22'; # DATE
our $DIST = 'App-genpw-wordlist'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use App::genpw ();
use App::wordlist ();
use List::Util qw(shuffle);

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
        %App::wordlist::arg_wordlists,
    },
    examples => [
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

This document describes version 0.009 of App::genpw::wordlist (from Perl distribution App-genpw-wordlist), released on 2020-05-22.

=head1 SYNOPSIS

See the included script L<genpw-wordlist>.

=head1 FUNCTIONS


=head2 genpw

Usage:

 genpw(%args) -> [status, msg, payload, meta]

Generate password with words from WordList::*.

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

=item * B<case> => I<str> (default: "default")

Force casing.

C<default> means to not change case. C<random> changes casing some letters
randomly to lower-/uppercase. C<lower> forces lower case. C<upper> forces
UPPER CASE. C<title> forces Title case.

=item * B<num> => I<int> (default: 1)

=item * B<patterns> => I<array[str]>

Pattern(s) to use.

A pattern is string that is similar to a printf pattern. %P (where P is certain
letter signifying a format) will be replaced with some other string. %Nw (where
N is a number) will be replaced by a word of length N, %N$MP (where N and M is a
number) will be replaced by a word of length between N and M. Anything else will
be used as-is. Available conversions:

 %l   Random Latin letter (A-Z, a-z)
 %d   Random digit (0-9)
 %h   Random hexdigit (0-9a-f)
 %a   Random letter/digit (Alphanum) (A-Z, a-z, 0-9; combination of %l and %d)
 %s   Random ASCII symbol, e.g. "-" (dash), "_" (underscore), etc.
 %x   Random letter/digit/ASCII symbol (combination of %a and %s)
 %m   Base64 character (A-Z, a-z, 0-9, +, /)
 %b   Base58 character (A-Z, a-z, 0-9 minus IOl0)
 %B   Base56 character (A-Z, a-z, 0-9 minus IOol01)
 %%   A literal percent sign
 %w   Random word

=item * B<wordlists> => I<array[str]>

Select one or more wordlist modules.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-genpw-wordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-genpw-wordlist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-genpw-wordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<genpw> (from L<App::genpw>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
