package App::CSVUtils::csv_setop;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.008'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );

gen_csv_util(
    name => 'csv_setop',
    summary => 'Set operation (union/unique concatenation of rows, intersection/common rows, difference of rows) against several CSV files',
    description => <<'_',

This utility lets you perform one of several set options against several CSV
files:
- union
- intersection
- difference
- symmetric difference

Example input:

    # file1.csv
    a,b,c
    1,2,3
    4,5,6
    7,8,9

    # file2.csv
    a,b,c
    1,2,3
    4,5,7
    7,8,9

Output of intersection (`--intersect file1.csv file2.csv`), which will return
common rows between the two files:

    a,b,c
    1,2,3
    7,8,9

Output of union (`--union file1.csv file2.csv`), which will return all rows with
duplicate removed:

    a,b,c
    1,2,3
    4,5,6
    4,5,7
    7,8,9

Output of difference (`--diff file1.csv file2.csv`), which will return all rows
in the first file but not in the second:

    a,b,c
    4,5,6

Output of symmetric difference (`--symdiff file1.csv file2.csv`), which will
return all rows in the first file not in the second, as well as rows in the
second not in the first:

    a,b,c
    4,5,6
    4,5,7

You can specify `--compare-fields` to only consider some fields only, for
example `--union --compare-fields a,b file1.csv file2.csv`:

    a,b,c
    1,2,3
    4,5,6
    7,8,9

Each field specified in `--compare-fields` can be specified using
`F1:OTHER1,F2:OTHER2,...` format to refer to different field names or indexes in
each file, for example if `file3.csv` is:

    # file3.csv
    Ei,Si,Bi
    1,3,2
    4,7,5
    7,9,8

Then `--union --compare-fields a:Ei,b:Bi file1.csv file3.csv` will result in:

    a,b,c
    1,2,3
    4,5,6
    7,8,9

Finally you can print out only certain fields using `--result-fields`.

_
    add_args => {
        op => {
            summary => 'Set operation to perform',
            schema => ['str*', in=>[qw/intersect union diff symdiff/]],
            req => 1,
            cmdline_aliases => {
                intersect   => {is_flag=>1, summary=>'Shortcut for --op=intersect', code=>sub{ $_[0]{op} = 'intersect' }},
                union       => {is_flag=>1, summary=>'Shortcut for --op=union'    , code=>sub{ $_[0]{op} = 'union'     }},
                diff        => {is_flag=>1, summary=>'Shortcut for --op=diff'     , code=>sub{ $_[0]{op} = 'diff'      }},
                symdiff     => {is_flag=>1, summary=>'Shortcut for --op=symdiff'  , code=>sub{ $_[0]{op} = 'symdiff'   }},
            },
        },
        ignore_case => {
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
        },
        compare_fields => {
            schema => ['str*'],
        },
        result_fields => {
            schema => ['str*'],
        },
    },

    links => [
        {url=>'prog:setop'},
    ],

    reads_multiple_csv => 1,

    on_begin => sub {
        my $r = shift;

        # check arguments
        die [400, "Please specify at least 2 files"]
            unless @{ $r->{util_args}{input_filenames} } >= 2;

        # these are the keys we add to the stash
        $r->{all_input_data_rows} = [];  # array of all data rows, one elem for each input file
        $r->{all_input_fields} = [];     # array of input_fields, one elem for each input file
        $r->{all_input_fields_idx} = []; # array of input_fields_idx, one elem for each input file
    },

    on_input_header_row => sub {
        my $r = shift;

        $r->{all_input_fields}    [ $r->{input_filenum}-1 ] = $r->{input_fields};
        $r->{all_input_fields_idx}[ $r->{input_filenum}-1 ] = $r->{input_fields_idx};
        $r->{all_input_data_rows} [ $r->{input_filenum}-1 ] = [];
    },

    on_input_data_row => sub {
        my $r = shift;

        push @{ $r->{all_input_data_rows}[ $r->{input_filenum}-1 ] },
            $r->{input_row};
    },

    after_close_input_files => sub {
        require Tie::IxHash;

        my $r = shift;

        my $op = $r->{util_args}{op};
        my $ci = $r->{util_args}{ignore_case};
        my $num_files = @{ $r->{util_args}{input_filenames} };

        my @compare_fields; # elem = [fieldname-for-file1, fieldname-for-file2, ...]
        if (defined $r->{util_args}{compare_fields}) {
            my @ff = ref($r->{util_args}{compare_fields}) eq 'ARRAY' ?
                @{$r->{util_args}{compare_fields}} : split(/,/, $r->{util_args}{compare_fields});
            for my $field_idx (0..$#ff) {
                my @ff2 = split /:/, $ff[$field_idx];
                for (@ff2+1 .. $num_files) {
                    push @ff2, $ff2[0];
                }
                $compare_fields[$field_idx] = \@ff2;
            }
            # XXX check that specified fields exist
        } else {
            for my $field_idx (0..$#{ $r->{all_input_fields}[0] }) {
                $compare_fields[$field_idx] = [
                    map { $r->{all_input_fields}[0][$field_idx] } 0..$num_files-1];
            }
        }

        my @result_fields; # elem = fieldname, ...
        if (defined $r->{util_args}{result_fields}) {
            @result_fields = ref($r->{util_args}{result_fields}) eq 'ARRAY' ?
                @{$r->{util_args}{result_fields}} : split(/,/, $r->{util_args}{result_fields});
            # XXX check that specified fields exist
        } else {
            @result_fields = @{ $r->{all_input_fields}[0] };
        }
        $r->{output_fields} = \@result_fields;

        tie my(%res), 'Tie::IxHash';

        my $code_get_compare_key = sub {
            my ($file_idx, $row_idx) = @_;
            my $row   = $r->{all_input_data_rows}[$file_idx][$row_idx];
            my $key = join "|", map {
                my $field = $compare_fields[$_][$file_idx];
                my $field_idx = $r->{all_input_fields_idx}[$file_idx]{$field};
                my $val = defined $field_idx ? $row->[$field_idx] : "";
                $val = uc $val if $ci;
                $val;
            } 0..$#compare_fields;
            #say "D:compare_key($file_idx, $row_idx)=<$key>";
            $key;
        };

        my $code_print_result_row = sub {
            my ($file_idx, $row) = @_;
            my @res_row = map {
                my $field = $result_fields[$_];
                my $field_idx = $r->{all_input_fields_idx}[$file_idx]{$field};
                defined $field_idx ? $row->[$field_idx] : "";
            } 0..$#result_fields;
            $r->{code_print_row}->(\@res_row);
        };

        if ($op eq 'intersect') {
            for my $file_idx (0..$num_files-1) {
                if ($file_idx == 0) {
                    for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                        my $key = $code_get_compare_key->($file_idx, $row_idx);
                        $res{$key} //= [1, $row_idx]; # [num_of_occurrence, row_idx]
                    }
                } else {
                    for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                        my $key = $code_get_compare_key->($file_idx, $row_idx);
                        if ($res{$key} && $res{$key}[0] == $file_idx) {
                            $res{$key}[0]++;
                        }
                    }
                }

                # print result
                if ($file_idx == $num_files-1) {
                    for my $key (keys %res) {
                        $code_print_result_row->(
                            0, $r->{all_input_data_rows}[0][$res{$key}[1]])
                            if $res{$key}[0] == $num_files;
                    }
                }
            } # for file_idx

        } elsif ($op eq 'union') {

            for my $file_idx (0..$num_files-1) {
                for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    next if $res{$key}++;
                    my $row = $r->{all_input_data_rows}[$file_idx][$row_idx];
                    $code_print_result_row->($file_idx, $row);
                }
            } # for file_idx

        } elsif ($op eq 'diff') {

            for my $file_idx (0..$num_files-1) {
                if ($file_idx == 0) {
                    for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                        my $key = $code_get_compare_key->($file_idx, $row_idx);
                        $res{$key} //= [$file_idx, $row_idx];
                    }
                } else {
                    for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                        my $key = $code_get_compare_key->($file_idx, $row_idx);
                        delete $res{$key};
                    }
                }

                # print result
                if ($file_idx == $num_files-1) {
                    for my $key (keys %res) {
                        my ($file_idx, $row_idx) = @{ $res{$key} };
                        $code_print_result_row->(
                            0, $r->{all_input_data_rows}[$file_idx][$row_idx]);
                    }
                }
            } # for file_idx

        } elsif ($op eq 'symdiff') {

            for my $file_idx (0..$num_files-1) {
                if ($file_idx == 0) {
                    for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                        my $key = $code_get_compare_key->($file_idx, $row_idx);
                        $res{$key} //= [1, $file_idx, $row_idx];  # [num_of_occurrence, file_idx, row_idx]
                    }
                } else {
                    for my $row_idx (0..$#{ $r->{all_input_data_rows}[$file_idx] }) {
                        my $key = $code_get_compare_key->($file_idx, $row_idx);
                        if (!$res{$key}) {
                            $res{$key} = [1, $file_idx, $row_idx];
                        } else {
                            $res{$key}[0]++;
                        }
                    }
                }

                # print result
                if ($file_idx == $num_files-1) {
                    for my $key (keys %res) {
                        my ($num_occur, $file_idx, $row_idx) = @{ $res{$key} };
                        $code_print_result_row->(
                            0, $r->{all_input_data_rows}[$file_idx][$row_idx])
                            if $num_occur == 1;
                    }
                }
            } # for file_idx

        } else {

            die [400, "Unknown/unimplemented op '$op'"];

        }

        #use DD; dd +{
        #    compare_fields => \@compare_fields,
        #    result_fields => \@result_fields,
        #    all_input_data_rows=>$r->{all_input_data_rows},
        #    all_input_fields=>$r->{all_input_fields},
        #    all_input_fields_idx=>$r->{all_input_fields_idx},
        #};
    },
);

