package App::CSVUtils::csv_mix_formulas;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-24'; # DATE
our $DIST = 'App-CSVUtils-csv_mix_formulas'; # DIST
our $VERSION = '0.002'; # VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );
use List::Util qw(sum);

gen_csv_util(
    name => 'csv_mix_formulas',
    summary => 'Mix several formulas/recipes (lists of ingredients and their weights/volumes) into one, '.
        'and output the combined formula',
    description => <<'MARKDOWN',

Each formula is a CSV comprised of at least two fields. The first field (by
default literally the first field, but can also be specified using
`--ingredient-field`) is assumed to contain the name of ingredients. The second
field (by default literally the second field, but can also be specified using
`--weight-field`) is assumed to contain the weight of ingredients. A percent
form is recognized and will be converted to its decimal form (e.g. "60%" or
"60.0 %" will become 0.6).

Example, mixing this CSV:

    ingredient,%weight,extra-field1,extra-field2
    water,80,foo,bar
    sugar,15,foo,bar
    citric acid,0.3,foo,bar
    strawberry syrup,4.7,foo,bar

and this:

    ingredient,%weight,extra-field1,extra-field2,extra-field3
    lemon syrup,5.75,bar,baz,qux
    citric acid,0.25,bar,baz,qux
    sugar,14,bar,baz,qux
    water,80,bar,baz,qux

will result in the following CSV. Note: 1) for the header, except for the first
two fields which are the ingredient name and weight which will contain the mixed
formula, the other fields will simply collect values from all the CSV files. 2)
for sorting order: decreasing weight then by name.

    ingredient,%weight,extra-field1,extra-field2,extra-field3
    water,80,foo,bar,qux
    sugar,14.5,foor,bar,qux
    lemon syrup,2.875,bar,baz,qux
    strawberry syrup,2.35,foo,bar,
    citric acid,0.275,foo,bar,qux

Keywords: compositions, mixture, combine

MARKDOWN
    add_args => {
        ingredient_field => {
            summary => 'Specify field which contain the ingredient names',
            schema => 'str*',
        },
        weight_field => {
            summary => 'Specify field which contain the weights',
            schema => 'str*',
        },
        output_format => {
            summary => 'A sprintf() template to format the weight',
            schema => 'str*',
            tags => ['category:formatting'],
        },
        output_percent => {
            summary => 'If enabled, will convert output weights to percent with the percent sign (e.g. 0.6 to "60%")',
            schema => 'bool*',
            tags => ['category:formatting'],
        },
        output_percent_nosign => {
            summary => 'If enabled, will convert output weights to percent without the percent sign (e.g. 0.6 to "60")',
            schema => 'bool*',
            tags => ['category:formatting'],
        },
    },
    add_args_rels => {
        choose_one => ['output_percent', 'output_percent_nosign'],
        choose_all => ['ingredient_field', 'weight_field'],
    },
    tags => ['category:combining'],

    # we modify from csv-concat

    reads_multiple_csv => 1,

    before_open_input_files => sub {
        my $r = shift;

        # we add the following keys to the stash
        $r->{all_input_fields} = [];
        $r->{all_input_fh} = [];
        $r->{ingredient_field} = undef;
        $r->{weight_field} = undef;
    },

    on_input_header_row => sub {
        my $r = shift;

        # TODO: allow to customize
        if ($r->{input_filenum} == 1) {
            # assign the ingredient field and weight field
            if (defined $r->{util_args}{ingredient_field}) {
                die "csv-mix-formulas: FATAL: Specified ingredient field does not exist\n"
                    unless defined $r->{input_fields_idx}{ $r->{util_args}{ingredient_field} };
                $r->{ingredient_field} = $r->{util_args}{ingredient_field};

                die "csv-mix-formulas: FATAL: Specified weight field does not exist\n"
                    unless defined $r->{input_fields_idx}{ $r->{util_args}{weight_field} };
                $r->{weight_field} = $r->{util_args}{weight_field};
            } else {
                die "csv-mix-formulas: FATAL: At least 2 fields are required\n" unless @{ $r->{input_fields} } >= 2;

                $r->{ingredient_field} = $r->{input_fields}[0];
                $r->{weight_field}     = $r->{input_fields}[1];
            }
        }

        # after we read the header row of each input file, we record the fields
        # as well as the filehandle, so we can resume reading the data rows
        # later. before printing all the rows, we collect all the fields from
        # all files first.

        push @{ $r->{all_input_fields} }, $r->{input_fields};
        push @{ $r->{all_input_fh} }, $r->{input_fh};
        $r->{wants_skip_file}++;
    },

    after_close_input_files => sub {
        my $r = shift;

        # collect all output fields
        $r->{output_fields} = [];
        $r->{output_fields_idx} = {};
        for my $i (0 .. $#{ $r->{all_input_fields} }) {
            my $input_fields = $r->{all_input_fields}[$i];
            for my $j (0 .. $#{ $input_fields }) {
                my $field = $input_fields->[$j];
                unless (grep {$field eq $_} @{ $r->{output_fields} }) {
                    push @{ $r->{output_fields} }, $field;
                    $r->{output_fields_idx}{$field} = $#{ $r->{output_fields} };
                }
            }
        }

        my $ingredients = {}; # key = ingredient name, { field=> ... }

        # get all ingredients
        my $csv = $r->{input_parser};
        for my $i (0 .. $#{ $r->{all_input_fh} }) {
            my $fh = $r->{all_input_fh}[$i];
            my $input_fields = $r->{all_input_fields}[$i];
            while (my $row = $csv->getline($fh)) {
                my $ingredient = $row->[ $r->{input_fields_idx}{ $r->{ingredient_field} } ];
                my $weight     = $row->[ $r->{input_fields_idx}{ $r->{weight_field} } ];
                $ingredients->{$ingredient} //= {};
                my $ingredient_row = $ingredients->{$ingredient};
                for my $j (0 .. $#{ $input_fields }) {
                    my $field = $input_fields->[$j];
                    if ($field eq $r->{weight_field}) {
                        $ingredient_row->{$field} //= [];
                        push @{ $ingredient_row->{$field} }, $row->[$j];
                    } else {
                        $ingredient_row->{$field} //= $row->[$j];
                    }
                }
            }
        }

        #use DD; dd $ingredients;

        my $num_formulas = @{ $r->{input_filenames} };
        return unless $num_formulas;

        # calculate the weights of the mixed formula
        for my $ingredient (keys %{ $ingredients }) {
            $ingredients->{$ingredient}{ $r->{weight_field} } = sum( @{ $ingredients->{$ingredient}{ $r->{weight_field} } } ) / $num_formulas;
        }

        for my $ingredient (sort { ($ingredients->{$b}{ $r->{weight_field} } <=> $ingredients->{$a}{ $r->{weight_field} }) ||
                                       (lc($a) cmp lc($b)) } keys %$ingredients) {

          FORMAT: for my $weight ($ingredients->{ $r->{weight_field} }) {
                if ($r->{util_args}{output_percent}) {
                    $weight = ($weight * 100) . "%";
                    last FORMAT;
                } elsif ($r->{util_args}{output_percent_nosign}) {
                    $weight = ($weight * 100);
                }
                if ($r->{util_args}{output_format}) {
                    $weight = sprintf($r->{util_args}{output_format}, $weight);
                }
            } # FORMAT

            $r->{code_print_row}->($ingredients->{$ingredient});
        }
    },
);

