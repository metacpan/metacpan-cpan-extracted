package App::CSVUtils::csv_sorted_fields;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-10'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.022'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );
use App::CSVUtils::csv_sort_fields;

gen_csv_util(
    name => 'csv_sorted_fields',
    summary => 'Check that CSV fields are sorted',
    description => <<'_',

This utility checks that fields in the CSV are sorted according to specified
sorting rule(s). Example `input.csv`:

    b,c,a
    1,2,3
    4,5,6

Example check command:

    % csv-sorted-fields input.csv; # check if the fields are ascibetically sorted
    ERROR 400: Fields are NOT sorted

Example `input2.csv`:

    c,b,a
    1,2,3
    4,5,6

    % csv-sorted-fields input2.csv -r
    Fields are sorted

See <prog:csv-sort-fields> for details on sorting options.

_

    writes_csv => 0,

    add_args => {
        # KEEP SYNC WITH csv_sort_fields
        %App::CSVUtils::argspecs_sort_fields,

        quiet => {
            summary => 'If set to true, do not show messages',
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },

    # KEEP SYNC WITH csv_sort_fields
    add_args_rels => {
        choose_one => ['by_examples', 'by_code', 'by_sortsub'],
    },

    on_input_header_row => sub {
        local $main::_CSV_SORTED_FIELDS = 1;
        App::CSVUtils::csv_sort_fields::on_input_header_row(@_);
    },

    on_input_data_row => sub {
        local $main::_CSV_SORTED_FIELDS = 1;
        App::CSVUtils::csv_sort_fields::on_input_data_row(@_);
    },
);

1;
# ABSTRACT: Check that CSV fields are sorted

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_sorted_fields - Check that CSV fields are sorted

=head1 VERSION

This document describes version 1.022 of App::CSVUtils::csv_sorted_fields (from Perl distribution App-CSVUtils), released on 2023-03-10.

=head1 FUNCTIONS


=head2 csv_sorted_fields

Usage:

 csv_sorted_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that CSV fields are sorted.

This utility checks that fields in the CSV are sorted according to specified
sorting rule(s). Example C<input.csv>:

 b,c,a
 1,2,3
 4,5,6

Example check command:

 % csv-sorted-fields input.csv; # check if the fields are ascibetically sorted
 ERROR 400: Fields are NOT sorted

Example C<input2.csv>:

 c,b,a
 1,2,3
 4,5,6
 
 % csv-sorted-fields input2.csv -r
 Fields are sorted

See L<csv-sort-fields> for details on sorting options.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Sort fields using Perl code.

C<$a> and C<$b> (or the first and second argument) will contain C<[$field_name,
$field_idx]>.

=item * B<by_examples> => I<array[str]>

Sort by a list of field names as examples.

=item * B<by_sortsub> => I<str>

Sort using a Sort::Sub routine.

When sorting rows, usually combined with C<--key> because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

=item * B<ci> => I<bool>

(No description)

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

=item * B<quiet> => I<bool>

If set to true, do not show messages.

=item * B<reverse> => I<bool>

(No description)

=item * B<sortsub_args> => I<hash>

Arguments to pass to Sort::Sub routine.


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
