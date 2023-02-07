package App::CSVUtils::csv_freqtable;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.008'; # VERSION

use App::CSVUtils qw(gen_csv_util);

gen_csv_util(
    name => 'csv_freqtable',
    summary => 'Output a frequency table of values of a specified field in CSV',
    description => <<'_',

_

    add_args => {
        %App::CSVUtils::argspec_field_1,
    },
    examples => [
        {
            summary => 'Show the age distribution of people',
            argv => ['people.csv', 'age'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    on_input_header_row => sub {
        my $r = shift;

        # check arguments
        my $field_idx = $r->{input_fields_idx}{ $r->{util_args}{field} };
        die [404, "Field '$r->{util_args}{field}' not found in CSV"]
            unless defined $field_idx;

        # this is a key we add to the stash
        $r->{freqtable} //= {};
        $r->{field_idx} = $field_idx;
    },

    on_input_data_row => sub {
        my $r = shift;

        $r->{freqtable}{ $r->{input_row}[ $r->{field_idx} ] }++;
    },

    writes_csv => 0,

    on_end => sub {
        my $r = shift;

        my @freqtable;
        for (sort { $r->{freqtable}{$b} <=> $r->{freqtable}{$a} } keys %{$r->{freqtable}}) {
            push @freqtable, [$_, $r->{freqtable}{$_}];
        }
        $r->{result} = [200, "OK", \@freqtable, {'table.fields'=>['value','freq']}];
    },
);

1;
# ABSTRACT: Output a frequency table of values of a specified field in CSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_freqtable - Output a frequency table of values of a specified field in CSV

=head1 VERSION

This document describes version 1.008 of App::CSVUtils::csv_freqtable (from Perl distribution App-CSVUtils), released on 2023-02-03.

=head1 FUNCTIONS


=head2 csv_freqtable

Usage:

 csv_freqtable(%args) -> [$status_code, $reason, $payload, \%result_meta]

Output a frequency table of values of a specified field in CSV.

Examples:

=over

=item * Show the age distribution of people:

 csv_freqtable(input_filename => "people.csv", field => "age");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<field>* => I<str>

Field name.

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
