package App::CSVUtils::csv_sort_rows;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.007'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                );

sub on_input_header_row {
    my $r = shift;
    $r->{wants_input_row_as_hashref}++ if $r->{util_args}{hash};
}

sub on_input_data_row {
    my $r = shift;

    # keys we add to the stash
    $r->{input_rows} //= [];
    if ($r->{wants_input_row_as_hashref}) {
        $r->{input_rows_as_hashref} //= [];
    }

    push @{ $r->{input_rows} }, $r->{input_row};
    if ($r->{wants_input_row_as_hashref}) {
        push @{ $r->{input_rows_as_hashref} }, $r->{input_row_as_hashref};
    }
}

sub after_close_input_files {
    my $r = shift;

    # we do the actual sorting here after collecting all the rows

    # whether we should compute keys
    my @keys;
    if ($r->{util_args}{key}) {
        my $code_gen_key = compile_eval_code($r->{util_args}{key}, 'key');
        for my $row (@{ $r->{util_args}{hash} ? $r->{input_rows_as_hashref} : $r->{input_rows} }) {
            local $_ = $row;
            push @keys, $code_gen_key->($row);
        }
    }

    my $sorted_rows;
    if ($r->{util_args}{by_code} || $r->{util_args}{by_sortsub}) {

        my $code0;
        if ($r->{util_args}{by_code}) {
            $code0 = compile_eval_code($r->{util_args}{by_code}, 'by_code');
        } elsif (defined $r->{util_args}{by_sortsub}) {
            require Sort::Sub;
            $code0 = Sort::Sub::get_sorter(
                $r->{util_args}{by_sortsub}, $r->{util_args}{sortsub_args});
        }

        my $sort_indices;
        my $code;
        if (@keys) {
            # compare two sort keys ($a & $b) are indices
            $sort_indices++;
            $code = sub {
                local $main::a = $keys[$a];
                local $main::b = $keys[$b];
                #log_trace "a=<$main::a> vs b=<$main::b>";
                $code0->($main::a, $main::b);
            };
        } elsif ($r->{util_args}{hash}) {
            $sort_indices++;
            $code = sub {
                local $main::a = $r->{input_rows_as_hashref}[$a];
                local $main::b = $r->{input_rows_as_hashref}[$b];
                #log_trace "a=<%s> vs b=<%s>", $main::a, $main::b;
                $code0->($main::a, $main::b);
            };
        } else {
            $code = $code0;
        }

        if ($sort_indices) {
            my @sorted_indices = sort { local $main::a=$a; local $main::b=$b; $code->($main::a,$main::b) } 0..$#{$r->{input_rows}};
            $sorted_rows = [map {$r->{input_rows}[$_]} @sorted_indices];
        } else {
            $sorted_rows = [sort { local $main::a=$a; local $main::b=$b; $code->($main::a,$main::b) } @{$r->{input_rows}}];
        }

    } elsif ($r->{util_args}{by_fields}) {

        my @fields;
        my $code_str = "";
        for my $field_spec (@{ $r->{util_args}{by_fields} }) {
            my ($prefix, $field) = $field_spec =~ /\A([+~-]?)(.+)/;
            my $field_idx = $r->{input_fields_idx}{$field};
            die [400, "Unknown field '$field' (known fields include: ".
                 join(", ", map { "'$_'" } sort {$r->{input_fields_idx}{$a} <=> $r->{input_fields_idx}{$b}}
                      keys %{$r->{input_fields_idx}}).")"] unless defined $field_idx;
            $prefix //= "";
            if ($prefix eq '+') {
                $code_str .= ($code_str ? " || " : "") .
                    "(\$a->[$field_idx] <=> \$b->[$field_idx])";
            } elsif ($prefix eq '-') {
                $code_str .= ($code_str ? " || " : "") .
                    "(\$b->[$field_idx] <=> \$a->[$field_idx])";
            } elsif ($prefix eq '') {
                if ($r->{util_args}{ci}) {
                    $code_str .= ($code_str ? " || " : "") .
                        "(lc(\$a->[$field_idx]) cmp lc(\$b->[$field_idx]))";
                } else {
                    $code_str .= ($code_str ? " || " : "") .
                        "(\$a->[$field_idx] cmp \$b->[$field_idx])";
                }
            } elsif ($prefix eq '~') {
                if ($r->{util_args}{ci}) {
                    $code_str .= ($code_str ? " || " : "") .
                        "(lc(\$b->[$field_idx]) cmp lc(\$a->[$field_idx]))";
                } else {
                    $code_str .= ($code_str ? " || " : "") .
                        "(\$b->[$field_idx] cmp \$a->[$field_idx])";
                }
            }
        }
        my $code = compile_eval_code($code_str, 'from sort_by_fields');
        $sorted_rows = [sort { local $main::a = $a; local $main::b = $b; $code->($main::a, $main::b) } @{$r->{input_rows}}];

    } else {

        die [400, "Please specify by_fields or by_sortsub or by_code"];

    }

    if ($main::_CSV_SORTED_ROWS) {
        require Data::Cmp;
        #use DD; dd $r->{input_rows}; print "\n"; dd $sorted_rows;
        if (Data::Cmp::cmp_data($r->{input_rows}, $sorted_rows)) {
            # not sorted
            $r->{result} = [400, "NOT sorted", $r->{util_args}{quiet} ? undef : "Rows are NOT sorted"];
        } else {
            # sorted
            $r->{result} = [200, "Sorted", $r->{util_args}{quiet} ? undef : "Rows are sorted"];
        }
    } else {
        for my $row (@$sorted_rows) {
            $r->{code_print_row}->($row);
        }
    }
}

