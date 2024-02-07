package App::CSVUtils::csv_fill_cells;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-02'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.034'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                );

gen_csv_util(
    name => 'csv_fill_cells',
    summary => 'Create a CSV and fill its cells from supplied values (a 1-column CSV)',
    description => <<'_',

This utility takes values (from cells of a 1-column input CSV), creates an
output CSV of specified size, and fills the output CSV in one of several
possible ways ("layouts"): left-to-right first then top-to-bottom, or
bottom-to-top then left-to-right, etc.

Some illustration of the layout:

    % cat 1-to-100.csv
    num
    1
    2
    3
    ...
    100

    % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 ; # default layout is 'left_to_right_then_top_to_bottom'
    field0,field1,field2,field3,field4,field5,field6,field7,field8,field9
    1,2,3,4,5,6,7,8,9,10
    11,12,13,14,15,16,17,18,19,20
    21,22,23,24,25,26,27,28,29,30
    ...
    91,92,93,94,95,96,97,98,99,100

    % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 --layout top_to_bottom_then_left_to_right
    field0,field1,field2,field3,field4,field5,field6,field7,field8,field9
    1,11,21,31,41,51,61,71,81,91
    2,12,22,32,42,52,62,72,82,92
    3,13,23,33,43,53,63,73,83,93
    ...
    10,20,30,40,50,60,70,80,90,100

    % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 --layout top_to_bottom_then_right_to_left
    91,81,71,61,51,41,31,21,11,1
    92,82,72,62,52,42,32,22,12,2
    93,83,73,63,53,43,33,23,13,3
    ...
    100,90,80,70,60,50,40,30,20,10

    % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 --layout right_to_left_then_top_to_bottom
    10,9,8,7,6,5,4,3,2,1
    20,19,18,17,16,15,14,13,12,11
    30,29,28,27,26,25,24,23,22,21
    ...
    100,99,98,97,96,95,94,93,92,91

Some additional options are available, e.g.: a filter to let skip filling some
cells.

When there are more input values than can be fitted, the extra input values are
not placed into the output CSV.

When there are less input values to fill the specified number of rows, then only
the required number of rows and/or columns will be used.

Additional options planned:

- what to do when there are less values to completely fill the output CSV
  (whether to always expand or expand when necessary, which is the default).

- what to do when there are more values (extend the table or ignore the extra
  input values, which is the default).

_
    add_args => {
        # TODO
        #fields => $App::CSVUtils::argspecopt_fields{fields}, # category:output

        layout => {
            summary => 'Specify how the output CSV is to be filled',
            schema => ['str*', in=>[
                'left_to_right_then_top_to_bottom',
                'right_to_left_then_top_to_bottom',
                'left_to_right_then_bottom_to_top',
                'right_to_left_then_bottom_to_top',
                'top_to_bottom_then_left_to_right',
                'top_to_bottom_then_right_to_left',
                'bottom_to_top_then_left_to_right',
                'bottom_to_top_then_right_to_left',
            ]],
            default => 'left_to_right_then_top_to_bottom',
            tags => ['category:layout'],
        },

        filter => {
            summary => 'Code to filter cells to fill',
            schema => 'str*',
            description => <<'_',

Code will be compiled in the `main` package.

Code is passed `($r, $output_row_num, $output_field_idx)` where `$r` is the
stash, `$output_row_num` is a 1-based integer (first data row means 1), and
`$output_field_idx` is the 0-based field index (0 means the first index). Code
is expected to return a boolean value, where true meaning the cell should be
filied.

_
            tags => ['category:filtering'],
        },
        num_rows => {
            summary => 'Number of rows of the output CSV',
            schema => 'posint*',
            req => 1,
            tags => ['category:output'],
        },
        num_fields => {
            summary => 'Number of fields of the output CSV',
            schema => 'posint*',
            req => 1,
            tags => ['category:output'],
        },
    },

    tags => ['category:generating', 'accepts-code'],

    examples => [
        {
            summary => 'Fill number 1..100 into a 10x10 grid',
            src => q{seq 1 100 | [[prog]] --num-rows 10 --num-fields 10},
            src_plang => 'bash',
            test => 0,
        },
    ],

    on_input_header_row => sub {
        my $r = shift;

        # set output fields
        $r->{output_fields} = [ map {"field$_"}
                                0 .. $r->{util_args}{num_fields}-1 ];

        # compile filter
        if ($r->{util_args}{filter}) {
            my $code = compile_eval_code($r->{util_args}{filter}, 'filter');
            # this is a key we add to the stash
            $r->{filter} = $code;
        }

        # this is a key we add to the stash
        $r->{input_values} = [];
    },

    on_input_data_row => sub {
        my $r = shift;

        push @{ $r->{input_values} }, $r->{input_row}[0];
    },

    after_read_input => sub {
        my $r = shift;

        my $i = -1;
        my $layout = $r->{util_args}{layout} // 'left_to_right_then_top_to_bottom';
        my $output_rows = [];

        my $x = $layout =~ /left_to_right/ ? 0 : $r->{util_args}{num_fields}-1;
        my $y = $layout =~ /top_to_bottom/ ? 1 : $r->{util_args}{num_rows};
        while (1) {
            goto INC_POS if $r->{filter} && !$r->{filter}->($r, $y, $x);

          INC_I:
            $i++;
            last if $i >= @{ $r->{input_values} };

          FILL_CELL:
            for (1 .. $y) {
                $output_rows->[$_-1] //= [map {undef} 1 .. $r->{util_args}{num_fields}];
            }
            $output_rows->[$y-1][$x] = $r->{input_values}[$i];

          INC_POS:
            if ($layout =~ /\A(top|bottom)_/) {
                # vertically first then horizontally
                if ($layout =~ /top_to_bottom/) {
                    $y++;
                    if ($y > $r->{util_args}{num_rows}) {
                        $y = 1;
                        if ($layout =~ /left_to_right/) {
                            $x++;
                            last if $x >= $r->{util_args}{num_fields};
                        } else {
                            $x--;
                            last if $x < 0;
                        }
                    }
                } else {
                    $y--;
                    if ($y < 1) {
                        $y = $r->{util_args}{num_rows};
                        if ($layout =~ /left_to_right/) {
                            $x++;
                            last if $x >= $r->{util_args}{num_fields};
                        } else {
                            $x--;
                            last if $x < 0;
                        }
                    }
                }
            } else {
                # horizontally first then vertically
                if ($layout =~ /left_to_right/) {
                    $x++;
                    if ($x >= $r->{util_args}{num_fields}) {
                        $x = 0;
                        if ($layout =~ /top_to_bottom/) {
                            $y++;
                            last if $y > $r->{util_args}{num_rows};
                        } else {
                            $y--;
                            last if $y < 1;
                        }
                    }
                } else {
                    $x--;
                    if ($x < 0) {
                        $x = $r->{util_args}{num_fields}-1;
                        if ($layout =~ /top_to_bottom/) {
                            $y++;
                            last if $y > $r->{util_args}{num_rows};
                        } else {
                            $y--;
                            last if $y < 1;
                        }
                    }
                }
            }
        }

        # print rows
        for my $row (@$output_rows) {
            $r->{code_print_row}->($row);
        }
    },
);

