package App::CSVUtils::csv_get_cells;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-10'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.022'; # VERSION

use App::CSVUtils qw(gen_csv_util);

gen_csv_util(
    name => 'csv_get_cells',
    summary => 'Get one or more cells from CSV',
    description => <<'_',

This utility lets you specify "coordinates" of cell locations to extract. Each
coordinate is in the form of `<field>,<row>` where `<field>` is the field name
or position (1-based, so 1 is the first field) and `<row>` is the row position
(1-based, so 1 is the header row and 2 is the first data row).

_

    add_args => {
        coordinates => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'coordinate',
            summary => 'List of coordinates, each in the form of <col>,<row> e.g. age,1 or 1,1',
            schema => ['array*', of=>'str*', min_len=>1],
            req => 1,
            pos => 1,
            slurpy => 1,
        },
    },
    examples => [
        {
            summary => 'Get the age for second row',
            argv => ['file.csv', 'age,2'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    writes_csv => 0,

    on_input_data_row => sub {
        my $r = shift;

        # this is the key we add to stash
        $r->{cells} //= [];

        my $j = -1;
      COORD:
        for my $coord (@{ $r->{util_args}{coordinates} }) {
            $j++;
            my ($coord_field, $coord_row) = $coord =~ /\A(.+),(.+)\z/
                or die [400, "Invalid coordinate '$coord': must be in field,row form"];
            $coord_row =~ /\A[0-9]+\z/
                or die [400, "Invalid coordinate '$coord': invalid row syntax '$coord_row', must be a number"];
            my $row;
            if ($coord_row == 1) {
                $row = $r->{input_fields};
            } elsif ($coord_row == $r->{input_rownum}) {
                $row = $r->{input_row};
            } else {
                next COORD;
            }

            if ($coord_field =~ /\A[0-9]+\z/) {
                $coord_field >= 1 && $coord_field <= $#{ $r->{input_fields} }+1
                        or die [400, "Invalid coordinate '$coord': field number '$coord_field' out of bound, must be between 1-". ($#{$r->{input_fields}}+1)];
                $r->{cells}[$j] = $row->[$coord_field-1];
            } else {
                my $field_idx = App::CSVUtils::_find_field($r->{input_fields}, $coord_field);
                $r->{cells}[$j] = $row->[ $field_idx ];
            }
        }
    },

    after_close_input_files => sub {
        my $r = shift;

        $r->{result} = [200, "OK", $r->{cells}];
    },
);

1;
# ABSTRACT: Get one or more cells from CSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_get_cells - Get one or more cells from CSV

=head1 VERSION

This document describes version 1.022 of App::CSVUtils::csv_get_cells (from Perl distribution App-CSVUtils), released on 2023-03-10.

=head1 FUNCTIONS


=head2 csv_get_cells

Usage:

 csv_get_cells(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get one or more cells from CSV.

Examples:

=over

=item * Get the age for second row:

 csv_get_cells(input_filename => "file.csv", coordinates => ["age,2"]);

=back

This utility lets you specify "coordinates" of cell locations to extract. Each
coordinate is in the form of C<< E<lt>fieldE<gt>,E<lt>rowE<gt> >> where C<< E<lt>fieldE<gt> >> is the field name
or position (1-based, so 1 is the first field) and C<< E<lt>rowE<gt> >> is the row position
(1-based, so 1 is the header row and 2 is the first data row).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coordinates>* => I<array[str]>

List of coordinates, each in the form of <colE<gt>,<rowE<gt> e.g. age,1 or 1,1.

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
