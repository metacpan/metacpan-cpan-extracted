package App::CSVUtils::csv_uniq;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-04'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.036'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );

gen_csv_util(
    name => 'csv_uniq',
    summary => 'Report or omit duplicated values in CSV',
    add_args => {
        %App::CSVUtils::argspec_fields_1plus,
        ignore_case => {
            summary => 'Ignore case when comparing',
            schema => 'true*',
            cmdline_aliases => {i=>{}},
        },
        unique => {
            summary => 'Instead of reporting duplicate values, report unique values instead',
            schema => 'true*',
        },
    },
    examples => [
        {
            summary => 'Check that field "foo" in CSV is unique, compare case-insensitively, report duplicates',
            argv => ['file.csv', '-i', 'foo'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Check that combination of fields "foo", "bar", "baz" in CSV is unique, report duplicates',
            argv => ['file.csv', 'foo', 'bar', 'baz'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    writes_csv => 0,

    tags => ['category:filtering'],

    on_input_header_row => sub {
        my $r = shift;

        # we add this key to the stash
        $r->{seen} = {};
        $r->{fields_idx} = [];

        # check arguments
        for my $field (@{ $r->{util_args}{fields} }) {
            push @{ $r->{fields_idx} }, App::CSVUtils::_find_field($r->{input_fields}, $field);
        }
    },

    on_input_data_row => sub {
        my $r = shift;

        my @vals;
        for my $field_idx (@{ $r->{fields_idx} }) {
            my $fieldval = $r->{input_row}[ $field_idx ] // '';
            push @vals, $r->{util_args}{ignore_case} ? lc($fieldval) : $fieldval;
        }
        my $val = join("|", @vals);
        $r->{seen}{$val}++;
        unless ($r->{util_args}{unique}) {
            print "csv-uniq: Duplicate value '$val'\n" if $r->{seen}{$val} == 2;
        }
    },

    on_end => sub {
        my $r = shift;

        if ($r->{util_args}{unique}) {
            for my $val (sort keys %{ $r->{seen} }) {
                print "csv-uniq: Unique value '$val'\n" if $r->{seen}{$val} == 1;
            }
        }
    },
);

1;
# ABSTRACT: Report or omit duplicated values in CSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_uniq - Report or omit duplicated values in CSV

=head1 VERSION

This document describes version 1.036 of App::CSVUtils::csv_uniq (from Perl distribution App-CSVUtils), released on 2025-02-04.

=head1 FUNCTIONS


=head2 csv_uniq

Usage:

 csv_uniq(%args) -> [$status_code, $reason, $payload, \%result_meta]

Report or omit duplicated values in CSV.

Examples:

=over

=item * Check that field "foo" in CSV is unique, compare case-insensitively, report duplicates:

 csv_uniq(input_filename => "file.csv", fields => ["foo"], ignore_case => 1);

=item * Check that combination of fields "foo", "bar", "baz" in CSV is unique, report duplicates:

 csv_uniq(input_filename => "file.csv", fields => ["foo", "bar", "baz"]);

=back

(No description)

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fields>* => I<array[str]>

Field names.

=item * B<ignore_case> => I<true>

Ignore case when comparing.

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

=item * B<input_skip_num_lines> => I<posint>

Number of lines to skip before header row.

This can be useful if you have a CSV files (usually some generated reports,
sometimes converted from spreadsheet) that have additional header lines or info
before the CSV header row.

See also the alternative option: C<--input-skip-until-pattern>.

=item * B<input_skip_until_pattern> => I<re_from_str>

Skip rows until the first header row matches a regex pattern.

This is an alternative to the C<--input-skip-num-lines> and can be useful if you
have a CSV files (usually some generated reports, sometimes converted from
spreadsheet) that have additional header lines or info before the CSV header
row.

With C<--input-skip-num-lines>, you skip a fixed number of lines. With this
option, rows will be skipped until the first field matches the specified regex
pattern.

=item * B<input_tsv> => I<true>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--input-sep-char>, C<--input-quote-char>, C<--input-escape-char>
options. If one of those options is specified, then C<--input-tsv> will be
ignored.

=item * B<unique> => I<true>

Instead of reporting duplicate values, report unique values instead.


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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