1;
# ABSTRACT: Create a CSV and fill its cells from supplied values (a 1-column CSV)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_fill_cells - Create a CSV and fill its cells from supplied values (a 1-column CSV)

=head1 VERSION

This document describes version 1.034 of App::CSVUtils::csv_fill_cells (from Perl distribution App-CSVUtils), released on 2024-02-02.

=head1 FUNCTIONS


=head2 csv_fill_cells

Usage:

 csv_fill_cells(%args) -> [$status_code, $reason, $payload, \%result_meta]

Create a CSV and fill its cells from supplied values (a 1-column CSV).

This utility takes values (from cells of a 1-column input CSV), creates an
output CSV of specified size, and fills the output CSV in one of several
possible ways ("layouts"): left-to-right first then top-to-bottom, or
bottom-to-top then left-to-right, etc.

Some illustration of the layout:

 % cat 1-to-100.csv
 num
 1
 2
 3
 ...
 100
 
 % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 ; # default layout is 'left_to_right_then_top_to_bottom'
 field0,field1,field2,field3,field4,field5,field6,field7,field8,field9
 1,2,3,4,5,6,7,8,9,10
 11,12,13,14,15,16,17,18,19,20
 21,22,23,24,25,26,27,28,29,30
 ...
 91,92,93,94,95,96,97,98,99,100
 
 % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 --layout top_to_bottom_then_left_to_right
 field0,field1,field2,field3,field4,field5,field6,field7,field8,field9
 1,11,21,31,41,51,61,71,81,91
 2,12,22,32,42,52,62,72,82,92
 3,13,23,33,43,53,63,73,83,93
 ...
 10,20,30,40,50,60,70,80,90,100
 
 % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 --layout top_to_bottom_then_right_to_left
 91,81,71,61,51,41,31,21,11,1
 92,82,72,62,52,42,32,22,12,2
 93,83,73,63,53,43,33,23,13,3
 ...
 100,90,80,70,60,50,40,30,20,10
 
 % csv-fill-cells 1-to-100.csv --num-rows 10 --num-fields 10 --layout right_to_left_then_top_to_bottom
 10,9,8,7,6,5,4,3,2,1
 20,19,18,17,16,15,14,13,12,11
 30,29,28,27,26,25,24,23,22,21
 ...
 100,99,98,97,96,95,94,93,92,91

Some additional options are available, e.g.: a filter to let skip filling some
cells.

When there are more input values than can be fitted, the extra input values are
not placed into the output CSV.

When there are less input values to fill the specified number of rows, then only
the required number of rows and/or columns will be used.

Additional options planned:

=over

=item * what to do when there are less values to completely fill the output CSV
(whether to always expand or expand when necessary, which is the default).

=item * what to do when there are more values (extend the table or ignore the extra
input values, which is the default).

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filter> => I<str>

Code to filter cells to fill.

Code will be compiled in the C<main> package.

Code is passed C<($r, $output_row_num, $output_field_idx)> where C<$r> is the
stash, C<$output_row_num> is a 1-based integer (first data row means 1), and
C<$output_field_idx> is the 0-based field index (0 means the first index). Code
is expected to return a boolean value, where true meaning the cell should be
filied.

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

=item * B<layout> => I<str> (default: "left_to_right_then_top_to_bottom")

Specify how the output CSV is to be filled.

=item * B<num_fields>* => I<posint>

Number of fields of the output CSV.

=item * B<num_rows>* => I<posint>

Number of rows of the output CSV.

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
