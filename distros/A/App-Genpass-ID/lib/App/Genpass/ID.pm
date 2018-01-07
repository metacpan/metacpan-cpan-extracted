package App::Genpass::ID;

our $DATE = '2018-01-02'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::Genpass::WordList ();

our %SPEC;

$SPEC{genpass} = {
    v => 1.1,
    summary => 'Generate password from combination of Indonesian words',
    description => $App::Genpass::WordList::SPEC{genpass}{description},
    args => {
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        %App::Genpass::WordList::arg_patterns,
    },
    examples => [
    ],
};
sub genpass {

    my %args = @_;

    App::Genpass::WordList::genpass(
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

App::Genpass::ID - Generate password from combination of Indonesian words

=head1 VERSION

This document describes version 0.003 of App::Genpass::ID (from Perl distribution App-Genpass-ID), released on 2018-01-02.

=head1 SYNOPSIS

See the included script L<genpass-id>.

=head1 FUNCTIONS


=head2 genpass

Usage:

 genpass(%args) -> [status, msg, result, meta]

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

=item * B<num> => I<int> (default: 1)

=item * B<patterns> => I<array[str]> (default: ["%w %w %w","%w %w %w %w","%w %w %w %w %w","%w %w %w %w %w %w","%W%4d%W","%W%6d%s"])

Pattern(s) to use.

A pattern is string that is similar to a printf pattern. %P (where P is certain
letter signifying a format) will be replaced with some other string. %NP (where
N is a number) will be replaced by a word of length N, %N$Mw (where N and M is a
number) will be replaced by a word of length between N and M. Anything else will
be used as-is. Available conversions:

 %w   Random word, all lowercase.
 %W   Random word, first letter uppercase, the rest lowercase.
 %s   Random ASCII symbol, e.g. "-" (dash), "_" (underscore), etc.
 %d   Random digit (0-9).
 %%   A literal percent sign.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-Genpass-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-Genpass-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Genpass-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
