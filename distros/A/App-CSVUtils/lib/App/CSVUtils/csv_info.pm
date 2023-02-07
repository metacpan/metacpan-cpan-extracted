package App::CSVUtils::csv_info;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.008'; # VERSION

use App::CSVUtils qw(gen_csv_util);

gen_csv_util(
    name => 'csv_info',
    summary => 'Show information about CSV file (number of rows, fields, etc)',
    description => <<'_',


_

    add_args => {
    },

    examples => [
        {
            summary => 'Show information on a CSV file',
            argv => ['file.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    writes_csv => 0,

    after_close_input_files => sub {
        my $r = shift;

        $r->{result} = [200, "OK", {
            field_count => scalar @{$r->{input_fields}},
            fields      => $r->{input_fields},

            row_count        => $r->{input_header_row_count} + $r->{input_data_row_count},
            header_row_count => $r->{input_header_row_count},
            data_row_count   => $r->{input_data_row_count},

            # XXX this is incorrect, we have set encoding to utf-8 so handle
            # position != number of bytes
            #file_size   => (-s $r->{input_fh}),
        }];
    }
);

1;
# ABSTRACT: Show information about CSV file (number of rows, fields, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_info - Show information about CSV file (number of rows, fields, etc)

=head1 VERSION

This document describes version 1.008 of App::CSVUtils::csv_info (from Perl distribution App-CSVUtils), released on 2023-02-03.

=head1 FUNCTIONS


=head2 csv_info

Usage:

 csv_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show information about CSV file (number of rows, fields, etc).

Examples:

=over

=item * Show information on a CSV file:

 csv_info(input_filename => "file.csv");

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
