package App::CSVUtils::csv_find_values;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-02'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.005'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );

gen_csv_util(
    name => 'csv_find_values',
    summary => 'Find specified values in a CSV field',
    description => <<'_',

Example input:

    # product.csv
    sku,name,is_active,description
    SKU1,foo,1,blah
    SK2,bar,1,blah
    SK3B,baz,0,blah
    SKU2,qux,1,blah
    SKU3,quux,1,blah
    SKU14,corge,0,blah

Check whether specified values are found in the `sku` column, print message
when they are (search case-insensitively):

    % csv-find-values product.csv sku sku1 sk3b sku15 -i
    'sku1' is found in column 'sku' row 2
    'sk3b' is found in column 'sku' row 4

Print message when values are *not* found instead:

    % csv-find-values product.csv sku sku1 sk3b sku15 -i --print-when=not_found
    'sku15' is NOT found in column 'sku'

Always print message:

    % csv-find-values product.csv sku sku1 sk3b sku15 -i --print-when=always
    'sku1' is found in column 'sku' row 2
    'sk3b' is found in column 'sku' row 4
    'sku15' is NOT found in column 'sku'

Do custom action with Perl code, code will receive `$_` (the value being
evaluated), `$found` (bool, whether it is found in the column), `$rownum` (the
row number the value is found in), `$data_rownum` (the data row number the value
is found in, equals `$rownum` - 1):

    % csv-find-values product.csv sku1 sk3b sku15 -i -e 'if ($found) { print "$_ found\n" } else { print "$_ NOT found\n" }'
    sku1 found
    sk3b found
    sku15 NOT found

There is an option to do fuzzy matching, where similar values will be suggested
when exact match is not found.

_
    add_args => {
        ignore_case => {
            schema => 'bool*',
            cmdline_aliases => {ci=>{}, i=>{}},
            tags => ['category:searching'],
        },
        fuzzy => {
            schema => 'true*',
            tags => ['category:searching'],
        },

        %App::CSVUtils::argspec_field_1,

        values => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'value',
            schema => ['array*', of=>'str*', min_len=>1],
            req => 1,
            pos => 2,
            slurpy => 1,
        },
        print_when => {
            schema => ['str*', in=>[qw/found not_found always/]],
            default => 'found',
            description => <<'_',

Overriden by the `--eval` option.

_
            tags => ['category:output'],
        },
        %App::CSVUtils::argspecopt_eval,
    },

    writes_csv => 0,

    on_input_header_row => sub {
        my $r = shift;

        # check arguments
        my $field = $r->{util_args}{field};
        my $field_idx = $r->{input_fields_idx}{$field};
        die [404, "Unknown field '$field'"] unless defined $field_idx;

        # we add the following keys to the stash
        $r->{field} = $field;
        $r->{field_idx} = $field_idx;
        $r->{code} = compile_eval_code($r->{util_args}{eval}, 'eval') if defined $r->{util_args}{eval};
        $r->{csv_values} = [];
        $r->{search_values} = $r->{util_args}{ignore_case} ?
            [ map { lc } @{ $r->{util_args}{values} }] : $r->{util_args}{values};
    },

    on_input_data_row => sub {
        my $r = shift;

        my $val = ($r->{input_row}[ $r->{field_idx} ] // '');
        if ($r->{util_args}{ignore_case}) { $val = lc $val }
        push @{ $r->{csv_values} }, $val;
    },

    after_close_input_files => sub {
        my $r = shift;

        my $ci = $r->{util_args}{ignore_case};

        my $maxdist;
        for my $i (0 .. $#{ $r->{util_args}{values} }) {
            my $value = $r->{util_args}{values}[$i];
            my $search_value = $r->{search_values}[$i];
            my $found_rownum;

            my $j = 0;
            for my $v (@{ $r->{csv_values} }) {
                $j++;
                if ($v eq $search_value) { $found_rownum = $j; last }
            }

            my $suggested_values;
            if (!defined($found_rownum) && $r->{util_args}{fuzzy}) {
                # XXX with this, we do exact matching twice
                require Complete::Util;
                local $Complete::Common::OPT_CI = 1;
                local $Complete::Common::OPT_MAP_CASE = 0;
                local $Complete::Common::OPT_WORD_MODE = 0;
                local $Complete::Common::OPT_CHAR_MODE = 0;
                local $Complete::Common::OPT_FUZZY = 1;
                $suggested_values = Complete::Util::complete_array_elem(
                    array => $r->{csv_values},
                    word => $value,
                );
            }

            if ($r->{code}) {
                {
                    local $_ = $value;
                    local $main::found = defined $found_rownum ? 1:0;
                    local $main::rownum = $found_rownum+1;
                    local $main::data_rownum = $found_rownum;
                    local $main::r = $r;
                    local $main::csv = $r->{input_parser};
                    $r->{code}->($_);
                }
            } else {
                if (defined $found_rownum) {
                    if ($r->{util_args}{print_when} eq 'found' || $r->{util_args}{print_when} eq 'always') {
                        print "'$value' is found in column '$r->{field}' row ".($found_rownum+1)."\n";
                    }
                } else {
                    if ($r->{util_args}{print_when} eq 'not_found' || $r->{util_args}{print_when} eq 'always') {
                        print "'$value' is NOT found in column '$r->{field}'".($suggested_values && @$suggested_values ? ", perhaps you meant ".join("/", @$suggested_values)."?" : "")."\n";
                    }
                }
            }
        }
    },
);