1;
# ABSTRACT: Set operation (union/unique concatenation of rows, intersection/common rows, difference of rows) against several CSV files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_setop - Set operation (union/unique concatenation of rows, intersection/common rows, difference of rows) against several CSV files

=head1 VERSION

This document describes version 1.008 of App::CSVUtils::csv_setop (from Perl distribution App-CSVUtils), released on 2023-02-03.

=head1 FUNCTIONS


=head2 csv_setop

Usage:

 csv_setop(%args) -> [$status_code, $reason, $payload, \%result_meta]

Set operation (unionE<sol>unique concatenation of rows, intersectionE<sol>common rows, difference of rows) against several CSV files.

This utility lets you perform one of several set options against several CSV
files:
- union
- intersection
- difference
- symmetric difference

Example input:

 # file1.csv
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 
 # file2.csv
 a,b,c
 1,2,3
 4,5,7
 7,8,9

Output of intersection (C<--intersect file1.csv file2.csv>), which will return
common rows between the two files:

 a,b,c
 1,2,3
 7,8,9

Output of union (C<--union file1.csv file2.csv>), which will return all rows with
duplicate removed:

 a,b,c
 1,2,3
 4,5,6
 4,5,7
 7,8,9

Output of difference (C<--diff file1.csv file2.csv>), which will return all rows
in the first file but not in the second:

 a,b,c
 4,5,6

Output of symmetric difference (C<--symdiff file1.csv file2.csv>), which will
return all rows in the first file not in the second, as well as rows in the
second not in the first:

 a,b,c
 4,5,6
 4,5,7

You can specify C<--compare-fields> to only consider some fields only, for
example C<--union --compare-fields a,b file1.csv file2.csv>:

 a,b,c
 1,2,3
 4,5,6
 7,8,9

Each field specified in C<--compare-fields> can be specified using
C<F1:OTHER1,F2:OTHER2,...> format to refer to different field names or indexes in
each file, for example if C<file3.csv> is:

 # file3.csv
 Ei,Si,Bi
 1,3,2
 4,7,5
 7,9,8

Then C<--union --compare-fields a:Ei,b:Bi file1.csv file3.csv> will result in:

 a,b,c
 1,2,3
 4,5,6
 7,8,9

Finally you can print out only certain fields using C<--result-fields>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<compare_fields> => I<str>

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

=item * B<op>* => I<str>

Set operation to perform.

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

=item * B<result_fields> => I<str>

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
