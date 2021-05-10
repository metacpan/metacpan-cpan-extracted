package App::genpw::ind;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'App-genpw-ind'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::genpw::wordlist ();

our %SPEC;

$SPEC{genpw} = {
    v => 1.1,
    summary => 'Generate password from combination of Indonesian words',
    description => $App::genpw::wordlist::SPEC{genpw}{description},
    args => $App::genpw::wordlist::SPEC{genpw}{args},
    examples => [
    ],
};
sub genpw {

    my %args = @_;

    App::genpw::wordlist::genpw(
        (action => $args{action})     x !!defined($args{action}),
        (num => $args{num})           x !!defined($args{num}),
        (patterns => $args{patterns}) x !!defined($args{patterns}),
        wordlists => ['ID::KBBI'],
    );
}

1;
# ABSTRACT: Generate password from combination of Indonesian words

__END__

=pod

=encoding UTF-8

=head1 NAME

App::genpw::ind - Generate password from combination of Indonesian words

=head1 VERSION

This document describes version 0.007 of App::genpw::ind (from Perl distribution App-genpw-ind), released on 2021-05-07.

=head1 SYNOPSIS

See the included script L<genpw-ind>.

=head1 FUNCTIONS


=head2 genpw

Usage:

 genpw(%args) -> [status, msg, payload, meta]

Generate password from combination of Indonesian words.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-genpw-ind>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-genpw-ind>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-genpw-ind>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
