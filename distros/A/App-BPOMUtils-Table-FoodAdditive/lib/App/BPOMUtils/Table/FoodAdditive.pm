package App::BPOMUtils::Table::FoodAdditive;

use 5.010001;
use strict 'subs', 'vars';
use utf8;
use warnings;
use Log::ger;

use Exporter 'import';
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use TableData::Business::ID::BPOM::FoodAdditive;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-04-19'; # DATE
our $DIST = 'App-BPOMUtils-Table-FoodAdditive'; # DIST
our $VERSION = '0.019'; # VERSION

our @EXPORT_OK = qw(
                       bpom_list_food_additives
               );

our %SPEC;

my $res = gen_read_table_func(
    name => 'bpom_list_food_additives',
    summary => 'List registered food additives in BPOM',
    table_data => TableData::Business::ID::BPOM::FoodAdditive->new,
    description => <<'MARKDOWN',
MARKDOWN
    extra_props => {
        examples => [
            {
                summary => 'Check for additives that contain "dextrin" but do not contain "gamma"',
                src_plang => 'bash',
                src => '[[prog]] -l --format text-pretty -- dextrin -gamma',
                test => 0,
            },
            {
                summary => 'Check for additives that contain "magnesium" or "titanium"',
                src_plang => 'bash',
                src => '[[prog]] -l --format text-pretty --or -- magnesium titanium',
                test => 0,
            },
            {
                summary => 'Check for additives that match some regular expressions',
                src_plang => 'bash',
                src => q{[[prog]] -l --format text-pretty -- /potassium/ '/citrate|phosphate/'},
                test => 0,
            },
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: List registered food additives in BPOM

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::Table::FoodAdditive - List registered food additives in BPOM

=head1 VERSION

This document describes version 0.019 of App::BPOMUtils::Table::FoodAdditive (from Perl distribution App-BPOMUtils-Table-FoodAdditive), released on 2024-04-19.

=head1 DESCRIPTION

This distribution contains the following CLIs:

=over

=item * L<bpom-daftar-bahan-tambahan-pangan>

=item * L<bpom-list-food-additives>

=item * L<bpomfa>

=back

=head1 FUNCTIONS


=head2 bpom_list_food_additives

Usage:

 bpom_list_food_additives(%args) -> [$status_code, $reason, $payload, \%result_meta]

List registered food additives in BPOM.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<additive_group> => I<str>

Only return records where the 'additive_group' field equals specified value.

=item * B<additive_group.contains> => I<str>

Only return records where the 'additive_group' field contains specified text.

=item * B<additive_group.in> => I<array[str]>

Only return records where the 'additive_group' field is in the specified values.

=item * B<additive_group.is> => I<str>

Only return records where the 'additive_group' field equals specified value.

=item * B<additive_group.isnt> => I<str>

Only return records where the 'additive_group' field does not equal specified value.

=item * B<additive_group.max> => I<str>

Only return records where the 'additive_group' field is less than or equal to specified value.

=item * B<additive_group.min> => I<str>

Only return records where the 'additive_group' field is greater than or equal to specified value.

=item * B<additive_group.not_contains> => I<str>

Only return records where the 'additive_group' field does not contain specified text.

=item * B<additive_group.not_in> => I<array[str]>

Only return records where the 'additive_group' field is not in the specified values.

=item * B<additive_group.xmax> => I<str>

Only return records where the 'additive_group' field is less than specified value.

=item * B<additive_group.xmin> => I<str>

Only return records where the 'additive_group' field is greater than specified value.

=item * B<additive_name> => I<str>

Only return records where the 'additive_name' field equals specified value.

=item * B<additive_name.contains> => I<str>

Only return records where the 'additive_name' field contains specified text.

=item * B<additive_name.in> => I<array[str]>

Only return records where the 'additive_name' field is in the specified values.

=item * B<additive_name.is> => I<str>

Only return records where the 'additive_name' field equals specified value.

=item * B<additive_name.isnt> => I<str>

Only return records where the 'additive_name' field does not equal specified value.

=item * B<additive_name.max> => I<str>

Only return records where the 'additive_name' field is less than or equal to specified value.

=item * B<additive_name.min> => I<str>

Only return records where the 'additive_name' field is greater than or equal to specified value.

=item * B<additive_name.not_contains> => I<str>

Only return records where the 'additive_name' field does not contain specified text.

=item * B<additive_name.not_in> => I<array[str]>

Only return records where the 'additive_name' field is not in the specified values.

=item * B<additive_name.xmax> => I<str>

Only return records where the 'additive_name' field is less than specified value.

=item * B<additive_name.xmin> => I<str>

Only return records where the 'additive_name' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<food_category_name> => I<str>

Only return records where the 'food_category_name' field equals specified value.

=item * B<food_category_name.contains> => I<str>

Only return records where the 'food_category_name' field contains specified text.

=item * B<food_category_name.in> => I<array[str]>

Only return records where the 'food_category_name' field is in the specified values.

=item * B<food_category_name.is> => I<str>

Only return records where the 'food_category_name' field equals specified value.

=item * B<food_category_name.isnt> => I<str>

Only return records where the 'food_category_name' field does not equal specified value.

=item * B<food_category_name.max> => I<str>

Only return records where the 'food_category_name' field is less than or equal to specified value.

=item * B<food_category_name.min> => I<str>

Only return records where the 'food_category_name' field is greater than or equal to specified value.

=item * B<food_category_name.not_contains> => I<str>

Only return records where the 'food_category_name' field does not contain specified text.

=item * B<food_category_name.not_in> => I<array[str]>

Only return records where the 'food_category_name' field is not in the specified values.

=item * B<food_category_name.xmax> => I<str>

Only return records where the 'food_category_name' field is less than specified value.

=item * B<food_category_name.xmin> => I<str>

Only return records where the 'food_category_name' field is greater than specified value.

=item * B<food_category_number> => I<str>

Only return records where the 'food_category_number' field equals specified value.

=item * B<food_category_number.contains> => I<str>

Only return records where the 'food_category_number' field contains specified text.

=item * B<food_category_number.in> => I<array[str]>

Only return records where the 'food_category_number' field is in the specified values.

=item * B<food_category_number.is> => I<str>

Only return records where the 'food_category_number' field equals specified value.

=item * B<food_category_number.isnt> => I<str>

Only return records where the 'food_category_number' field does not equal specified value.

=item * B<food_category_number.max> => I<str>

Only return records where the 'food_category_number' field is less than or equal to specified value.

=item * B<food_category_number.min> => I<str>

Only return records where the 'food_category_number' field is greater than or equal to specified value.

=item * B<food_category_number.not_contains> => I<str>

Only return records where the 'food_category_number' field does not contain specified text.

=item * B<food_category_number.not_in> => I<array[str]>

Only return records where the 'food_category_number' field is not in the specified values.

=item * B<food_category_number.xmax> => I<str>

Only return records where the 'food_category_number' field is less than specified value.

=item * B<food_category_number.xmin> => I<str>

Only return records where the 'food_category_number' field is greater than specified value.

=item * B<id> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.contains> => I<str>

Only return records where the 'id' field contains specified text.

=item * B<id.in> => I<array[str]>

Only return records where the 'id' field is in the specified values.

=item * B<id.is> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.isnt> => I<str>

Only return records where the 'id' field does not equal specified value.

=item * B<id.max> => I<str>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<str>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_contains> => I<str>

Only return records where the 'id' field does not contain specified text.

=item * B<id.not_in> => I<array[str]>

Only return records where the 'id' field is not in the specified values.

=item * B<id.xmax> => I<str>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<str>

Only return records where the 'id' field is greater than specified value.

=item * B<information> => I<str>

Only return records where the 'information' field equals specified value.

=item * B<information.contains> => I<str>

Only return records where the 'information' field contains specified text.

=item * B<information.in> => I<array[str]>

Only return records where the 'information' field is in the specified values.

=item * B<information.is> => I<str>

Only return records where the 'information' field equals specified value.

=item * B<information.isnt> => I<str>

Only return records where the 'information' field does not equal specified value.

=item * B<information.max> => I<str>

Only return records where the 'information' field is less than or equal to specified value.

=item * B<information.min> => I<str>

Only return records where the 'information' field is greater than or equal to specified value.

=item * B<information.not_contains> => I<str>

Only return records where the 'information' field does not contain specified text.

=item * B<information.not_in> => I<array[str]>

Only return records where the 'information' field is not in the specified values.

=item * B<information.xmax> => I<str>

Only return records where the 'information' field is less than specified value.

=item * B<information.xmin> => I<str>

Only return records where the 'information' field is greater than specified value.

=item * B<ins_number> => I<str>

Only return records where the 'ins_number' field equals specified value.

=item * B<ins_number.contains> => I<str>

Only return records where the 'ins_number' field contains specified text.

=item * B<ins_number.in> => I<array[str]>

Only return records where the 'ins_number' field is in the specified values.

=item * B<ins_number.is> => I<str>

Only return records where the 'ins_number' field equals specified value.

=item * B<ins_number.isnt> => I<str>

Only return records where the 'ins_number' field does not equal specified value.

=item * B<ins_number.max> => I<str>

Only return records where the 'ins_number' field is less than or equal to specified value.

=item * B<ins_number.min> => I<str>

Only return records where the 'ins_number' field is greater than or equal to specified value.

=item * B<ins_number.not_contains> => I<str>

Only return records where the 'ins_number' field does not contain specified text.

=item * B<ins_number.not_in> => I<array[str]>

Only return records where the 'ins_number' field is not in the specified values.

=item * B<ins_number.xmax> => I<str>

Only return records where the 'ins_number' field is less than specified value.

=item * B<ins_number.xmin> => I<str>

Only return records where the 'ins_number' field is greater than specified value.

=item * B<limit> => I<str>

Only return records where the 'limit' field equals specified value.

=item * B<limit.contains> => I<str>

Only return records where the 'limit' field contains specified text.

=item * B<limit.in> => I<array[str]>

Only return records where the 'limit' field is in the specified values.

=item * B<limit.is> => I<str>

Only return records where the 'limit' field equals specified value.

=item * B<limit.isnt> => I<str>

Only return records where the 'limit' field does not equal specified value.

=item * B<limit.max> => I<str>

Only return records where the 'limit' field is less than or equal to specified value.

=item * B<limit.min> => I<str>

Only return records where the 'limit' field is greater than or equal to specified value.

=item * B<limit.not_contains> => I<str>

Only return records where the 'limit' field does not contain specified text.

=item * B<limit.not_in> => I<array[str]>

Only return records where the 'limit' field is not in the specified values.

=item * B<limit.xmax> => I<str>

Only return records where the 'limit' field is less than specified value.

=item * B<limit.xmin> => I<str>

Only return records where the 'limit' field is greater than specified value.

=item * B<limit_unit> => I<str>

Only return records where the 'limit_unit' field equals specified value.

=item * B<limit_unit.contains> => I<str>

Only return records where the 'limit_unit' field contains specified text.

=item * B<limit_unit.in> => I<array[str]>

Only return records where the 'limit_unit' field is in the specified values.

=item * B<limit_unit.is> => I<str>

Only return records where the 'limit_unit' field equals specified value.

=item * B<limit_unit.isnt> => I<str>

Only return records where the 'limit_unit' field does not equal specified value.

=item * B<limit_unit.max> => I<str>

Only return records where the 'limit_unit' field is less than or equal to specified value.

=item * B<limit_unit.min> => I<str>

Only return records where the 'limit_unit' field is greater than or equal to specified value.

=item * B<limit_unit.not_contains> => I<str>

Only return records where the 'limit_unit' field does not contain specified text.

=item * B<limit_unit.not_in> => I<array[str]>

Only return records where the 'limit_unit' field is not in the specified values.

=item * B<limit_unit.xmax> => I<str>

Only return records where the 'limit_unit' field is less than specified value.

=item * B<limit_unit.xmin> => I<str>

Only return records where the 'limit_unit' field is greater than specified value.

=item * B<note> => I<str>

Only return records where the 'note' field equals specified value.

=item * B<note.contains> => I<str>

Only return records where the 'note' field contains specified text.

=item * B<note.in> => I<array[str]>

Only return records where the 'note' field is in the specified values.

=item * B<note.is> => I<str>

Only return records where the 'note' field equals specified value.

=item * B<note.isnt> => I<str>

Only return records where the 'note' field does not equal specified value.

=item * B<note.max> => I<str>

Only return records where the 'note' field is less than or equal to specified value.

=item * B<note.min> => I<str>

Only return records where the 'note' field is greater than or equal to specified value.

=item * B<note.not_contains> => I<str>

Only return records where the 'note' field does not contain specified text.

=item * B<note.not_in> => I<array[str]>

Only return records where the 'note' field is not in the specified values.

=item * B<note.xmax> => I<str>

Only return records where the 'note' field is less than specified value.

=item * B<note.xmin> => I<str>

Only return records where the 'note' field is greater than specified value.

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

=item * B<status> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.contains> => I<str>

Only return records where the 'status' field contains specified text.

=item * B<status.in> => I<array[str]>

Only return records where the 'status' field is in the specified values.

=item * B<status.is> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.isnt> => I<str>

Only return records where the 'status' field does not equal specified value.

=item * B<status.max> => I<str>

Only return records where the 'status' field is less than or equal to specified value.

=item * B<status.min> => I<str>

Only return records where the 'status' field is greater than or equal to specified value.

=item * B<status.not_contains> => I<str>

Only return records where the 'status' field does not contain specified text.

=item * B<status.not_in> => I<array[str]>

Only return records where the 'status' field is not in the specified values.

=item * B<status.xmax> => I<str>

Only return records where the 'status' field is less than specified value.

=item * B<status.xmin> => I<str>

Only return records where the 'status' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-Table-FoodAdditive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-Table-FoodAdditive>.

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-Table-FoodAdditive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
