package App::grep::similar::text;

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
our $DIST = 'App-grep-similar-text'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'grep_similar_text',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines similar to the specified text',
    description => <<'MARKDOWN',

This is a grep-like utility that greps for text in input similar to the
specified text. Measure of similarity can be adjusted using these options:
`--max-edit-distance` (`-M`).

MARKDOWN
    remove_args => [
        'regexps',
        'pattern',
        'dash_prefix_inverts',
        'all',
    ],
    add_args    => {
        max_edit_distance => {
            schema => 'uint',
            tags => ['category:filtering'],
            description => <<'MARKDOWN',

If not specified, a sensible default will be calculated as follow:

    int( min(len(text), len(input_text)) / 1.3)

MARKDOWN
        },
        string => {
            summary => 'String to compare similarity of each line of input to',
            schema => 'str*',
            req => 1,
            pos => 0,
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
                summary => 'Show lines that are similar to the text "foobar"',
                'src' => q([[prog]] foobar file.txt),
                'src_plang' => 'bash',
                'test' => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} = [
            {url => 'prog:grep-sounds-like'},
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
                        warn "grep-similar-text: Can't open '$file': $!, skipped\n";
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

        $args{_filter_code} = sub {
            my ($line, $fargs) = @_;

            my $dist = Text::Levenshtein::XS::distance($fargs->{string}, $line);
            my $maxdist = $fargs->{max_edit_distance} //
                int(min(length($fargs->{string}), length($line))/1.3);
            $dist <= $maxdist;
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines similar to the specified text

__END__

=pod

=encoding UTF-8

=head1 NAME

App::grep::similar::text - Print lines similar to the specified text

=head1 VERSION

This document describes version 0.002 of App::grep::similar::text (from Perl distribution App-grep-similar-text), released on 2024-11-20.

=head1 FUNCTIONS


=head2 grep_similar_text

Usage:

 grep_similar_text(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines similar to the specified text.

This is a grep-like utility that greps for text in input similar to the
specified text. Measure of similarity can be adjusted using these options:
C<--max-edit-distance> (C<-M>).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

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

=item * B<max_edit_distance> => I<uint>

If not specified, a sensible default will be calculated as follow:

 int( min(len(text), len(input_text)) / 1.3)

=item * B<quiet> => I<true>

Do not print matches, only return appropriate exit code.

=item * B<string>* => I<str>

String to compare similarity of each line of input to.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-grep-similar-text>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-grep-similar-text>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-grep-similar-text>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
