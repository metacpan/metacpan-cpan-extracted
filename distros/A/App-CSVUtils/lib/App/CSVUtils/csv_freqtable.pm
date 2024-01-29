package App::CSVUtils::csv_freqtable;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-06'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.033'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                        eval_code
                );

gen_csv_util(
    name => 'csv_freqtable',
    summary => 'Output a frequency table of values of a specified field in CSV',
    description => <<'_',

_

    add_args => {
        %App::CSVUtils::argspecopt_field_1,
        ignore_case => {
            summary => 'Ignore case',
            schema => 'true*',
            cmdline_aliases => {i=>{}},
        },
        key => {
            summary => 'Generate computed field with this Perl code',
            description => <<'_',

If specified, then will compute field using Perl code.

The code will receive the row (arrayref, or if -H is specified, hashref) as the
argument. It should return the computed field (str).

_
            schema => $App::CSVUtils::sch_req_str_or_code,
            cmdline_aliases => {k=>{}},
        },
        %App::CSVUtils::argspecopt_hash,
        %App::CSVUtils::argspecopt_with_data_rows,
    },
    add_args_rels => {
        'req_one&' => [ ['field', 'key'] ],
    },
    tags => ['category:summarizing', 'outputs-data-structure', 'accepts-code'],

    examples => [
        {
            summary => 'Show the age distribution of people',
            argv => ['people.csv', 'age'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Show the frequency of wins by a user, ignore case differences in user',
            argv => ['winner.csv', 'user', '-i'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Show the frequency of events by period (YYYY-MM)',
            argv => ['events.csv', '-H', '--key', 'sprintf("%04d-%02d", $_->{year}, $_->{month})'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    on_input_header_row => sub {
        my $r = shift;

        # check arguments
        my $field_idx;
        if (defined $r->{util_args}{field}) {
            $field_idx = $r->{input_fields_idx}{ $r->{util_args}{field} };
            die [404, "Field '$r->{util_args}{field}' not found in CSV"]
                unless defined $field_idx;
        }

        $r->{wants_input_row_as_hashref} = 1 if $r->{util_args}{hash};

        # this is a key we add to the stash
        $r->{freqtable} //= {};
        $r->{field_idx} = $field_idx;
        $r->{code} = undef;
        $r->{has_added_field} = 0;
        $r->{freq_field} = undef;
        $r->{input_rows} = [];
    },

    on_input_data_row => sub {
        my $r = shift;

        # add freq field
        if ($r->{util_args}{with_data_rows} && !$r->{has_added_field}++) {
            my $i = 1;
            while (1) {
                my $field = "freq" . ($i>1 ? $i : "");
                unless (defined $r->{input_fields_idx}{$field}) {
                    $r->{input_fields_idx}{$field} = @{ $r->{input_fields} };
                    push @{ $r->{input_fields} }, $field;
                    $r->{freq_field} = $field;
                    push @{ $r->{input_row} }, undef;
                    last;
                }
                $i++;
            }
        }

        my $field_val;
        if ($r->{util_args}{key}) {
            unless ($r->{code}) {
                $r->{code} = compile_eval_code($r->{util_args}{key}, 'key');
            }
            $field_val = eval_code($r->{code}, $r, $r->{wants_input_row_as_hashref} ? $r->{input_row_as_hashref} : $r->{input_row}) // '';
        } else {
            $field_val = $r->{input_row}[ $r->{field_idx} ];
        }

        if ($r->{util_args}{ignore_case}) {
            $field_val = lc $field_val;
        }

        $r->{freqtable}{$field_val}++;

        if ($r->{util_args}{with_data_rows}) {
            # we first put the field val, later we will fill the freq
            if ($r->{wants_input_row_as_hashref}) {
                $r->{input_row}{ $r->{freq_field} } = $field_val;
            } else {
                $r->{input_row}[-1] = $field_val;
            }
            push @{ $r->{input_rows} }, $r->{input_row};
        }
    },

    writes_csv => 1,

    after_close_input_files => sub {
        my $r = shift;

        if ($r->{util_args}{with_data_rows}) {
            for my $row (@{ $r->{input_rows} }) {
                if ($r->{wants_input_row_as_hashref}) {
                    my $field_val = $row->{ $r->{freq_field} };
                    $row->{ $r->{freq_field} } = $r->{freqtable}{ $field_val };
                } else {
                    my $field_val = $row->[-1];
                    $row->[-1] = $r->{freqtable}{ $field_val };
                }
                $r->{code_print_row}->($row);
            }
        }
    },

    on_end => sub {
        my $r = shift;

        if ($r->{util_args}{with_data_rows}) {
            $r->{result} = [200];
        } else {
            my @freqtable;
            for (sort { $r->{freqtable}{$b} <=> $r->{freqtable}{$a} } keys %{$r->{freqtable}}) {
                push @freqtable, [$_, $r->{freqtable}{$_}];
            }
            $r->{result} = [200, "OK", \@freqtable, {'table.fields'=>['value','freq']}];
        }
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

This document describes version 1.033 of App::CSVUtils::csv_freqtable (from Perl distribution App-CSVUtils), released on 2023-09-06.

=head1 FUNCTIONS


=head2 csv_freqtable

Usage:

 csv_freqtable(%args) -> [$status_code, $reason, $payload, \%result_meta]

Output a frequency table of values of a specified field in CSV.

Examples:

=over

=item * Show the age distribution of people:

 csv_freqtable(input_filename => "people.csv", field => "age");

=item * Show the frequency of wins by a user, ignore case differences in user:

 csv_freqtable(input_filename => "winner.csv", field => "user", ignore_case => 1);

=item * Show the frequency of events by period (YYYY-MM):

 csv_freqtable(
     input_filename => "events.csv",
   hash => 1,
   key => "sprintf(\"%04d-%02d\", \$_->{year}, \$_->{month})"
 );

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<field> => I<str>

Field name.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<ignore_case> => I<true>

Ignore case.

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

=item * B<key> => I<str|code>

Generate computed field with this Perl code.

If specified, then will compute field using Perl code.

The code will receive the row (arrayref, or if -H is specified, hashref) as the
argument. It should return the computed field (str).

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

=item * B<with_data_rows> => I<bool>

Whether to also output data rows.


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