1;
# ABSTRACT: Find specified values in a CSV field

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_find_values - Find specified values in a CSV field

=head1 VERSION

This document describes version 1.005 of App::CSVUtils::csv_find_values (from Perl distribution App-CSVUtils), released on 2023-02-02.

=head1 FUNCTIONS


=head2 csv_find_values

Usage:

 csv_find_values(%args) -> [$status_code, $reason, $payload, \%result_meta]

Find specified values in a CSV field.

Example input:

 # product.csv
 sku,name,is_active,description
 SKU1,foo,1,blah
 SK2,bar,1,blah
 SK3B,baz,0,blah
 SKU2,qux,1,blah
 SKU3,quux,1,blah
 SKU14,corge,0,blah

Check whether specified values are found in the C<sku> column, print message
when they are (search case-insensitively):

 % csv-find-values product.csv sku sku1 sk3b sku15 -i
 'sku1' is found in column 'sku' row 2
 'sk3b' is found in column 'sku' row 4

Print message when values are I<not> found instead:

 % csv-find-values product.csv sku sku1 sk3b sku15 -i --print-when=not_found
 'sku15' is NOT found in column 'sku'

Always print message:

 % csv-find-values product.csv sku sku1 sk3b sku15 -i --print-when=always
 'sku1' is found in column 'sku' row 2
 'sk3b' is found in column 'sku' row 4
 'sku15' is NOT found in column 'sku'

Do custom action with Perl code, code will receive C<$_> (the value being
evaluated), C<$found> (bool, whether it is found in the column), C<$rownum> (the
row number the value is found in), C<$data_rownum> (the data row number the value
is found in, equals C<$rownum> - 1):

 % csv-find-values product.csv sku1 sk3b sku15 -i -e 'if ($found) { print "$_ found\n" } else { print "$_ NOT found\n" }'
 sku1 found
 sk3b found
 sku15 NOT found

There is an option to do fuzzy matching, where similar values will be suggested
when exact match is not found.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<eval> => I<str|code>

Perl code.

=item * B<field>* => I<str>

Field name.

=item * B<fuzzy> => I<true>

(No description)

=item * B<ignore_case> => I<bool>

(No description)

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

=item * B<print_when> => I<str> (default: "found")

Overriden by the C<--eval> option.

=item * B<values>* => I<array[str]>

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