1;
# ABSTRACT: Mix several formulas/recipes (lists of ingredients and their weights/volumes) into one, and output the combined formula

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv_mix_formulas - Mix several formulas/recipes (lists of ingredients and their weights/volumes) into one, and output the combined formula

=head1 VERSION

This document describes version 0.002 of App::CSVUtils::csv_mix_formulas (from Perl distribution App-CSVUtils-csv_mix_formulas), released on 2024-02-24.

=head1 FUNCTIONS


=head2 csv_mix_formulas

Usage:

 csv_mix_formulas(%args) -> [$status_code, $reason, $payload, \%result_meta]

Mix several formulasE<sol>recipes (lists of ingredients and their weightsE<sol>volumes) into one, and output the combined formula.

Each formula is a CSV comprised of at least two fields. The first field (by
default literally the first field, but can also be specified using
C<--ingredient-field>) is assumed to contain the name of ingredients. The second
field (by default literally the second field, but can also be specified using
C<--weight-field>) is assumed to contain the weight of ingredients. A percent
form is recognized and will be converted to its decimal form (e.g. "60%" or
"60.0 %" will become 0.6).

Example, mixing this CSV:

 ingredient,%weight,extra-field1,extra-field2
 water,80,foo,bar
 sugar,15,foo,bar
 citric acid,0.3,foo,bar
 strawberry syrup,4.7,foo,bar

and this:

 ingredient,%weight,extra-field1,extra-field2,extra-field3
 lemon syrup,5.75,bar,baz,qux
 citric acid,0.25,bar,baz,qux
 sugar,14,bar,baz,qux
 water,80,bar,baz,qux

will result in the following CSV. Note: 1) for the header, except for the first
two fields which are the ingredient name and weight which will contain the mixed
formula, the other fields will simply collect values from all the CSV files. 2)
for sorting order: decreasing weight then by name.

 ingredient,%weight,extra-field1,extra-field2,extra-field3
 water,80,foo,bar,qux
 sugar,14.5,foor,bar,qux
 lemon syrup,2.875,bar,baz,qux
 strawberry syrup,2.35,foo,bar,
 citric acid,0.275,foo,bar,qux

Keywords: compositions, mixture, combine

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ingredient_field> => I<str>

Specify field which contain the ingredient names.

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

=item * B<output_format> => I<str>

A sprintf() template to format the weight.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_percent> => I<bool>

If enabled, will convert output weights to percent with the percent sign (e.g. 0.6 to "60%").

=item * B<output_percent_nosign> => I<bool>

If enabled, will convert output weights to percent without the percent sign (e.g. 0.6 to "60").

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

=item * B<weight_field> => I<str>

Specify field which contain the weights.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-CSVUtils-csv_mix_formulas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CSVUtils-csv_mix_formulas>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils-csv_mix_formulas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
