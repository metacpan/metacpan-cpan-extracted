package App::CSVUtils::csv_check_cell;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.008'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                );

gen_csv_util(
    name => 'csv_check_cell',
    summary => 'Check the value of cells of CSV against code/schema/regex',
    description => <<'_',

Example `input.csv`:

    ingredient,%weight
    foo,81
    bar,9
    baz,10

Check that ingredients do not contain number:

    % csv-check-cell input.csv -f ingredient --with-regex '/\\A[A-Za-z ]+\\z/'

Check that all %weight is between 0 and 100:

    % csv-check-cell input.csv -f %weight --with-code '$_>0 && $_<=100'

_

    add_args => {
        %App::CSVUtils::argspecsopt_field_selection,
        with_code => {
            summary => 'Check with Perl code',
            schema => $App::CSVUtils::sch_req_str_or_code,
            description => <<'_',

Code will be given the value of the cell and should return a true value if value
is valid.

_
        },
        with_schema => {
            summary => 'Check with a Sah schema',
            schema => ['any*', of=>[
                ['str*', min_len=>1], # string schema
                ['array*', max_len=>2], # an array schema
            ]],
            completion => sub {
                require Complete::Module;
                my %args = @_;
                Complete::Module::complete_module(
                    word => $args{word},
                    ns_prefix => "Sah::Schema::",
                );
            },
        },
        with_regex => {
            schema => 're_from_str*',
        },

        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
        print_validated => {
            summary => 'Print the validated values of each cell',
            schema => 'bool*',
            description => <<'_',

When validating with schema, will print each validated (possible coerced,
filtered) value of each cell.

_
        },
    },
    add_args_rels => {
        req_one => ['with_code', 'with_schema', 'with_regex'],
    },

    writes_csv => 0,

    on_input_data_row => sub {
        my $r = shift;

        # key we add to the stash
        unless (defined $r->{code}) {
            if ($r->{util_args}{with_schema}) {
                require Data::Sah;
                my $sch = $r->{util_args}{with_schema};
                if (!ref($sch)) {
                    $sch =~ s!/!::!g;
                }
                $r->{code} = Data::Sah::gen_validator($sch, {return_type=>"str_errmsg+val"});
            } elsif ($r->{util_args}{with_code}) {
                my $code0 = compile_eval_code($r->{util_args}{with_code}, 'with_code');
                $r->{code} = sub {
                    local $_ = $_[0]; my $res = $code0->($_);
                    [($res ? "":"FAIL"), $res];
                };
            } elsif (defined $r->{util_args}{with_regex}) {
                $r->{code} = sub {
                    $_[0] =~ $r->{util_args}{with_regex} ? ["", $_[0]] : ["Does not match regex $r->{util_args}{with_regex}", $_[0]];
                };
            }
        }

        # key we add to the stash
        unless ($r->{selected_fields_idx_array_sorted}) {
            my $res = App::CSVUtils::_select_fields($r->{input_fields}, $r->{input_fields_idx}, $r->{util_args});
            die $res unless $res->[0] == 100;
            my $selected_fields = $res->[2][0];
            my $selected_fields_idx_array = $res->[2][1];
            die [412, "At least one field must be selected"]
                unless @$selected_fields;
            $r->{selected_fields_idx_array_sorted} = [sort { $b <=> $a } @$selected_fields_idx_array];
        }

        for my $idx (@{ $r->{selected_fields_idx_array_sorted} }) {
            my $res = $r->{code}->( $r->{input_row}[$idx] );
            if ($res->[0]) {
                my $msg = "Row #$r->{input_data_rownum} field '$r->{input_fields}[$idx]': Value '$r->{input_row}[$idx]' does NOT validate: $res->[0]";
                $r->{result} = [400, $msg, $r->{util_args}{quiet} ? undef : $msg];
                $r->{wants_skip_files}++;
            } else {
                if ($r->{util_args}{print_validated}) {
                    print $res->[1], "\n";
                }
            }
        }
    },

    after_close_input_files => sub {
        my $r = shift;

        $r->{result} //= [200, "OK", $r->{util_args}{quiet} ? undef : "All cells validate"];
    },
);

1;
# ABSTRACT: Check the value of cells of CSV against code/schema/regex

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_check_cell - Check the value of cells of CSV against code/schema/regex

=head1 VERSION

This document describes version 1.008 of App::CSVUtils::csv_check_cell (from Perl distribution App-CSVUtils), released on 2023-02-03.

=head1 FUNCTIONS


=head2 csv_check_cell

Usage:

 csv_check_cell(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check the value of cells of CSV against codeE<sol>schemaE<sol>regex.

Example C<input.csv>:

 ingredient,%weight
 foo,81
 bar,9
 baz,10

Check that ingredients do not contain number:

 % csv-check-cell input.csv -f ingredient --with-regex '/\\A[A-Za-z ]+\\z/'

Check that all %weight is between 0 and 100:

 % csv-check-cell input.csv -f %weight --with-code '$_>0 && $_<=100'

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

=item * B<print_validated> => I<bool>

Print the validated values of each cell.

When validating with schema, will print each validated (possible coerced,
filtered) value of each cell.

=item * B<quiet> => I<bool>

(No description)

=item * B<show_selected_fields> => I<true>

Show selected fields and then immediately exit.

=item * B<with_code> => I<str|code>

Check with Perl code.

Code will be given the value of the cell and should return a true value if value
is valid.

=item * B<with_regex> => I<re_from_str>

(No description)

=item * B<with_schema> => I<str|array>

Check with a Sah schema.


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
