package App::CSVUtils::csv_list_field_names;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-18'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.017'; # VERSION

use App::CSVUtils qw(gen_csv_util);

gen_csv_util(
    name => 'csv_list_field_names',
    summary => 'List field names of CSV file',
    description => <<'_',

_

    add_args => {
    },

    examples => [
        {
            summary => 'List field names of a CSV as a text table of name and position',
            argv => ['file.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List field names of a CSV as tab-separated lines, sort by name',
            src => '[[prog]] file.csv | sort',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    writes_csv => 0,

    on_input_header_row => sub {
        my $r = shift;

        $r->{result} = [
            200,
            "OK", [
                map { {name=>$_, index=>$r->{input_fields_idx}{$_}+1} }
                sort keys %{$r->{input_fields_idx}}
            ],
            {'table.fields'=>['name','index']},
        ];
        $r->{wants_skip_files}++;
    }
);

1;
# ABSTRACT: List field names of CSV file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_list_field_names - List field names of CSV file

=head1 VERSION

This document describes version 1.017 of App::CSVUtils::csv_list_field_names (from Perl distribution App-CSVUtils), released on 2023-02-18.

=head1 FUNCTIONS


=head2 csv_list_field_names

Usage:

 csv_list_field_names(%args) -> [$status_code, $reason, $payload, \%result_meta]

List field names of CSV file.

Examples:

=over

=item * List field names of a CSV as a text table of name and position:

 csv_list_field_names(input_filename => "file.csv");

=back

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
