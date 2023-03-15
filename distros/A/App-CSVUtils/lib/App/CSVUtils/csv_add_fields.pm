package App::CSVUtils::csv_add_fields;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-10'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.022'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                        eval_code
                );

gen_csv_util(
    name => 'csv_add_fields',
    summary => 'Add one or more fields to CSV file',
    description => <<'_',

The new fields by default will be added at the end, unless you specify one of
`--after` (to put after a certain field), `--before` (to put before a certain
field), or `--at` (to put at specific position, 1 means the first field). The
new fields will be clustered together though, you currently cannot set the
position of each new field. But you can later reorder fields using
<prog:csv-sort-fields>.

If supplied, your Perl code (`-e`) will be called for each row (excluding the
header row) and should return the value for the new fields (either as a list or
as an arrayref). `$_` contains the current row (as arrayref, or if you specify
`-H`, as a hashref). `$main::row` is available and contains the current row
(always as an arrayref). `$main::rownum` contains the row number (2 means the
first data row). `$csv` is the <pm:Text::CSV_XS> object. `$main::fields_idx` is
also available for additional information.

If `-e` is not supplied, the new fields will be getting the default value of
empty string (`''`).

_
    add_args => {
        %App::CSVUtils::argspec_fields_1plus_nocomp,
        %App::CSVUtils::argspecopt_eval,
        %App::CSVUtils::argspecopt_hash,
        after => {
            summary => 'Put the new field(s) after specified field',
            schema => 'str*',
            completion => \&_complete_field,
        },
        before => {
            summary => 'Put the new field(s) before specified field',
            schema => 'str*',
            completion => \&_complete_field,
        },
        at => {
            summary => 'Put the new field(s) at specific position '.
                '(1 means at the front of all others)',
            schema => 'posint*',
        },
    },
    add_args_rels => {
        choose_one => [qw/after before at/],
    },
    examples => [
        {
            summary => 'Add a few new blank fields at the end',
            argv => ['file.csv', 'field4', 'field6', 'field5'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Add a few new blank fields after a certain field',
            argv => ['file.csv', 'field4', 'field6', 'field5', '--after', 'field2'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Add a new field and set its value',
            argv => ['file.csv', 'after_tax', '-e', '$main::row->[5] * 1.11'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Add a couple new fields and set their values',
            argv => ['file.csv', 'tax_rate', 'after_tax', '-e', '(0.11, $main::row->[5] * 1.11)'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    on_begin => sub {
        my $r = shift;

        # check arguments
        if (!defined($r->{util_args}{fields}) || !@{ $r->{util_args}{fields} }) {
            die [400, "Please specify one or more fields (-f)"];
        }
    },

    on_input_header_row => sub {
        my $r = shift;

        # check that the new fields are not duplicate (against existing fields
        # and against itself)
        my %seen;
        for (@{ $r->{util_args}{fields} }) {
            unless (length $_) {
                die [400, "New field name cannot be empty"];
            }
            if (defined $r->{input_fields_idx}{$_}) {
                die [412, "Field '$_' already exists"];
            }
            if ($seen{$_}++) {
                die [412, "Duplicate new field '$_'"];
            }
        }

        # determine the position at which to insert the new fields
        my $new_fields_idx;
        if (defined $r->{util_args}{at}) {
            $new_fields_idx = $r->{util_args}{at}-1;
        } elsif (defined $r->{util_args}{before}) {
            for (0..$#{ $r->{input_fields} }) {
                if ($r->{input_fields}[$_] eq $r->{util_args}{before}) {
                    $new_fields_idx = $_;
                    last;
                }
            }
            die [400, "Field '$r->{util_args}{before}' (to add new fields before) not found"]
                unless defined $new_fields_idx;
        } elsif (defined $r->{util_args}{after}) {
            for (0..$#{ $r->{input_fields} }) {
                if ($r->{input_fields}[$_] eq $r->{util_args}{after}) {
                    $new_fields_idx = $_+1;
                    last;
                }
            }
            die [400, "Field '$r->{util_args}{after}' (to add new fields after) not found"]
                unless defined $new_fields_idx;
        } else {
            $new_fields_idx = @{ $r->{input_fields} };
        }

        # for printing the header
        $r->{output_fields} = [@{ $r->{input_fields} }];
        splice @{ $r->{output_fields} }, $new_fields_idx, 0, @{ $r->{util_args}{fields} };

        $r->{wants_input_row_as_hashref} = 1 if $r->{util_args}{hash};

        # we add the following keys to the stash
        $r->{code} = compile_eval_code($r->{util_args}{eval} // 'return', 'eval');
        $r->{new_fields_idx} = $new_fields_idx;
    },

    on_input_data_row => sub {
        my $r = shift;

        my @vals;
        eval { @vals = eval_code($r->{code}, $r, $r->{wants_input_row_as_hashref} ? $r->{input_row_as_hashref} : $r->{input_row}) };
        die [500, "Error while adding field(s) '".join(",", @{$r->{util_args}{fields}})."' for row #$r->{input_rownum}: $@"]
            if $@;
        if (ref $vals[0] eq 'ARRAY') { @vals = @{ $vals[0] } }
        splice @{ $r->{input_row} }, $r->{new_fields_idx}, 0,
            (map { $_ // '' } @vals[0 .. $#{$r->{util_args}{fields}}]);
        $r->{code_print_row}->($r->{input_row});
    },
);

1;
# ABSTRACT: Add one or more fields to CSV file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_add_fields - Add one or more fields to CSV file

=head1 VERSION

This document describes version 1.022 of App::CSVUtils::csv_add_fields (from Perl distribution App-CSVUtils), released on 2023-03-10.

=head1 FUNCTIONS


=head2 csv_add_fields

Usage:

 csv_add_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add one or more fields to CSV file.

Examples:

=over

=item * Add a few new blank fields at the end:

 csv_add_fields(
     input_filename => "file.csv",
   fields => ["field4", "field6", "field5"]
 );

=item * Add a few new blank fields after a certain field:

 csv_add_fields(
     input_filename => "file.csv",
   fields => ["field4", "field6", "field5"],
   after => "field2"
 );

=item * Add a new field and set its value:

 csv_add_fields(
     input_filename => "file.csv",
   fields => ["after_tax"],
   eval => "\$main::row->[5] * 1.11"
 );

=item * Add a couple new fields and set their values:

 csv_add_fields(
     input_filename => "file.csv",
   fields => ["tax_rate", "after_tax"],
   eval => "(0.11, \$main::row->[5] * 1.11)"
 );

=back

The new fields by default will be added at the end, unless you specify one of
C<--after> (to put after a certain field), C<--before> (to put before a certain
field), or C<--at> (to put at specific position, 1 means the first field). The
new fields will be clustered together though, you currently cannot set the
position of each new field. But you can later reorder fields using
L<csv-sort-fields>.

If supplied, your Perl code (C<-e>) will be called for each row (excluding the
header row) and should return the value for the new fields (either as a list or
as an arrayref). C<$_> contains the current row (as arrayref, or if you specify
C<-H>, as a hashref). C<$main::row> is available and contains the current row
(always as an arrayref). C<$main::rownum> contains the row number (2 means the
first data row). C<$csv> is the L<Text::CSV_XS> object. C<$main::fields_idx> is
also available for additional information.

If C<-e> is not supplied, the new fields will be getting the default value of
empty string (C<''>).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<after> => I<str>

Put the new field(s) after specified field.

=item * B<at> => I<posint>

Put the new field(s) at specific position (1 means at the front of all others).

=item * B<before> => I<str>

Put the new field(s) before specified field.

=item * B<eval> => I<str|code>

Perl code.

=item * B<fields>* => I<array[str]>

Field names.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

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
