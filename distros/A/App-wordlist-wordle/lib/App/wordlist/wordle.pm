## no critic: InputOutput::ProhibitInteractiveTest
package App::wordlist::wordle;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::wordlist ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-07'; # DATE
our $DIST = 'App-wordlist-wordle'; # DIST
our $VERSION = '0.295'; # VERSION

our %SPEC;

gen_modified_sub(
    base_name => 'App::wordlist::wordlist',
    output_name => 'wordlist_wordle',
    modify_args => {
        wordlists => sub {
            $_[0]{default} = ['EN::Wordle'];
        },
        len => sub {
            $_[0]{default} = 5;
        },
    },
    remove_args => [
        'action',
        'lcpan',
        'chars_unordered',
        'chars_ordered',
    ],
    modify_meta => sub {
        $_[0]{summary} = 'Help solve Wordle';
        delete $_[0]{'x.doc.faq'};
        $_[0]{description} = <<'MARKDOWN';

This is a wrapper to <prog:wordlist> designed to be a convenient helper to solve
Wordle puzzle. By default it greps from the `EN::Wordle` wordlist. It accepts
a series of guesses in a format like the following:

    A^R^isE^
    Pound
    might
    blA^ck
    PR^ivY^

where lowercase means wrong guess, uppercase means correct letter and position,
while (uppercase) letter followed by a caret (`^`) means the letter exists in
another position. It will convert these guesses to regex patterns and the
`--chars-unordered` option and pass it to `wordlist`.

MARKDOWN
        $_[0]{examples} = [
            {
                argv => ['cR^eEk'],
                summary => 'One guess',
                test => 0,
                'x.doc.show_result' => 0,
            },
            {
                argv => ['A^R^isE^', 'Pound', 'might', 'blA^ck', 'PR^ivY^'],
                summary => 'Five guesses',
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];
    },
    output_code => sub {
        my %args = @_;

        $args{arg} //= [];

        my $chars_unordered = '';
        my $possible_letters = join '', "a".."z";
        my @new_arg;
        for my $arg (@{ $args{arg} }) {
            my @chars = split //, $arg;
            my $re = '';
            my %letter_exists;
            while (@chars) {
                my $char = shift @chars;
                return [400, "Invalid letter '$char' in guess '$arg'"] unless $char =~ /[A-Za-z]/;
                my $caret = @chars && $chars[0] eq '^' ? shift(@chars) : '';
                my $uc = $char eq uc $char;
                $char = lc $char;

                if ($caret) { # letter is in another position
                    my $letters = $possible_letters;
                    $letters =~ s/$char//;
                    $re .= "[$letters]";
                    $letter_exists{$char}++;
                    $chars_unordered .= $char unless index($chars_unordered, $char) >= 0;
                } elsif ($uc) { # correct guess
                    $re .= $char;
                    $letter_exists{$char}++;
                    $chars_unordered .= $char unless index($chars_unordered, $char) >= 0;
                } else { # wrong guess
                    my $letters = $possible_letters;
                    $letters =~ s/$char//;
                    $possible_letters =~ s/$char// unless $letter_exists{$char};
                    $re .= "[$letters]";
                }
            }
            $re = "/\\A$re\\z/";
            push @new_arg, $re;
        }

        $args{arg} = \@new_arg;
        $args{chars_unordered} = $chars_unordered if length $chars_unordered;

        log_trace "Arguments passed to wordlist(): %s", \%args;
        App::wordlist::wordlist(%args);
    },
);

1;
# ABSTRACT: A wordlist wrapper to help solve Wordle

__END__

=pod

=encoding UTF-8

=head1 NAME

App::wordlist::wordle - A wordlist wrapper to help solve Wordle

=head1 VERSION

This document describes version 0.295 of App::wordlist::wordle (from Perl distribution App-wordlist-wordle), released on 2025-03-07.

=head1 FUNCTIONS


=head2 wordlist_wordle

Usage:

 wordlist_wordle(%args) -> [$status_code, $reason, $payload, \%result_meta]

Help solve Wordle.

Examples:

=over

=item * One guess:

 wordlist_wordle(arg => ["cR^eEk"]);

=item * Five guesses:

 wordlist_wordle(arg => ["A^R^isE^", "Pound", "might", "blA^ck", "PR^ivY^"]);

=back

This is a wrapper to L<wordlist> designed to be a convenient helper to solve
Wordle puzzle. By default it greps from the C<EN::Wordle> wordlist. It accepts
a series of guesses in a format like the following:

 A^R^isE^
 Pound
 might
 blA^ck
 PR^ivY^

where lowercase means wrong guess, uppercase means correct letter and position,
while (uppercase) letter followed by a caret (C<^>) means the letter exists in
another position. It will convert these guesses to regex patterns and the
C<--chars-unordered> option and pass it to C<wordlist>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg> => I<array[str]>

(No description)

=item * B<color> => I<str> (default: "auto")

When to highlight search stringE<sol>matching pattern with color.

=item * B<detail> => I<bool>

Display more information when listing modulesE<sol>result.

When listing installed modules (C<-l>), this means also returning a wordlist's
language.

When returning grep result, this means also returning wordlist name.

=item * B<exclude_dynamic_wordlists> => I<bool>

(No description)

=item * B<exclude_wordlist_pattern> => I<re_from_str>

(No description)

=item * B<exclude_wordlists> => I<array[str]>

Exclude wordlist modules.

=item * B<ignore_case> => I<bool> (default: 1)

(No description)

=item * B<langs> => I<array[str]>

Only include wordlists of certain language(s).

By convention, language code is the first subnamespace of a wordlist module,
e.g. WordList::EN::* for English, WordList::FR::* for French, and so on.
Wordlist modules which do not follow this convention (e.g. WordList::Password::*
or WordList::PersonName::*) are not included.

=item * B<len> => I<int> (default: 5)

(No description)

=item * B<max_len> => I<int>

(No description)

=item * B<min_len> => I<int>

(No description)

=item * B<num> => I<int> (default: 0)

Return (at most) this number of words (0 = unlimited).

=item * B<or> => I<bool>

Instead of printing words that must match all queries (the default), print words that match any query.

=item * B<random> => I<bool>

Pick random words.

If set to true, then streaming will be turned off. All words will be gathered
first, then words will be chosen randomly from the gathered list.

=item * B<wordlist_bundles> => I<array[str]>

Select one or more wordlist bundle (Acme::CPANModules::WordListBundle::*) modules.

=item * B<wordlists> => I<array[str]> (default: ["EN::Wordle"])

Select one or more wordlist modules.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-wordlist-wordle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-wordlist-wordle>.

=head1 SEE ALSO

Wordle game, L<https://www.nytimes.com/games/wordle/index.html>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-wordlist-wordle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
