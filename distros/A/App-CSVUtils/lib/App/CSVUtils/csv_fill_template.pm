package App::CSVUtils::csv_fill_template;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.031'; # VERSION

use App::CSVUtils qw(gen_csv_util);

gen_csv_util(
    name => 'csv_fill_template',
    summary => 'Substitute template values in a text file with fields from CSV rows',
    description => <<'_',

Templates are text that contain `[[NAME]]` field placeholders. The field
placeholders will be replaced by values from the CSV file. This is a simple
alternative to mail-merge. (I first wrote this utility because LibreOffice
Writer, as always, has all the annoying bugs; that particular time, one that
prevented mail merge from working.)

Example:

    % cat madlib.txt
    Today I went to the park. I saw a(n) [[adjective1]] [[noun1]] running
    towards me. It looked hungry, really hungry. Horrified and terrified, I took
    a(n) [[adjective2]] [[noun2]] and waved the thing [[adverb1]] towards it.
    [[adverb2]], when it arrived at my feet, it [[verb1]] and [[verb2]] me
    instead. I was relieved, the [[noun1]] was a friendly creature after all.
    After we [[verb3]] for a little while, I went home with a(n) [[noun3]] on my
    face. That was an unforgettable day indeed.

    % cat values.csv
    adjective1,adjective2,adjective3,noun1,noun2,noun3,verb1,verb2,verb3,adverb1,adverb2
    slow,gigantic,sticky,smartphone,six-wheeler truck,lollipop,piece of tissue,threw,kissed,stared,angrily,hesitantly
    sweet,delicious,red,pelican,bottle of parfume,desk,exercised,jumped,slept,confidently,passively

    % csv-fill-template values.csv madlib.txt
    Today I went to the park. I saw a(n) slow six-wheeler truck running
    towards me. It looked hungry, really hungry. Horrified and terrified, I took
    a(n) gigantic lollipop and waved the thing angrily towards it.
    hesitantly, when it arrived at my feet, it threw and kissed me
    instead. I was relieved, the six-wheeler truck was a friendly creature after all.
    After we stared for a little while, I went home with a(n) piece of tissue on my
    face. That was an unforgettable day indeed.

    ---
    Today I went to the park. I saw a(n) sweet pelican running
    towards me. It looked hungry, really hungry. Horrified and terrified, I took
    a(n) delicious bottle of parfume and waved the thing confidently towards it.
    passively, when it arrived at my feet, it exercised and jumped me
    instead. I was relieved, the pelican was a friendly creature after all.
    After we slept for a little while, I went home with a(n) desk on my
    face. That was an unforgettable day indeed.

_

    add_args => {
        template_filename => {
            schema => 'filename*',
            req => 1,
            pos => 1,
        },
    },
    tags => ['category:templating'],

    examples => [
    ],

    writes_csv => 0,

    on_begin => sub {
        my $r = shift;
        $r->{wants_input_row_as_hashref}++;

        require File::Slurper::Dash;

        my $template = File::Slurper::Dash::read_text($r->{util_args}{template_filename});

        # this is the key we add to the stash
        $r->{template} = $template;
        $r->{filled_template} = '';
    },

    on_input_data_row => sub {
        my $r = shift;

        my $text = $r->{template};
        $text =~ s/\[\[(.+?)\]\]/defined $r->{input_row_as_hashref}{$1} ? $r->{input_row_as_hashref}{$1} : "[[UNDEFINED:$1]]"/eg;
        $r->{filled_templates} .= (length $r->{filled_template} ? "\n---\n" : "") . $text;
    },

    writes_csv => 0,

    on_end => sub {
        my $r = shift;
        $r->{result} = [200, "OK", $r->{filled_templates}];
    },
);

1;
# ABSTRACT: Substitute template values in a text file with fields from CSV rows

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_fill_template - Substitute template values in a text file with fields from CSV rows

=head1 VERSION

This document describes version 1.031 of App::CSVUtils::csv_fill_template (from Perl distribution App-CSVUtils), released on 2023-08-06.

=head1 FUNCTIONS


=head2 csv_fill_template

Usage:

 csv_fill_template(%args) -> [$status_code, $reason, $payload, \%result_meta]

Substitute template values in a text file with fields from CSV rows.

Templates are text that contain C<[[NAME]]> field placeholders. The field
placeholders will be replaced by values from the CSV file. This is a simple
alternative to mail-merge. (I first wrote this utility because LibreOffice
Writer, as always, has all the annoying bugs; that particular time, one that
prevented mail merge from working.)

Example:

 % cat madlib.txt
 Today I went to the park. I saw a(n) [[adjective1]] [[noun1]] running
 towards me. It looked hungry, really hungry. Horrified and terrified, I took
 a(n) [[adjective2]] [[noun2]] and waved the thing [[adverb1]] towards it.
 [[adverb2]], when it arrived at my feet, it [[verb1]] and [[verb2]] me
 instead. I was relieved, the [[noun1]] was a friendly creature after all.
 After we [[verb3]] for a little while, I went home with a(n) [[noun3]] on my
 face. That was an unforgettable day indeed.
 
 % cat values.csv
 adjective1,adjective2,adjective3,noun1,noun2,noun3,verb1,verb2,verb3,adverb1,adverb2
 slow,gigantic,sticky,smartphone,six-wheeler truck,lollipop,piece of tissue,threw,kissed,stared,angrily,hesitantly
 sweet,delicious,red,pelican,bottle of parfume,desk,exercised,jumped,slept,confidently,passively
 
 % csv-fill-template values.csv madlib.txt
 Today I went to the park. I saw a(n) slow six-wheeler truck running
 towards me. It looked hungry, really hungry. Horrified and terrified, I took
 a(n) gigantic lollipop and waved the thing angrily towards it.
 hesitantly, when it arrived at my feet, it threw and kissed me
 instead. I was relieved, the six-wheeler truck was a friendly creature after all.
 After we stared for a little while, I went home with a(n) piece of tissue on my
 face. That was an unforgettable day indeed.
 
 ---
 Today I went to the park. I saw a(n) sweet pelican running
 towards me. It looked hungry, really hungry. Horrified and terrified, I took
 a(n) delicious bottle of parfume and waved the thing confidently towards it.
 passively, when it arrived at my feet, it exercised and jumped me
 instead. I was relieved, the pelican was a friendly creature after all.
 After we slept for a little while, I went home with a(n) desk on my
 face. That was an unforgettable day indeed.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input_escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--input-tsv> option.

=item * B<input_filename> => I<filename> (default: "-")

Input CSV file.

Use C<-> to read from stdin.

Encoding of input file is assumed to be UTF-8.

=item * B<input_header> => I<bool> (default: 1)

Specify whether input CSV has a header row.

By default, the first row of the input CSV will be assumed to contain field
names (and the second row contains the first data row). When you declare that
input CSV does not have header row (C<--no-input-header>), the first row of the
CSV is assumed to contain the first data row. Fields will be named C<field1>,
C<field2>, and so on.

=item * B<input_quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--input-tsv> option.

=item * B<input_sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--input-tsv> option.

=item * B<input_tsv> => I<true>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--input-sep-char>, C<--input-quote-char>, C<--input-escape-char>
options. If one of those options is specified, then C<--input-tsv> will be
ignored.

=item * B<template_filename>* => I<filename>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CSVUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CSVUtils>.

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
