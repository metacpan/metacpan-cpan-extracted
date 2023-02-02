package App::CSVUtils::csv_sorted_rows;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-02'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.005'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );
use App::CSVUtils::csv_sort_rows;

gen_csv_util(
    name => 'csv_sorted_rows',
    summary => 'Check that CSV rows are sorted',
    description => <<'_',

This utility checks that rows in the CSV are sorted according to specified
sorting rule(s). Example `input.csv`:

    name,age
    Andy,20
    Dennis,15
    Ben,30
    Jerry,30

Example check command:

    % csv-sorted-rows input.csv --by-field name; # check if name is ascibetically sorted
    ERROR 400: Rows are NOT sorted

Example `input2.csv`:

    name,age
    Andy,20
    Ben,30
    Dennis,15
    Jerry,30

    % csv-sorted-rows input2.csv --by-field name; # check if name is ascibetically sorted
    Rows are sorted

    % csv-sorted-rows input2.csv --by-field ~name; # check if name is ascibetically sorted in descending order
    ERROR 400: Rows are NOT sorted

See <prog:csv-sort-rows> for details on sorting options.

_

    writes_csv => 0,

    add_args => {
        # KEEP SYNC WITH csv_sort_rows
        %App::CSVUtils::argspecopt_hash,
        %App::CSVUtils::argspecs_sort_rows,

        quiet => {
            summary => 'If set to true, do not show messages',
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },

    # KEEP SYNC WITH csv_sort_rows
    add_args_rels => {
        req_one => ['by_fields', 'by_code', 'by_sortsub'],
    },

    on_input_header_row => \&App::CSVUtils::csv_sort_rows::on_input_header_row,

    on_input_data_row => \&App::CSVUtils::csv_sort_rows::on_input_data_row,

    after_close_input_files => sub {
        local $main::_CSV_SORTED_ROWS = 1;
        App::CSVUtils::csv_sort_rows::after_close_input_files(@_);
    },
);

1;
# ABSTRACT: Check that CSV rows are sorted

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_sorted_rows - Check that CSV rows are sorted

=head1 VERSION

This document describes version 1.005 of App::CSVUtils::csv_sorted_rows (from Perl distribution App-CSVUtils), released on 2023-02-02.

=head1 FUNCTIONS


=head2 csv_sorted_rows

Usage:

 csv_sorted_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that CSV rows are sorted.

This utility checks that rows in the CSV are sorted according to specified
sorting rule(s). Example C<input.csv>:

 name,age
 Andy,20
 Dennis,15
 Ben,30
 Jerry,30

Example check command:

 % csv-sorted-rows input.csv --by-field name; # check if name is ascibetically sorted
 ERROR 400: Rows are NOT sorted

Example C<input2.csv>:

 name,age
 Andy,20
 Ben,30
 Dennis,15
 Jerry,30
 
 % csv-sorted-rows input2.csv --by-field name; # check if name is ascibetically sorted
 Rows are sorted
 
 % csv-sorted-rows input2.csv --by-field ~name; # check if name is ascibetically sorted in descending order
 ERROR 400: Rows are NOT sorted

See L<csv-sort-rows> for details on sorting options.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Sort by using Perl code.

C<$a> and C<$b> (or the first and second argument) will contain the two rows to be
compared. Which are arrayrefs; or if C<--hash> (C<-H>) is specified, hashrefs; or
if C<--key> is specified, whatever the code in C<--key> returns.

=item * B<by_fields> => I<array[str]>

Sort by a list of field specifications.

Each field specification is a field name with an optional prefix. C<FIELD>
(without prefix) means sort asciibetically ascending (smallest to largest),
C<~FIELD> means sort asciibetically descending (largest to smallest), C<+FIELD>
means sort numerically ascending, C<-FIELD> means sort numerically descending.

=item * B<by_sortsub> => I<str>

Sort using a Sort::Sub routine.

When sorting rows, usually combined with C<--key> because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

=item * B<ci> => I<bool>

(No description)

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

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

=item * B<key> => I<str|code>

Generate sort keys with this Perl code.

If specified, then will compute sort keys using Perl code and sort using the
keys. Relevant when sorting using C<--by-code> or C<--by-sortsub>. If specified,
then instead of row when sorting rows, the code (or Sort::Sub routine) will
receive these sort keys to sort against.

The code will receive the row (arrayref, or if -H is specified, hashref) as the
argument.

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
