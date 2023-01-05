package App::CSVUtils::csv_lookup_fields;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-04'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.001'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );

gen_csv_util(
    name => 'csv_lookup_fields',
    summary => 'Fill fields of a CSV file from another',
    description => <<'_',

Example input:

    # report.csv
    client_id,followup_staff,followup_note,client_email,client_phone
    101,Jerry,not renewing,
    299,Jerry,still thinking over,
    734,Elaine,renewing,

    # clients.csv
    id,name,email,phone
    101,Andy,andy@example.com,555-2983
    102,Bob,bob@acme.example.com,555-2523
    299,Cindy,cindy@example.com,555-7892
    400,Derek,derek@example.com,555-9018
    701,Edward,edward@example.com,555-5833
    734,Felipe,felipe@example.com,555-9067

To fill up the `client_email` and `client_phone` fields of `report.csv` from
`clients.csv`, we can use:

    % csv-lookup-fields report.csv clients.csv --lookup-fields client_id:id --fill-fields client_email:email,client_phone:phone

The result will be:

    client_id,followup_staff,followup_note,client_email,client_phone
    101,Jerry,not renewing,andy@example.com,555-2983
    299,Jerry,still thinking over,cindy@example.com,555-7892
    734,Elaine,renewing,felipe@example.com,555-9067

_
    add_args => {
        ignore_case => {
            schema => 'bool*',
            cmdline_aliases => {ci=>{}, i=>{}},
        },
        fill_fields => {
            schema => ['str*'],
            req => 1,
        },
        lookup_fields => {
            schema => ['str*'],
            req => 1,
        },
        count => {
            summary => 'Do not output rows, just report the number of rows filled',
            schema => 'bool*',
            cmdline_aliases => {c=>{}},
        },
    },

    reads_multiple_csv => 1,

    on_begin => sub {
        my $r = shift;

        # check arguments
        @{ $r->{util_args}{input_filenames} } == 2
            or die [400, "Please specify exactly 2 files: target and source"];

        my @lookup_fields; # elem = [fieldname-in-target, fieldname-in-source]
        {
            my @ff = ref($r->{util_args}{lookup_fields}) eq 'ARRAY' ?
                @{$r->{util_args}{lookup_fields}} : split(/,/, $r->{util_args}{lookup_fields});
            for my $field_idx (0..$#ff) {
                my @ff2 = split /:/, $ff[$field_idx], 2;
                if (@ff2 < 2) {
                    $ff2[1] = $ff2[0];
                }
                $lookup_fields[$field_idx] = \@ff2;
            }
        }

        my %fill_fields; # key=fieldname-in-target, val=fieldname-in-source
        {
            my @ff = ref($r->{util_args}{fill_fields}) eq 'ARRAY' ?
                @{$r->{util_args}{fill_fields}} : split(/,/, $r->{util_args}{fill_fields});
            for my $field_idx (0..$#ff) {
                my @ff2 = split /:/, $ff[$field_idx], 2;
                if (@ff2 < 2) {
                    $ff2[1] = $ff2[0];
                }
                $fill_fields{ $ff2[0] } = $ff2[1];
            }
        }

        # these are the keys that we add to the stash
        $r->{lookup_fields} = \@lookup_fields;
        $r->{fill_fields} = \%fill_fields;
        $r->{source_fields_idx} = [];
        $r->{source_fields} = [];
        $r->{source_data_rows} = [];
        $r->{target_fields_idx} = [];
        $r->{target_fields} = [];
        $r->{target_data_rows} = [];
    },

    on_input_header_row => sub {
        my $r = shift;

        if ($r->{input_filenum} == 1) {
            $r->{target_fields}     = $r->{input_fields};
            $r->{target_fields_idx} = $r->{input_fields_idx};
            $r->{output_fields}     = $r->{input_fields};
        } else {
            $r->{source_fields}     = $r->{input_fields};
            $r->{source_fields_idx} = $r->{input_fields_idx};
        }
    },

    on_input_data_row => sub {
        my $r = shift;

        if ($r->{input_filenum} == 1) {
            push @{ $r->{target_data_rows} }, $r->{input_row};
        } else {
            push @{ $r->{source_data_rows} }, $r->{input_row};
        }
    },

    after_close_input_files => sub {
        my $r = shift;

        my $ci = $r->{util_args}{ignore_case};

        # build lookup table
        my %lookup_table; # key = joined lookup fields, val = source row idx
        for my $row_idx (0..$#{$r->{source_data_rows}}) {
            my $row = $r->{source_data_rows}[$row_idx];
            my $key = join "|", map {
                my $field = $r->{lookup_fields}[$_][1];
                my $field_idx = $r->{source_fields_idx}{$field};
                my $val = defined $field_idx ? $row->[$field_idx] : "";
                $val = lc $val if $ci;
                $val;
            } 0..$#{ $r->{lookup_fields} };
            $lookup_table{$key} //= $row_idx;
        }
        #use DD; dd { lookup_fields=>$r->{lookup_fields}, fill_fields=>$r->{fill_fields}, lookup_table=>\%lookup_table };

        # fill target csv
        my $num_filled = 0;

        for my $row (@{ $r->{target_data_rows} }) {
            my $key = join "|", map {
                my $field = $r->{lookup_fields}[$_][0];
                my $field_idx = $r->{target_fields_idx}{$field};
                my $val = defined $field_idx ? $row->[$field_idx] : "";
                $val = lc $val if $ci;
                $val;
            } 0..$#{ $r->{lookup_fields} };

            #say "D:looking up '$key' ...";
            if (defined(my $row_idx = $lookup_table{$key})) {
                #say "  D:found";
                my $row_filled;
                my $source_row = $r->{source_data_rows}[$row_idx];
                for my $field (keys %{$r->{fill_fields}}) {
                    my $target_field_idx = $r->{target_fields_idx}{$field};
                    next unless defined $target_field_idx;
                    my $source_field_idx = $r->{source_fields_idx}{ $r->{fill_fields}{$field} };
                    next unless defined $source_field_idx;
                    $row->[$target_field_idx] =
                        $source_row->[$source_field_idx];
                    $row_filled++;
                }
                $num_filled++ if $row_filled;
            }
            unless ($r->{util_args}{count}) {
                $r->{code_print_row}->($row);
            }
        } # for target data row

        if ($r->{util_args}{count}) {
            $r->{result} = [200, "OK", $num_filled];
        }
    },
);

