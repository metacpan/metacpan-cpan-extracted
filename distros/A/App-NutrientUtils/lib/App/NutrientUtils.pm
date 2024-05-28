package App::NutrientUtils;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use TableData::Health::Nutrient;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-14'; # DATE
our $DIST = 'App-NutrientUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       list_nutrients
               );

our %SPEC;

my $res = gen_read_table_func(
    name => 'list_nutrients',
    summary => 'List nutrients',
    table_data => TableData::Health::Nutrient->new,
    description => <<'MARKDOWN',
MARKDOWN
    extra_props => {
        examples => [
            {
                summary => 'List all vitamins, with all details',
                src_plang => 'bash',
                src => '[[prog]] -l --category vitamin',
                test => 0,
            },
            {
                summary => 'List the English names of all minerals',
                src_plang => 'bash',
                src => q([[prog]] --category mineral --fields '["eng_name"]'),
                test => 0,
            },
        ],
    },
);

1;
# ABSTRACT: Utilities related to nutrients

__END__

=pod

=encoding UTF-8

=head1 NAME

App::NutrientUtils - Utilities related to nutrients

=head1 VERSION

This document describes version 0.001 of App::NutrientUtils (from Perl distribution App-NutrientUtils), released on 2024-05-14.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<list-nutrients>

=back

=head1 FUNCTIONS


=head2 list_nutrients

Usage:

 list_nutrients(%args) -> [$status_code, $reason, $payload, \%result_meta]

List nutrients.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str>

Only return records where the 'category' field equals specified value.

=item * B<category.contains> => I<str>

Only return records where the 'category' field contains specified text.

=item * B<category.in> => I<array[str]>

Only return records where the 'category' field is in the specified values.

=item * B<category.is> => I<str>

Only return records where the 'category' field equals specified value.

=item * B<category.isnt> => I<str>

Only return records where the 'category' field does not equal specified value.

=item * B<category.max> => I<str>

Only return records where the 'category' field is less than or equal to specified value.

=item * B<category.min> => I<str>

Only return records where the 'category' field is greater than or equal to specified value.

=item * B<category.not_contains> => I<str>

Only return records where the 'category' field does not contain specified text.

=item * B<category.not_in> => I<array[str]>

Only return records where the 'category' field is not in the specified values.

=item * B<category.xmax> => I<str>

Only return records where the 'category' field is less than specified value.

=item * B<category.xmin> => I<str>

Only return records where the 'category' field is greater than specified value.

=item * B<default_unit> => I<str>

Only return records where the 'default_unit' field equals specified value.

=item * B<default_unit.contains> => I<str>

Only return records where the 'default_unit' field contains specified text.

=item * B<default_unit.in> => I<array[str]>

Only return records where the 'default_unit' field is in the specified values.

=item * B<default_unit.is> => I<str>

Only return records where the 'default_unit' field equals specified value.

=item * B<default_unit.isnt> => I<str>

Only return records where the 'default_unit' field does not equal specified value.

=item * B<default_unit.max> => I<str>

Only return records where the 'default_unit' field is less than or equal to specified value.

=item * B<default_unit.min> => I<str>

Only return records where the 'default_unit' field is greater than or equal to specified value.

=item * B<default_unit.not_contains> => I<str>

Only return records where the 'default_unit' field does not contain specified text.

=item * B<default_unit.not_in> => I<array[str]>

Only return records where the 'default_unit' field is not in the specified values.

=item * B<default_unit.xmax> => I<str>

Only return records where the 'default_unit' field is less than specified value.

=item * B<default_unit.xmin> => I<str>

Only return records where the 'default_unit' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<eng_aliases> => I<array>

Only return records where the 'eng_aliases' field equals specified value.

=item * B<eng_aliases.has> => I<array[str]>

Only return records where the 'eng_aliases' field is an arrayE<sol>list which contains specified value.

=item * B<eng_aliases.is> => I<array>

Only return records where the 'eng_aliases' field equals specified value.

=item * B<eng_aliases.isnt> => I<array>

Only return records where the 'eng_aliases' field does not equal specified value.

=item * B<eng_aliases.lacks> => I<array[str]>

