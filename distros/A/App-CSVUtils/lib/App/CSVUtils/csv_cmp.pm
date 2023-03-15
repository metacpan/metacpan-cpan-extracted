package App::CSVUtils::csv_cmp;

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

gen_csv_util(
    name => 'csv_cmp',
    summary => 'Compare two CSV files value by value',
    description => <<'_',

This utility is modelled after the Unix command `cmp`; it compares two CSV files
value by value and ignore quoting (and can be instructed to ignore whitespaces,
case difference).

If all the values of two CSV files are identical, then utility will exit with
code 0. If a value differ, this utility will stop, print the difference and exit
with code 1.

If `-l` (`--detail`) option is specified, all differences will be reported. Note
that in `cmp` Unix command, the `-l` option is called `--verbose`. The detailed
report is in the form of CSV:

    rownum,fieldnum,value1,value2

where `rownum` begins at 1 (for header row), `fieldnum` begins at 1 (first
field), `value1` is the value in first CSV file, `value2` is the value in the
second CSV file.

Other notes:

* If none of the field selection options are used, it means all fields are
  included (equivalent to `--include-all-fields`).

* Field selection will be performed on the first CSV file, then the indexes will
be used for the second CSV file.

_
    add_args => {
        %App::CSVUtils::argspecsopt_field_selection,
        %App::CSVUtils::argspecsopt_show_selected_fields,

        detail => {
            summary => 'Report all differences instead of just the first one',
            schema => 'true*',
            cmdline_aliases => {l=>{}},
        },
        quiet => {
            summary => 'Do not report, just signal via exit code',
            schema => 'true*',
            cmdline_aliases => {q=>{}},
        },
        ignore_case => {
            summary => 'Ignore case difference',
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
        },
        ignore_leading_ws => {
            summary => 'Ignore leading whitespaces',
            schema => 'bool*',
        },
        ignore_trailing_ws => {
            summary => 'Ignore trailing whitespaces',
            schema => 'bool*',
        },
        ignore_ws => {
            summary => 'Ignore leading & trailing whitespaces',
            schema => 'bool*',
        },
    },
    examples => [
        {
            summary => 'Compare two identical files, will output nothing and exits 0',
            argv => ['file.csv', 'file.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Compare two CSV files case-insensitively (-i), show detailed report (-l)',
            argv => ['file1.csv', 'file2.csv', '-il'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    reads_multiple_csv => 1,

    on_begin => sub {
        my $r = shift;

        unless ($r->{util_args}{input_filenames} && @{ $r->{util_args}{input_filenames} } == 2) {
            die [400, "Please specify exactly two files to compare"];
        }
        # no point in generating detailed report if we're not going to show it
        $r->{util_args}{detail} = 0 if $r->{util_args}{quiet};
    },

    before_open_input_files => sub {
        my $r = shift;

        # we add the following keys to the stash
        $r->{all_input_rows} = [[], []]; # including header row. format: [ [row1 of csv1, row2 of csv1...], [row1 of csv2, row2 of csv2, ...] ]
        $r->{selected_fields_idx_array_sorted} = undef;
    },

    on_input_header_row => sub {
        my $r = shift;

        push @{ $r->{all_input_rows}[ $r->{input_filenum}-1 ] }, $r->{input_fields};

        if ($r->{input_filenum} == 1) {
            # set selected_fields_idx_array_sorted
            my $res = App::CSVUtils::_select_fields($r->{input_fields}, $r->{input_fields_idx}, $r->{util_args}, 'all');
            die $res unless $res->[0] == 100;
            my $selected_fields = $res->[2][0];
            my $selected_fields_idx_array = $res->[2][1];
            die [412, "At least one field must be selected"]
                unless @$selected_fields;
            $r->{selected_fields_idx_array_sorted} = [sort { $b <=> $a } @$selected_fields_idx_array];

            if ($r->{util_args}{show_selected_fields}) {
                $r->{wants_skip_files}++;
                $r->{result} = [200, "OK", $selected_fields];
                return;
            }
        }
    },

    on_input_data_row => sub {
        my $r = shift;

        push @{ $r->{all_input_rows}[ $r->{input_filenum}-1 ] }, $r->{input_row};
    },

    after_close_input_files => sub {
        my $r = shift;

        $r->{output_fields} = ["rownum","fieldnum","value1","value2"];

        my $exit_code = 0;
        my $numrows1   = @{ $r->{all_input_rows}[0] };
        my $numrows2   = @{ $r->{all_input_rows}[1] };
        my $numfields1 = @{ $r->{all_input_rows}[0][0] };
        my $numfields2 = @{ $r->{all_input_rows}[1][0] };

        if ($numfields1 > $numfields2) {
            warn "csv-cmp: second CSV only has $numfields2 field(s) (vs $numfields1)\n"
                unless $r->{util_args}{quiet};
            $exit_code = 1;
            goto DONE unless $r->{util_args}{detail};
        } elsif ($numfields1 < $numfields2) {
            warn "csv-cmp: first CSV only has $numfields1 field(s) (vs $numfields2)\n"
                unless $r->{util_args}{quiet};
            $exit_code = 1;
            goto DONE unless $r->{util_args}{detail};
        }

        my $numrows_min = $numrows1 < $numrows2 ? $numrows1 : $numrows2;
        for my $rownum (1 .. $numrows_min) {
            for my $j (@{ $r->{selected_fields_idx_array_sorted} }) {
                my $fieldnum = $j+1;
                my $origvalue1 = my $value1 = $r->{all_input_rows}[0][ $rownum-1 ][ $fieldnum-1 ];
                my $origvalue2 = my $value2 = $r->{all_input_rows}[1][ $rownum-1 ][ $fieldnum-1 ];

                if ($r->{util_args}{ignore_case}) {
                    $value1 = lc $value1;
                    $value2 = lc $value2;
                }
                if ($r->{util_args}{ignore_ws} || $r->{util_args}{ignore_leading_ws}) {
                    $value1 =~ s/\A\s+//s;
                    $value2 =~ s/\A\s+//s;
                }
                if ($r->{util_args}{ignore_ws} || $r->{util_args}{ignore_trailing_ws}) {
                    $value1 =~ s/\s+\z//s;
                    $value2 =~ s/\s+\z//s;
                }

                if ($value1 ne $value2) {
                    $exit_code = 1;
                    if ($r->{util_args}{detail}) {
                        $r->{code_print_row}->([$rownum, $fieldnum, $origvalue1, $origvalue2])
                            unless $r->{util_args}{quiet};
                    } else {
                        warn "csv-cmp: Value differ at rownum $rownum fieldnum $fieldnum: '$origvalue1' vs '$origvalue2'\n"
                            unless $r->{util_args}{quiet};
                        goto DONE;
                    }
                }
            } # for field
        } # for row

        if ($numrows1 > $numrows2) {
            warn "csv-cmp: EOF: second CSV only has $numrows2 row(s) (vs $numrows1)\n"
                unless $r->{util_args}{quiet};
            $exit_code = 1;
            goto DONE unless $r->{util_args}{detail};
        } elsif ($numrows1 < $numrows2) {
            warn "csv-cmp: EOF: first CSV only has $numrows1 row(s) (vs $numrows2)\n"
                unless $r->{util_args}{quiet};
            $exit_code = 1;
            goto DONE unless $r->{util_args}{detail};
        }

      DONE:
        $r->{result} = [200, "OK", "", {"cmdline.exit_code"=>$exit_code}];
    },
);

1;
# ABSTRACT: Compare two CSV files value by value

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_cmp - Compare two CSV files value by value

=head1 VERSION

This document describes version 1.022 of App::CSVUtils::csv_cmp (from Perl distribution App-CSVUtils), released on 2023-03-10.

=head1 FUNCTIONS


=head2 csv_cmp

Usage:

 csv_cmp(%args) -> [$status_code, $reason, $payload, \%result_meta]

Compare two CSV files value by value.

Examples:

=over

=item * Compare two identical files, will output nothing and exits 0:

 csv_cmp(input_filenames => ["file.csv", "file.csv"]);

=item * Compare two CSV files case-insensitively (-i), show detailed report (-l):

 csv_cmp(
     input_filenames => ["file1.csv", "file2.csv"],
   detail => 1,
   ignore_case => 1
 );

=back

This utility is modelled after the Unix command C<cmp>; it compares two CSV files
value by value and ignore quoting (and can be instructed to ignore whitespaces,
case difference).

If all the values of two CSV files are identical, then utility will exit with
code 0. If a value differ, this utility will stop, print the difference and exit
with code 1.

If C<-l> (C<--detail>) option is specified, all differences will be reported. Note
that in C<cmp> Unix command, the C<-l> option is called C<--verbose>. The detailed
report is in the form of CSV:

 rownum,fieldnum,value1,value2

where C<rownum> begins at 1 (for header row), C<fieldnum> begins at 1 (first
field), C<value1> is the value in first CSV file, C<value2> is the value in the
second CSV file.

Other notes:

=over

=item * If none of the field selection options are used, it means all fields are
included (equivalent to C<--include-all-fields>).

=item * Field selection will be performed on the first CSV file, then the indexes will
be used for the second CSV file.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

Report all differences instead of just the first one.

=item * B<exclude_field_pat> => I<re>

Field regex pattern to exclude, takes precedence over --field-pat.

=item * B<exclude_fields> => I<array[str]>

Field names to exclude, takes precedence over --fields.

=item * B<ignore_case> => I<bool>

Ignore case difference.

=item * B<ignore_leading_ws> => I<bool>

Ignore leading whitespaces.

=item * B<ignore_trailing_ws> => I<bool>

Ignore trailing whitespaces.

=item * B<ignore_unknown_fields> => I<bool>

When unknown fields are specified in --include-field (--field) or --exclude-field options, ignore them instead of throwing an error.

=item * B<ignore_ws> => I<bool>

Ignore leading & trailing whitespaces.

=item * B<include_field_pat> => I<re>

Field regex pattern to select, overidden by --exclude-field-pat.

=item * B<include_fields> => I<array[str]>

Field names to include, takes precedence over --exclude-field-pat.

=item * B<inplace> => I<true>

Output to the same file as input.

Normally, you output to a different file than input. If you try to output to the
same file (C<-o INPUT.csv -O>) you will clobber the input file; thus the utility
prevents you from doing it. However, with this C<--inplace> option, you can
output to the same file. Like perl's C<-i> option, this will first output to a
temporary file in the same directory as the input file then rename to the final
file at the end. You cannot specify output file (C<-o>) when using this option,
but you can specify backup extension with C<-b> option.

Some caveats:

=over

=item * if input file is a symbolic link, it will be replaced with a regular file;

=item * renaming (implemented using C<rename()>) can fail if input filename is too long;

=item * value specified in C<-b> is currently not checked for acceptable characters;

=item * things can also fail if permissions are restrictive;

=back

=item * B<inplace_backup_ext> => I<str> (default: "")

Extension to add for backup of input file.

In inplace mode (C<--inplace>), if this option is set to a non-empty string, will
rename the input file using this extension as a backup. The old existing backup
will be overwritten, if any.

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

=item * B<output_always_quote> => I<bool> (default: 0)

Whether to always quote values.

When set to false (the default), values are quoted only when necessary:

 field1,field2,"field three contains comma (,)",field4

When set to true, then all values will be quoted:

 "field1","field2","field three contains comma (,)","field4"

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

=item * B<output_quote_empty> => I<bool> (default: 0)

Whether to quote empty values.

When set to false (the default), empty values are not quoted:

 field1,field2,,field4

When set to true, then empty values will be quoted:

 field1,field2,"",field4

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

=item * B<quiet> => I<true>

Do not report, just signal via exit code.

=item * B<show_selected_fields> => I<true>

Show selected fields and then immediately exit.


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
