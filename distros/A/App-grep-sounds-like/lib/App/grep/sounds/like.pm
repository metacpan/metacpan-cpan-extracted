package App::grep::sounds::like;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use List::Util qw(min);
use Perinci::Sub::Util qw(gen_modified_sub);
use Text::Levenshtein::XS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-20'; # DATE
our $DIST = 'App-grep-sounds-like'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'grep_sounds_like',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines with words that sound like to the specified word',
    description => <<'MARKDOWN',

This is a grep-like utility that greps for text in input that has word(s) that
sound like the specified text. By default uses the `Metaphone` algorithm.

MARKDOWN
    remove_args => [
        'regexps',
        'pattern',
        'dash_prefix_inverts',
        'all',
    ],
    add_args    => {
        word => {
            summary => 'Word to compare',
            schema => 'str*',
            req => 1,
            pos => 0,
            tags => ['category:filtering'],
        },
        algo => {
            summary => 'Phonetic algorithm to use, should be a module under `Text::Phonetic::` without the prefix',
            schema => 'perl::modname*',
            default => 'Metaphone',
            completion => sub {
                require Complete::Module;
                my %args = @_;
                Complete::Module::complete_module(word => $args{word}, ns_prefix => 'Text::Phonetic::');
            },
            tags => ['category:filtering'],
        },
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            pos => 1,
            slurpy => 1,
        },

        # XXX recursive (-r)
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{examples} = [
            {
                summary => 'Show lines that have word(s) similar to "orange"',
                'src' => q([[prog]] orange file.txt),
                'src_plang' => 'bash',
                'test' => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} = [
        ];
    },
    output_code => sub {
        my %args = @_;
        my ($fh, $file);

        my @files = @{ delete($args{files}) // [] };

        my $show_label = 0;
        if (!@files) {
            $fh = \*STDIN;
        } elsif (@files > 1) {
            $show_label = 1;
        }

        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "grep-sounds-like: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $show_label ? $file : undef);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        my $phonetic_mod = "Text::Phonetic::" . ($args{algo} // 'Metaphone');
        (my $phoneitc_mod_pm = "$phonetic_mod.pm") =~ s!::!/!g;
        require $phoneitc_mod_pm;
        my $phonetic_obj = $phonetic_mod->new;

        $args{_filter_code} = sub {
            my ($line, $fargs, $ansi_highlight_seq) = @_;

            my @words = $line =~ /(\w+)/g;
            my @matching_words;
            for (@words) { push @matching_words, $_ if $phonetic_obj->compare($_, $args{word}) }

            return [0] unless @matching_words;
            my $re = join("|", map {quotemeta($_)} @matching_words);

            (my $highlighted_line = $line) =~ s/($re)/$ansi_highlight_seq$1\e[0m/g;
            [1, $highlighted_line];
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines with words that sound like to the specified word

__END__

=pod

=encoding UTF-8

=head1 NAME

App::grep::sounds::like - Print lines with words that sound like to the specified word

=head1 VERSION

This document describes version 0.001 of App::grep::sounds::like (from Perl distribution App-grep-sounds-like), released on 2024-11-20.

=head1 FUNCTIONS


=head2 grep_sounds_like

Usage:

 grep_sounds_like(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines with words that sound like to the specified word.

This is a grep-like utility that greps for text in input that has word(s) that
sound like the specified text. By default uses the C<Metaphone> algorithm.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<algo> => I<perl::modname> (default: "Metaphone")

Phonetic algorithm to use, should be a module under `Text::Phonetic::` without the prefix.

=item * B<color> => I<str> (default: "auto")

Specify when to show color (never, always, or autoE<sol>when interactive).

=item * B<count> => I<true>

Supress normal output; instead return a count of matching lines.

=item * B<files> => I<array[filename]>

(No description)

=item * B<files_with_matches> => I<true>

Supress normal output; instead return filenames with matching lines; scanning for each file will stop on the first match.

=item * B<files_without_match> => I<true>

Supress normal output; instead return filenames without matching lines.

=item * B<ignore_case> => I<bool>

If set to true, will search case-insensitively.

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

Show line number along with matches.

=item * B<quiet> => I<true>

Do not print matches, only return appropriate exit code.

=item * B<word>* => I<str>

Word to compare.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-grep-sounds-like>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-grep-sounds-like>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-grep-sounds-like>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