Only return records where the 'eng_aliases' field is an arrayE<sol>list which does not contain specified value.

=item * B<eng_name> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.contains> => I<str>

Only return records where the 'eng_name' field contains specified text.

=item * B<eng_name.in> => I<array[str]>

Only return records where the 'eng_name' field is in the specified values.

=item * B<eng_name.is> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.isnt> => I<str>

Only return records where the 'eng_name' field does not equal specified value.

=item * B<eng_name.max> => I<str>

Only return records where the 'eng_name' field is less than or equal to specified value.

=item * B<eng_name.min> => I<str>

Only return records where the 'eng_name' field is greater than or equal to specified value.

=item * B<eng_name.not_contains> => I<str>

Only return records where the 'eng_name' field does not contain specified text.

=item * B<eng_name.not_in> => I<array[str]>

Only return records where the 'eng_name' field is not in the specified values.

=item * B<eng_name.xmax> => I<str>

Only return records where the 'eng_name' field is less than specified value.

=item * B<eng_name.xmin> => I<str>

Only return records where the 'eng_name' field is greater than specified value.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fat_soluble> => I<bool>

Only return records where the 'fat_soluble' field equals specified value.

=item * B<fat_soluble.is> => I<bool>

Only return records where the 'fat_soluble' field equals specified value.

=item * B<fat_soluble.isnt> => I<bool>

Only return records where the 'fat_soluble' field does not equal specified value.

=item * B<fat_soluble_note> => I<str>

Only return records where the 'fat_soluble_note' field equals specified value.

=item * B<fat_soluble_note.contains> => I<str>

Only return records where the 'fat_soluble_note' field contains specified text.

=item * B<fat_soluble_note.in> => I<array[str]>

Only return records where the 'fat_soluble_note' field is in the specified values.

=item * B<fat_soluble_note.is> => I<str>

Only return records where the 'fat_soluble_note' field equals specified value.

=item * B<fat_soluble_note.isnt> => I<str>

Only return records where the 'fat_soluble_note' field does not equal specified value.

=item * B<fat_soluble_note.max> => I<str>

Only return records where the 'fat_soluble_note' field is less than or equal to specified value.

=item * B<fat_soluble_note.min> => I<str>

Only return records where the 'fat_soluble_note' field is greater than or equal to specified value.

=item * B<fat_soluble_note.not_contains> => I<str>

Only return records where the 'fat_soluble_note' field does not contain specified text.

=item * B<fat_soluble_note.not_in> => I<array[str]>

Only return records where the 'fat_soluble_note' field is not in the specified values.

=item * B<fat_soluble_note.xmax> => I<str>

Only return records where the 'fat_soluble_note' field is less than specified value.

=item * B<fat_soluble_note.xmin> => I<str>

Only return records where the 'fat_soluble_note' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<ind_aliases> => I<array>

Only return records where the 'ind_aliases' field equals specified value.

=item * B<ind_aliases.has> => I<array[str]>

Only return records where the 'ind_aliases' field is an arrayE<sol>list which contains specified value.

=item * B<ind_aliases.is> => I<array>

Only return records where the 'ind_aliases' field equals specified value.

=item * B<ind_aliases.isnt> => I<array>

Only return records where the 'ind_aliases' field does not equal specified value.

=item * B<ind_aliases.lacks> => I<array[str]>

Only return records where the 'ind_aliases' field is an arrayE<sol>list which does not contain specified value.

=item * B<ind_name> => I<str>

Only return records where the 'ind_name' field equals specified value.

=item * B<ind_name.contains> => I<str>

Only return records where the 'ind_name' field contains specified text.

=item * B<ind_name.in> => I<array[str]>

Only return records where the 'ind_name' field is in the specified values.

=item * B<ind_name.is> => I<str>

Only return records where the 'ind_name' field equals specified value.

=item * B<ind_name.isnt> => I<str>

Only return records where the 'ind_name' field does not equal specified value.

=item * B<ind_name.max> => I<str>

Only return records where the 'ind_name' field is less than or equal to specified value.

=item * B<ind_name.min> => I<str>

Only return records where the 'ind_name' field is greater than or equal to specified value.

=item * B<ind_name.not_contains> => I<str>