gen_csv_util(
    name => 'csv_sort_rows',
    summary => 'Sort CSV rows',
    description => <<'_',

This utility sorts the rows in the CSV. Example input CSV:

    name,age
    Andy,20
    Dennis,15
    Ben,30
    Jerry,30

Example output CSV (using `--by-field +age` which means by age numerically and
ascending):

    name,age
    Dennis,15
    Andy,20
    Ben,30
    Jerry,30

Example output CSV (using `--by-field -age`, which means by age numerically and
descending):

    name,age
    Ben,30
    Jerry,30
    Andy,20
    Dennis,15

Example output CSV (using `--by-field name`, which means by name ascibetically
and ascending):

    name,age
    Andy,20
    Ben,30
    Dennis,15
    Jerry,30

Example output CSV (using `--by-field ~name`, which means by name ascibetically
and descending):

    name,age
    Jerry,30
    Dennis,15
    Ben,30
    Andy,20

Example output CSV (using `--by-field +age --by-field ~name`):

    name,age
    Dennis,15
    Andy,20
    Jerry,30
    Ben,30

You can also reverse the sort order (`-r`) or sort case-insensitively (`-i`).

For more flexibility, instead of `--by-field` you can use `--by-code`:

Example output `--by-code '$a->[1] <=> $b->[1] || $b->[0] cmp $a->[0]'` (which
is equivalent to `--by-field +age --by-field ~name`):

    name,age
    Dennis,15
    Andy,20
    Jerry,30
    Ben,30

If you use `--hash`, your code will receive the rows to be compared as hashref,
e.g. `--hash --by-code '$a->{age} <=> $b->{age} || $b->{name} cmp $a->{name}'.

A third alternative is to sort using <pm:Sort::Sub> routines. Example output
(using `--by-sortsub 'by_length<r>' --key '$_->[0]'`, which is to say to sort by
descending length of name):

    name,age
    Dennis,15
    Jerry,30
    Andy,20
    Ben,30

_

    add_args => {
        %App::CSVUtils::argspecopt_hash,
        %App::CSVUtils::argspecs_sort_rows,
    },
    add_args_rels => {
        req_one => ['by_fields', 'by_code', 'by_sortsub'],
    },

    on_input_header_row => \&App::CSVUtils::csv_sort_rows::on_input_header_row,

    on_input_data_row => \&App::CSVUtils::csv_sort_rows::on_input_data_row,

    after_close_input_files => \&App::CSVUtils::csv_sort_rows::after_close_input_files,

);

1;
# ABSTRACT: Sort CSV rows

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_sort_rows - Sort CSV rows

=head1 VERSION

This document describes version 1.007 of App::CSVUtils::csv_sort_rows (from Perl distribution App-CSVUtils), released on 2023-02-03.

=for Pod::Coverage ^(on|after|before)_.+$

=head1 FUNCTIONS


=head2 csv_sort_rows

Usage:

 csv_sort_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort CSV rows.

This utility sorts the rows in the CSV. Example input CSV:

 name,age
 Andy,20
 Dennis,15
 Ben,30
 Jerry,30

Example output CSV (using C<--by-field +age> which means by age numerically and
ascending):

 name,age
 Dennis,15
 Andy,20
 Ben,30
 Jerry,30

Example output CSV (using C<--by-field -age>, which means by age numerically and
descending):

 name,age
 Ben,30
 Jerry,30
 Andy,20
 Dennis,15

Example output CSV (using C<--by-field name>, which means by name ascibetically
and ascending):

 name,age
 Andy,20
 Ben,30
 Dennis,15
 Jerry,30

Example output CSV (using C<--by-field ~name>, which means by name ascibetically
and descending):

 name,age
 Jerry,30
 Dennis,15
 Ben,30
 Andy,20

Example output CSV (using C<--by-field +age --by-field ~name>):

 name,age
 Dennis,15
 Andy,20
 Jerry,30
 Ben,30

You can also reverse the sort order (C<-r>) or sort case-insensitively (C<-i>).

For more flexibility, instead of C<--by-field> you can use C<--by-code>:

Example output C<< --by-code '$a-E<gt>[1] E<lt>=E<gt> $b-E<gt>[1] || $b-E<gt>[0] cmp $a-E<gt>[0]' >> (which
is equivalent to C<--by-field +age --by-field ~name>):

 name,age
 Dennis,15
 Andy,20
 Jerry,30
 Ben,30

If you use C<--hash>, your code will receive the rows to be compared as hashref,
e.g. `--hash --by-code '$a->{age} <=> $b->{age} || $b->{name} cmp $a->{name}'.

A third alternative is to sort using L<Sort::Sub> routines. Example output
(using C<< --by-sortsub 'by_lengthE<lt>rE<gt>' --key '$_-E<gt>[0]' >>, which is to say to sort by
descending length of name):

 name,age
 Dennis,15
 Jerry,30
 Andy,20
 Ben,30

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Sort by using Perl code.

C<$a> and C<$b> (or the first and second argument) will contain the two rows to be
compared. Which are arrayrefs; or if C<--hash> (C<-H>) is specified, hashrefs; or
if C<--key> is specified, whatever the code in C<--key> returns.

=item * B<by_fields> => I<array[str]>

Sort by a list of field specifications.

Each field specification is a field name with an optional prefix. C<FIELD>
(without prefix) means sort asciibetically ascending (smallest to largest),
C<~FIELD> means sort asciibetically descending (largest to smallest), C<+FIELD>
means sort numerically ascending, C<-FIELD> means sort numerically descending.

=item * B<by_sortsub> => I<str>

Sort using a Sort::Sub routine.

When sorting rows, usually combined with C<--key> because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

=item * B<ci> => I<bool>

(No description)

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

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

Generate sort keys with this Perl code.

If specified, then will compute sort keys using Perl code and sort using the
keys. Relevant when sorting using C<--by-code> or C<--by-sortsub>. If specified,
then instead of row when sorting rows, the code (or Sort::Sub routine) will
receive these sort keys to sort against.

The code will receive the row (arrayref, or if -H is specified, hashref) as the
argument.

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
