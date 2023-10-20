package App::CSVUtils::csv_sort_fields;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.031'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                );

sub on_input_header_row {
    my $r = shift;

    my $code;
    my $code_gets_field_with_pos;
    if ($r->{util_args}{by_code}) {
        $code_gets_field_with_pos++;
        $code = compile_eval_code($r->{util_args}{by_code}, 'by_code');
    } elsif (defined $r->{util_args}{by_sortsub}) {
        require Sort::Sub;
        $code = Sort::Sub::get_sorter(
            $r->{util_args}{by_sortsub}, $r->{util_args}{sortsub_args});
    } elsif (my $eg = $r->{util_args}{by_examples}) {
        require Sort::ByExample;
        $code = Sort::ByExample->cmp($eg);
    } else {
        $code = sub { $_[0] cmp $_[1] };
    }

    my @sorted_indices = sort {
        my $field_a = $r->{util_args}{ci} ? lc($r->{input_fields}[$a]) : $r->{input_fields}[$a];
        my $field_b = $r->{util_args}{ci} ? lc($r->{input_fields}[$b]) : $r->{input_fields}[$b];
        local $main::a = $code_gets_field_with_pos ? [$field_a, $a] : $field_a;
        local $main::b = $code_gets_field_with_pos ? [$field_b, $b] : $field_b;
        ($r->{util_args}{reverse} ? -1:1) * $code->($main::a, $main::b);
    } 0..$#{$r->{input_fields}};

    $r->{output_fields} = [map {$r->{input_fields}[$_]} @sorted_indices];
    $r->{output_fields_idx_array} = \@sorted_indices; # this is a key we add to stash
}

sub on_input_data_row {
    my $r = shift;

    if ($main::_CSV_SORTED_FIELDS) {
        require Data::Cmp;
        #use DD; dd $r->{input_fields}; print "\n"; dd $r->{output_fields};
        if (Data::Cmp::cmp_data($r->{input_fields}, $r->{output_fields})) {
            # not sorted
            $r->{result} = [400, "NOT sorted", $r->{util_args}{quiet} ? undef : "Fields are NOT sorted"];
        } else {
            # sorted
            $r->{result} = [200, "Sorted", $r->{util_args}{quiet} ? undef : "Fields are sorted"];
        }
        $r->{wants_skip_files}++;
        return;
    } else {
        my $row = [];
        for my $j (@{ $r->{output_fields_idx_array} }) {
            push @$row, $r->{input_row}[$j];
        }
        $r->{code_print_row}->($row);
    }
}

gen_csv_util(
    name => 'csv_sort_fields',
    summary => 'Sort CSV fields',
    description => <<'_',

This utility sorts the order of fields in the CSV. Example input CSV:

    b,c,a
    1,2,3
    4,5,6

Example output CSV:

    a,b,c
    3,1,2
    6,4,5

You can also reverse the sort order (`-r`), sort case-insensitively (`-i`), or
provides the ordering example, e.g. `--by-examples-json '["a","c","b"]'`, or use
`--by-code` or `--by-sortsub`.

_

    add_args => {
        %App::CSVUtils::argspecs_sort_fields,
    },
    add_args_rels => {
        choose_one => ['by_examples', 'by_code', 'by_sortsub'],
    },

    tags => ['category:sorting'],

    on_input_header_row => \&on_input_header_row,

    on_input_data_row => \&on_input_data_row,

);

1;
# ABSTRACT: Sort CSV fields

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_sort_fields - Sort CSV fields

=head1 VERSION

This document describes version 1.031 of App::CSVUtils::csv_sort_fields (from Perl distribution App-CSVUtils), released on 2023-08-06.

=for Pod::Coverage ^(on|after|before)_.+$

=head1 FUNCTIONS


=head2 csv_sort_fields

Usage:

 csv_sort_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort CSV fields.

This utility sorts the order of fields in the CSV. Example input CSV:

 b,c,a
 1,2,3
 4,5,6

Example output CSV:

 a,b,c
 3,1,2
 6,4,5

You can also reverse the sort order (C<-r>), sort case-insensitively (C<-i>), or
provides the ordering example, e.g. C<--by-examples-json '["a","c","b"]'>, or use
C<--by-code> or C<--by-sortsub>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Sort fields using Perl code.

C<$a> and C<$b> (or the first and second argument) will contain C<[$field_name,
$field_idx]>.

=item * B<by_examples> => I<array[str]>

Sort by a list of field names as examples.

=item * B<by_sortsub> => I<str>

Sort using a Sort::Sub routine.

When sorting rows, usually combined with C<--key> because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

=item * B<ci> => I<bool>

(No description)

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

=item * B<reverse> => I<bool>

(No description)

=item * B<sortsub_args> => I<hash>

Arguments to pass to Sort::Sub routine.


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
