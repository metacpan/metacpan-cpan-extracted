package App::ChemistryUtils;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-12'; # DATE
our $DIST = 'App-ChemistryUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

my $res = gen_read_table_func(
    name => 'list_chemical_elements',
    summary => 'List chemical elements',
    table_data => do { require TableData::Chemistry::Element; TableData::Chemistry::Element->new },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: Utilities related to chemistry

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ChemistryUtils - Utilities related to chemistry

=head1 VERSION

This document describes version 0.001 of App::ChemistryUtils (from Perl distribution App-ChemistryUtils), released on 2023-02-12.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<list-chemical-elements>

=back

=head1 FUNCTIONS


=head2 list_chemical_elements

Usage:

 list_chemical_elements(%args) -> [$status_code, $reason, $payload, \%result_meta]

List chemical elements.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abundance_in_earth_crust> => I<str>

Only return records where the 'abundance_in_earth_crust' field equals specified value.

=item * B<abundance_in_earth_crust.contains> => I<str>

Only return records where the 'abundance_in_earth_crust' field contains specified text.

=item * B<abundance_in_earth_crust.in> => I<array[str]>

Only return records where the 'abundance_in_earth_crust' field is in the specified values.

=item * B<abundance_in_earth_crust.is> => I<str>

Only return records where the 'abundance_in_earth_crust' field equals specified value.

=item * B<abundance_in_earth_crust.isnt> => I<str>

Only return records where the 'abundance_in_earth_crust' field does not equal specified value.

=item * B<abundance_in_earth_crust.max> => I<str>

Only return records where the 'abundance_in_earth_crust' field is less than or equal to specified value.

=item * B<abundance_in_earth_crust.min> => I<str>

Only return records where the 'abundance_in_earth_crust' field is greater than or equal to specified value.

=item * B<abundance_in_earth_crust.not_contains> => I<str>

Only return records where the 'abundance_in_earth_crust' field does not contain specified text.

=item * B<abundance_in_earth_crust.not_in> => I<array[str]>

Only return records where the 'abundance_in_earth_crust' field is not in the specified values.

=item * B<abundance_in_earth_crust.xmax> => I<str>

Only return records where the 'abundance_in_earth_crust' field is less than specified value.

=item * B<abundance_in_earth_crust.xmin> => I<str>

Only return records where the 'abundance_in_earth_crust' field is greater than specified value.

=item * B<atomic_number> => I<int>

Only return records where the 'atomic_number' field equals specified value.

=item * B<atomic_number.in> => I<array[int]>

Only return records where the 'atomic_number' field is in the specified values.

=item * B<atomic_number.is> => I<int>

Only return records where the 'atomic_number' field equals specified value.

=item * B<atomic_number.isnt> => I<int>

Only return records where the 'atomic_number' field does not equal specified value.

=item * B<atomic_number.max> => I<int>

Only return records where the 'atomic_number' field is less than or equal to specified value.

=item * B<atomic_number.min> => I<int>

Only return records where the 'atomic_number' field is greater than or equal to specified value.

=item * B<atomic_number.not_in> => I<array[int]>

Only return records where the 'atomic_number' field is not in the specified values.

=item * B<atomic_number.xmax> => I<int>

Only return records where the 'atomic_number' field is less than specified value.

=item * B<atomic_number.xmin> => I<int>

Only return records where the 'atomic_number' field is greater than specified value.

=item * B<block> => I<str>

Only return records where the 'block' field equals specified value.

=item * B<block.contains> => I<str>

Only return records where the 'block' field contains specified text.

=item * B<block.in> => I<array[str]>

Only return records where the 'block' field is in the specified values.

=item * B<block.is> => I<str>

Only return records where the 'block' field equals specified value.

=item * B<block.isnt> => I<str>

Only return records where the 'block' field does not equal specified value.

=item * B<block.max> => I<str>

Only return records where the 'block' field is less than or equal to specified value.

=item * B<block.min> => I<str>

Only return records where the 'block' field is greater than or equal to specified value.

=item * B<block.not_contains> => I<str>

Only return records where the 'block' field does not contain specified text.

=item * B<block.not_in> => I<array[str]>

Only return records where the 'block' field is not in the specified values.

=item * B<block.xmax> => I<str>

Only return records where the 'block' field is less than specified value.

=item * B<block.xmin> => I<str>

Only return records where the 'block' field is greater than specified value.

=item * B<boiling_point> => I<float>

Only return records where the 'boiling_point' field equals specified value.

=item * B<boiling_point.in> => I<array[float]>

Only return records where the 'boiling_point' field is in the specified values.

=item * B<boiling_point.is> => I<float>

Only return records where the 'boiling_point' field equals specified value.

=item * B<boiling_point.isnt> => I<float>

Only return records where the 'boiling_point' field does not equal specified value.

=item * B<boiling_point.max> => I<float>

Only return records where the 'boiling_point' field is less than or equal to specified value.

=item * B<boiling_point.min> => I<float>

Only return records where the 'boiling_point' field is greater than or equal to specified value.

=item * B<boiling_point.not_in> => I<array[float]>

Only return records where the 'boiling_point' field is not in the specified values.

=item * B<boiling_point.xmax> => I<float>

Only return records where the 'boiling_point' field is less than specified value.

=item * B<boiling_point.xmin> => I<float>

Only return records where the 'boiling_point' field is greater than specified value.

=item * B<density> => I<float>

Only return records where the 'density' field equals specified value.

=item * B<density.in> => I<array[float]>

Only return records where the 'density' field is in the specified values.

=item * B<density.is> => I<float>

Only return records where the 'density' field equals specified value.

=item * B<density.isnt> => I<float>

Only return records where the 'density' field does not equal specified value.

=item * B<density.max> => I<float>

Only return records where the 'density' field is less than or equal to specified value.

=item * B<density.min> => I<float>

Only return records where the 'density' field is greater than or equal to specified value.

=item * B<density.not_in> => I<array[float]>

Only return records where the 'density' field is not in the specified values.

=item * B<density.xmax> => I<float>

Only return records where the 'density' field is less than specified value.

=item * B<density.xmin> => I<float>

Only return records where the 'density' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<electronegativity> => I<float>

Only return records where the 'electronegativity' field equals specified value.

=item * B<electronegativity.in> => I<array[float]>

Only return records where the 'electronegativity' field is in the specified values.

=item * B<electronegativity.is> => I<float>

Only return records where the 'electronegativity' field equals specified value.

=item * B<electronegativity.isnt> => I<float>

Only return records where the 'electronegativity' field does not equal specified value.

=item * B<electronegativity.max> => I<float>

Only return records where the 'electronegativity' field is less than or equal to specified value.

=item * B<electronegativity.min> => I<float>

Only return records where the 'electronegativity' field is greater than or equal to specified value.

=item * B<electronegativity.not_in> => I<array[float]>

Only return records where the 'electronegativity' field is not in the specified values.

=item * B<electronegativity.xmax> => I<float>

Only return records where the 'electronegativity' field is less than specified value.

=item * B<electronegativity.xmin> => I<float>

Only return records where the 'electronegativity' field is greater than specified value.

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

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<group> => I<str>

Only return records where the 'group' field equals specified value.

=item * B<group.contains> => I<str>

Only return records where the 'group' field contains specified text.

=item * B<group.in> => I<array[str]>

Only return records where the 'group' field is in the specified values.

=item * B<group.is> => I<str>

Only return records where the 'group' field equals specified value.

=item * B<group.isnt> => I<str>

Only return records where the 'group' field does not equal specified value.

=item * B<group.max> => I<str>

Only return records where the 'group' field is less than or equal to specified value.

=item * B<group.min> => I<str>

Only return records where the 'group' field is greater than or equal to specified value.

=item * B<group.not_contains> => I<str>

Only return records where the 'group' field does not contain specified text.

=item * B<group.not_in> => I<array[str]>

Only return records where the 'group' field is not in the specified values.

=item * B<group.xmax> => I<str>

Only return records where the 'group' field is less than specified value.

=item * B<group.xmin> => I<str>

Only return records where the 'group' field is greater than specified value.

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

=item * B<melting_point> => I<float>

Only return records where the 'melting_point' field equals specified value.

=item * B<melting_point.in> => I<array[float]>

Only return records where the 'melting_point' field is in the specified values.

=item * B<melting_point.is> => I<float>

Only return records where the 'melting_point' field equals specified value.

=item * B<melting_point.isnt> => I<float>

Only return records where the 'melting_point' field does not equal specified value.

=item * B<melting_point.max> => I<float>

Only return records where the 'melting_point' field is less than or equal to specified value.

=item * B<melting_point.min> => I<float>

Only return records where the 'melting_point' field is greater than or equal to specified value.

=item * B<melting_point.not_in> => I<array[float]>

Only return records where the 'melting_point' field is not in the specified values.

=item * B<melting_point.xmax> => I<float>

Only return records where the 'melting_point' field is less than specified value.

=item * B<melting_point.xmin> => I<float>

Only return records where the 'melting_point' field is greater than specified value.

=item * B<name_origin> => I<str>

Only return records where the 'name_origin' field equals specified value.

=item * B<name_origin.contains> => I<str>

Only return records where the 'name_origin' field contains specified text.

=item * B<name_origin.in> => I<array[str]>

Only return records where the 'name_origin' field is in the specified values.

=item * B<name_origin.is> => I<str>

Only return records where the 'name_origin' field equals specified value.

=item * B<name_origin.isnt> => I<str>

Only return records where the 'name_origin' field does not equal specified value.

=item * B<name_origin.max> => I<str>

Only return records where the 'name_origin' field is less than or equal to specified value.

=item * B<name_origin.min> => I<str>

Only return records where the 'name_origin' field is greater than or equal to specified value.

=item * B<name_origin.not_contains> => I<str>

Only return records where the 'name_origin' field does not contain specified text.

=item * B<name_origin.not_in> => I<array[str]>

Only return records where the 'name_origin' field is not in the specified values.

=item * B<name_origin.xmax> => I<str>

Only return records where the 'name_origin' field is less than specified value.

=item * B<name_origin.xmin> => I<str>

Only return records where the 'name_origin' field is greater than specified value.

=item * B<origin> => I<str>

Only return records where the 'origin' field equals specified value.

=item * B<origin.contains> => I<str>

Only return records where the 'origin' field contains specified text.

=item * B<origin.in> => I<array[str]>

Only return records where the 'origin' field is in the specified values.

=item * B<origin.is> => I<str>

Only return records where the 'origin' field equals specified value.

=item * B<origin.isnt> => I<str>

Only return records where the 'origin' field does not equal specified value.

=item * B<origin.max> => I<str>

Only return records where the 'origin' field is less than or equal to specified value.

=item * B<origin.min> => I<str>

Only return records where the 'origin' field is greater than or equal to specified value.

=item * B<origin.not_contains> => I<str>

Only return records where the 'origin' field does not contain specified text.

=item * B<origin.not_in> => I<array[str]>

Only return records where the 'origin' field is not in the specified values.

=item * B<origin.xmax> => I<str>

Only return records where the 'origin' field is less than specified value.

=item * B<origin.xmin> => I<str>

Only return records where the 'origin' field is greater than specified value.

=item * B<period> => I<str>

Only return records where the 'period' field equals specified value.

=item * B<period.contains> => I<str>

Only return records where the 'period' field contains specified text.

=item * B<period.in> => I<array[str]>

Only return records where the 'period' field is in the specified values.

=item * B<period.is> => I<str>

Only return records where the 'period' field equals specified value.

=item * B<period.isnt> => I<str>

Only return records where the 'period' field does not equal specified value.

=item * B<period.max> => I<str>

Only return records where the 'period' field is less than or equal to specified value.

=item * B<period.min> => I<str>

Only return records where the 'period' field is greater than or equal to specified value.

=item * B<period.not_contains> => I<str>

Only return records where the 'period' field does not contain specified text.

=item * B<period.not_in> => I<array[str]>

Only return records where the 'period' field is not in the specified values.

=item * B<period.xmax> => I<str>

Only return records where the 'period' field is less than specified value.

=item * B<period.xmin> => I<str>

Only return records where the 'period' field is greater than specified value.

=item * B<phase_at_rt> => I<str>

Only return records where the 'phase_at_rt' field equals specified value.

=item * B<phase_at_rt.contains> => I<str>

Only return records where the 'phase_at_rt' field contains specified text.

=item * B<phase_at_rt.in> => I<array[str]>

Only return records where the 'phase_at_rt' field is in the specified values.

=item * B<phase_at_rt.is> => I<str>

Only return records where the 'phase_at_rt' field equals specified value.

=item * B<phase_at_rt.isnt> => I<str>

Only return records where the 'phase_at_rt' field does not equal specified value.

=item * B<phase_at_rt.max> => I<str>

Only return records where the 'phase_at_rt' field is less than or equal to specified value.

=item * B<phase_at_rt.min> => I<str>

Only return records where the 'phase_at_rt' field is greater than or equal to specified value.

=item * B<phase_at_rt.not_contains> => I<str>

Only return records where the 'phase_at_rt' field does not contain specified text.

=item * B<phase_at_rt.not_in> => I<array[str]>

Only return records where the 'phase_at_rt' field is not in the specified values.

=item * B<phase_at_rt.xmax> => I<str>

Only return records where the 'phase_at_rt' field is less than specified value.

=item * B<phase_at_rt.xmin> => I<str>

Only return records where the 'phase_at_rt' field is greater than specified value.

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

=item * B<specific_heat_capacity> => I<float>

Only return records where the 'specific_heat_capacity' field equals specified value.

=item * B<specific_heat_capacity.in> => I<array[float]>

Only return records where the 'specific_heat_capacity' field is in the specified values.

=item * B<specific_heat_capacity.is> => I<float>

Only return records where the 'specific_heat_capacity' field equals specified value.

=item * B<specific_heat_capacity.isnt> => I<float>

Only return records where the 'specific_heat_capacity' field does not equal specified value.

=item * B<specific_heat_capacity.max> => I<float>

Only return records where the 'specific_heat_capacity' field is less than or equal to specified value.

=item * B<specific_heat_capacity.min> => I<float>

Only return records where the 'specific_heat_capacity' field is greater than or equal to specified value.

=item * B<specific_heat_capacity.not_in> => I<array[float]>

Only return records where the 'specific_heat_capacity' field is not in the specified values.

=item * B<specific_heat_capacity.xmax> => I<float>

Only return records where the 'specific_heat_capacity' field is less than specified value.

=item * B<specific_heat_capacity.xmin> => I<float>

Only return records where the 'specific_heat_capacity' field is greater than specified value.

=item * B<standard_atomic_weight> => I<float>

Only return records where the 'standard_atomic_weight' field equals specified value.

=item * B<standard_atomic_weight.in> => I<array[float]>

Only return records where the 'standard_atomic_weight' field is in the specified values.

=item * B<standard_atomic_weight.is> => I<float>

Only return records where the 'standard_atomic_weight' field equals specified value.

=item * B<standard_atomic_weight.isnt> => I<float>

Only return records where the 'standard_atomic_weight' field does not equal specified value.

=item * B<standard_atomic_weight.max> => I<float>

Only return records where the 'standard_atomic_weight' field is less than or equal to specified value.

=item * B<standard_atomic_weight.min> => I<float>

Only return records where the 'standard_atomic_weight' field is greater than or equal to specified value.

=item * B<standard_atomic_weight.not_in> => I<array[float]>

Only return records where the 'standard_atomic_weight' field is not in the specified values.

=item * B<standard_atomic_weight.xmax> => I<float>

Only return records where the 'standard_atomic_weight' field is less than specified value.

=item * B<standard_atomic_weight.xmin> => I<float>

Only return records where the 'standard_atomic_weight' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ChemistryUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ChemistryUtils>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ChemistryUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
