package App::CSVUtils::csv_check_field_values;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-06'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.033'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                        compile_eval_code
                );

gen_csv_util(
    name => 'csv_check_field_values',
    summary => 'Check the values of whole fields against code/schema',
    description => <<'_',

Example `input.csv`:

    ingredient,%weight
    foo,81
    bar,9
    baz,10

Example `input2.csv`:

    ingredient,%weight
    foo,81
    bar,9
    baz,10

Check that ingredients are sorted in descending %weight:

    % csv-check-field-values input.csv %weight --with-schema array::num::rev_sorted
    ERROR 400: Field '%weight' does not validate with schema 'array::num::rev_sorted'

    % csv-check-field-values input2.csv %weight --with-schema array::num::rev_sorted
    Field '%weight' validates with schema 'array::num::rev_sorted'

_

    add_args => {
        %App::CSVUtils::argspec_field_1,
        with_code => {
            summary => 'Check with Perl code',
            schema => $App::CSVUtils::sch_req_str_or_code,
            description => <<'_',

Code will be given the value of the rows of the field as an array of scalars and
should return a true value if value is valid.

_
        },
        with_schema => {
            summary => 'Check with a Sah schema module',
            schema => ['any*', of=>[
                ['str*', min_len=>1], # string schema
                ['array*', max_len=>2], # an array schema
            ]],
            description => <<'_',

Should be the name of a Sah schema module without the `Sah::Schema::` prefix,
typically in the `Sah::Schema::array::` subnamespace.

_
            completion => sub {
                require Complete::Module;
                my %args = @_;
                $args{word} = "array/" unless length $args{word};
                Complete::Module::complete_module(
                    word => $args{word},
                    ns_prefix => "Sah::Schema::",
                );
            },
        },
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
    add_args_rels => {
        req_one => ['with_code', 'with_schema'],
    },
    links => [
        {url=>'prog:csv-check-cell-values', summary=>'Check single-cell values'},
        {url=>'prog:csv-check-field-names', summary=>'Check the field names'},
    ],
    tags => ['category:checking', 'accepts-schema', 'accepts-code',
             #'accepts-regex',
         ],

    writes_csv => 0,

    on_input_data_row => sub {
        my $r = shift;

        # keys we add to the stash
        $r->{value} //= [];

        push @{ $r->{value} }, $r->{input_row}[ $r->{input_fields_idx}{ $r->{util_args}{field} } ];
    },

    after_close_input_files => sub {
        my $r = shift;

        if ($r->{util_args}{with_schema}) {
            require Data::Dmp;
            require Data::Sah;
            my $sch = $r->{util_args}{with_schema};
            if (!ref($sch)) {
                $sch =~ s!/!::!g;
            }
            my $vdr = Data::Sah::gen_validator($sch, {return_type=>"str_errmsg"});
            my $res = $vdr->($r->{value});
            if ($res) {
                my $msg = "Field '$r->{util_args}{field}' does NOT validate with schema ".Data::Dmp::dmp($sch).": $res";
                $r->{result} = [400, $msg, $r->{util_args}{quiet} ? undef : $msg];
            } else {
                my $msg = "Field '$r->{util_args}{field}' validates with schema ".Data::Dmp::dmp($sch);
                $r->{result} = [200, "Sorted", $r->{util_args}{quiet} ? undef : $msg];
            }
        } elsif ($r->{util_args}{with_code}) {
            my $code = compile_eval_code($r->{util_args}{with_code}, 'with_code');
            my $res; { local $_ = $r->{value}; $res = $code->($_) }
            if (!$res) {
                my $msg = "Field '$r->{util_args}{field}' does NOT validate with code'";
                $r->{result} = [400, $msg, $r->{util_args}{quiet} ? undef : $msg];
            } else {
                my $msg = "Field '$r->{util_args}{field}' validates with code";
                $r->{result} = [200, "Sorted", $r->{util_args}{quiet} ? undef : $msg];
            }
        }
    },
);

1;
# ABSTRACT: Check the values of whole fields against code/schema

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_check_field_values - Check the values of whole fields against code/schema

=head1 VERSION

This document describes version 1.033 of App::CSVUtils::csv_check_field_values (from Perl distribution App-CSVUtils), released on 2023-09-06.

=head1 FUNCTIONS


=head2 csv_check_field_values

Usage:

 csv_check_field_values(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check the values of whole fields against codeE<sol>schema.

Example C<input.csv>:

 ingredient,%weight
 foo,81
 bar,9
 baz,10

Example C<input2.csv>:

 ingredient,%weight
 foo,81
 bar,9
 baz,10

Check that ingredients are sorted in descending %weight:

 % csv-check-field-values input.csv %weight --with-schema array::num::rev_sorted
 ERROR 400: Field '%weight' does not validate with schema 'array::num::rev_sorted'
 
 % csv-check-field-values input2.csv %weight --with-schema array::num::rev_sorted
 Field '%weight' validates with schema 'array::num::rev_sorted'

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<field>* => I<str>

Field name.

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

=item * B<quiet> => I<bool>

(No description)

=item * B<with_code> => I<str|code>

Check with Perl code.

Code will be given the value of the rows of the field as an array of scalars and
should return a true value if value is valid.

=item * B<with_schema> => I<str|array>

Check with a Sah schema module.

Should be the name of a Sah schema module without the C<Sah::Schema::> prefix,
typically in the C<Sah::Schema::array::> subnamespace.


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