1;
# ABSTRACT: Fill fields of a CSV file from another

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_lookup_fields - Fill fields of a CSV file from another

=head1 VERSION

This document describes version 1.001 of App::CSVUtils::csv_lookup_fields (from Perl distribution App-CSVUtils), released on 2023-01-04.

=head1 FUNCTIONS


=head2 csv_lookup_fields

Usage:

 csv_lookup_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Fill fields of a CSV file from another.

Example input:

 # report.csv
 client_id,followup_staff,followup_note,client_email,client_phone
 101,Jerry,not renewing,
 299,Jerry,still thinking over,
 734,Elaine,renewing,
 
 # clients.csv
 id,name,email,phone
 101,Andy,andy@example.com,555-2983
 102,Bob,bob@acme.example.com,555-2523
 299,Cindy,cindy@example.com,555-7892
 400,Derek,derek@example.com,555-9018
 701,Edward,edward@example.com,555-5833
 734,Felipe,felipe@example.com,555-9067

To fill up the C<client_email> and C<client_phone> fields of C<report.csv> from
C<clients.csv>, we can use:

 % csv-lookup-fields report.csv clients.csv --lookup-fields client_id:id --fill-fields client_email:email,client_phone:phone

The result will be:

 client_id,followup_staff,followup_note,client_email,client_phone
 101,Jerry,not renewing,andy@example.com,555-2983
 299,Jerry,still thinking over,cindy@example.com,555-7892
 734,Elaine,renewing,felipe@example.com,555-9067

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<count> => I<bool>

Do not output rows, just report the number of rows filled.

=item * B<fill_fields>* => I<str>

(No description)

=item * B<ignore_case> => I<bool>

(No description)

=item * B<input_escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--input-tsv> option.

=item * B<input_filenames> => I<array[filename]> (default: ["-"])

Input CSV files.

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

=item * B<lookup_fields>* => I<str>

(No description)

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--input-escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename.

Use C<-> to output to stdout (the default if you don't specify this option).

Encoding of output file is assumed to be UTF-8.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--input-quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--input-sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--input-tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.


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
