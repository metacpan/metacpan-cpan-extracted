package App::CSVUtils::csv_delete_fields;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-02'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.034'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );

gen_csv_util(
    name => 'csv_delete_fields',
    summary => 'Delete one or more fields from CSV file',
    add_args => {
        %App::CSVUtils::argspecsopt_field_selection,
    },
    tags => ['category:munging','deletes-fields'],

    examples => [
        {
            summary => 'Delete a single field from CSV',
            argv => ['file.csv', '-f', 'f1'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Delete several fields from CSV',
            argv => ['file.csv', '-f', 'f1', '-f', 'f2', '-f', 'f3'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Delete fields matching regex from CSV',
            argv => ['file.csv', '--include-field-pat', '/^extra_/'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Delete all fields except specified from CSV',
            argv => ['file.csv', '-a', '-f', 'f1', '-f', 'f2'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Only show what fields would be included, then exit',
            argv => ['file.csv', '--include-field-pat', '/^extra_/', '--show-selected-fields'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    on_input_data_row => sub {
        my $r = shift;

        # we add the following keys to the stash
        unless ($r->{selected_fields_idx_array_sorted}) {
            my $res = App::CSVUtils::_select_fields($r->{input_fields}, $r->{input_fields_idx}, $r->{util_args});
            die $res unless $res->[0] == 100;
            my $selected_fields = $res->[2][0];
            my $selected_fields_idx_array = $res->[2][1];
            die [412, "At least one field must remain"]
                if @{ $selected_fields } == @{ $r->{input_fields} };
            $r->{selected_fields_idx_array_sorted} = [sort { $b <=> $a } @$selected_fields_idx_array];

            # set ouput fields
            $r->{output_fields} = [@{ $r->{input_fields} }];
            for (@{ $r->{selected_fields_idx_array_sorted} }) {
                splice @{ $r->{output_fields} }, $_, 1;
            }

            if ($r->{util_args}{show_selected_fields}) {
                $r->{wants_skip_files}++;
                $r->{result} = [200, "OK", $selected_fields];
                return;
            }
        }

        for (@{ $r->{selected_fields_idx_array_sorted} }) {
            splice @{ $r->{input_row} }, $_, 1;
        }

        $r->{code_print_row}->($r->{input_row});
    },
);

1;
# ABSTRACT: Delete one or more fields from CSV file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_delete_fields - Delete one or more fields from CSV file

=head1 VERSION

This document describes version 1.034 of App::CSVUtils::csv_delete_fields (from Perl distribution App-CSVUtils), released on 2024-02-02.

=head1 FUNCTIONS


=head2 csv_delete_fields

Usage:

 csv_delete_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete one or more fields from CSV file.

Examples:

=over

=item * Delete a single field from CSV:

 csv_delete_fields(input_filename => "file.csv", include_fields => ["f1"]);

=item * Delete several fields from CSV:

 csv_delete_fields(input_filename => "file.csv", include_fields => ["f1", "f2", "f3"]);

=item * Delete fields matching regex from CSV:

 csv_delete_fields(input_filename => "file.csv", include_field_pat => "/^extra_/");

=item * Delete all fields except specified from CSV:

 csv_delete_fields(
     input_filename    => "file.csv",
   include_field_pat => ".*",
   include_fields    => ["f1", "f2"]
 );

=item * Only show what fields would be included, then exit:

 csv_delete_fields(
     input_filename       => "file.csv",
   include_field_pat    => "/^extra_/",
   show_selected_fields => 1
 );

=back

(No description)

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_field_pat> => I<re>

Field regex pattern to exclude, takes precedence over --field-pat.

=item * B<exclude_fields> => I<array[str]>

Field names to exclude, takes precedence over --fields.

=item * B<ignore_unknown_fields> => I<bool>

When unknown fields are specified in --include-field (--field) or --exclude-field options, ignore them instead of throwing an error.

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