Only return records where the 'ind_name' field does not contain specified text.

=item * B<ind_name.not_in> => I<array[str]>

Only return records where the 'ind_name' field is not in the specified values.

=item * B<ind_name.xmax> => I<str>

Only return records where the 'ind_name' field is less than specified value.

=item * B<ind_name.xmin> => I<str>

Only return records where the 'ind_name' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<summary> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.contains> => I<str>

Only return records where the 'summary' field contains specified text.

=item * B<summary.in> => I<array[str]>

Only return records where the 'summary' field is in the specified values.

=item * B<summary.is> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.isnt> => I<str>

Only return records where the 'summary' field does not equal specified value.

=item * B<summary.max> => I<str>

Only return records where the 'summary' field is less than or equal to specified value.

=item * B<summary.min> => I<str>

Only return records where the 'summary' field is greater than or equal to specified value.

=item * B<summary.not_contains> => I<str>

Only return records where the 'summary' field does not contain specified text.

=item * B<summary.not_in> => I<array[str]>

Only return records where the 'summary' field is not in the specified values.

=item * B<summary.xmax> => I<str>

Only return records where the 'summary' field is less than specified value.

=item * B<summary.xmin> => I<str>

Only return records where the 'summary' field is greater than specified value.

=item * B<symbol> => I<str>

Only return records where the 'symbol' field equals specified value.

=item * B<symbol.contains> => I<str>

Only return records where the 'symbol' field contains specified text.

=item * B<symbol.in> => I<array[str]>

Only return records where the 'symbol' field is in the specified values.

=item * B<symbol.is> => I<str>

Only return records where the 'symbol' field equals specified value.

=item * B<symbol.isnt> => I<str>

Only return records where the 'symbol' field does not equal specified value.

=item * B<symbol.max> => I<str>

Only return records where the 'symbol' field is less than or equal to specified value.

=item * B<symbol.min> => I<str>

Only return records where the 'symbol' field is greater than or equal to specified value.

=item * B<symbol.not_contains> => I<str>

Only return records where the 'symbol' field does not contain specified text.

=item * B<symbol.not_in> => I<array[str]>

Only return records where the 'symbol' field is not in the specified values.

=item * B<symbol.xmax> => I<str>

Only return records where the 'symbol' field is less than specified value.

=item * B<symbol.xmin> => I<str>

Only return records where the 'symbol' field is greater than specified value.

=item * B<water_soluble> => I<bool>

Only return records where the 'water_soluble' field equals specified value.

=item * B<water_soluble.is> => I<bool>

Only return records where the 'water_soluble' field equals specified value.

=item * B<water_soluble.isnt> => I<bool>

Only return records where the 'water_soluble' field does not equal specified value.

=item * B<water_soluble_note> => I<str>

Only return records where the 'water_soluble_note' field equals specified value.

=item * B<water_soluble_note.contains> => I<str>

Only return records where the 'water_soluble_note' field contains specified text.

=item * B<water_soluble_note.in> => I<array[str]>

Only return records where the 'water_soluble_note' field is in the specified values.

=item * B<water_soluble_note.is> => I<str>

Only return records where the 'water_soluble_note' field equals specified value.

=item * B<water_soluble_note.isnt> => I<str>

Only return records where the 'water_soluble_note' field does not equal specified value.

=item * B<water_soluble_note.max> => I<str>

Only return records where the 'water_soluble_note' field is less than or equal to specified value.

=item * B<water_soluble_note.min> => I<str>

Only return records where the 'water_soluble_note' field is greater than or equal to specified value.

=item * B<water_soluble_note.not_contains> => I<str>

Only return records where the 'water_soluble_note' field does not contain specified text.

=item * B<water_soluble_note.not_in> => I<array[str]>

Only return records where the 'water_soluble_note' field is not in the specified values.

=item * B<water_soluble_note.xmax> => I<str>

Only return records where the 'water_soluble_note' field is less than specified value.

=item * B<water_soluble_note.xmin> => I<str>

Only return records where the 'water_soluble_note' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


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

Please visit the project's homepage at L<https://metacpan.org/release/App-NutrientUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-NutrientUtils>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-NutrientUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
