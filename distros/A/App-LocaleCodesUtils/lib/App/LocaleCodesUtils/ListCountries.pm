package App::LocaleCodesUtils::ListCountries;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'App-LocaleCodesUtils'; # DIST
our $VERSION = '0.004'; # VERSION

my $res;

$res = gen_read_table_func(
    name => 'list_countries',
    summary => 'List countries',
    table_data => sub {
        require Locale::Country;
        my @alpha2s = Locale::Country::all_country_codes('alpha-2');
        my @data;
        for my $alpha2 (@alpha2s) {
            my $country = Locale::Country::code2country($alpha2, 'alpha-2');
            my $alpha3  = Locale::Country::country2code($country, 'alpha-3');
            push @data, [$alpha2, $country, $alpha3];
        }
        return { data=>\@data };
    },
    table_spec => {
        summary => 'List of countries',
        fields => {
            alpha2 => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            name => {
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
            alpha3 => {
                schema => 'str*',
                pos => 2,
                sortable => 1,
            },
        },
        pk => 'alpha2',
    },
);
die "Can't generate list_countries(): $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: Backend module for list-countries

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LocaleCodesUtils::ListCountries - Backend module for list-countries

=head1 VERSION

This document describes version 0.004 of App::LocaleCodesUtils::ListCountries (from Perl distribution App-LocaleCodesUtils), released on 2023-08-06.

=for Pod::Coverage ^(.+)$

=head1 FUNCTIONS


=head2 list_countries

Usage:

 list_countries(%args) -> [$status_code, $reason, $payload, \%result_meta]

List countries.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alpha2> => I<str>

Only return records where the 'alpha2' field equals specified value.

=item * B<alpha2.contains> => I<str>

Only return records where the 'alpha2' field contains specified text.

=item * B<alpha2.in> => I<array[str]>

Only return records where the 'alpha2' field is in the specified values.

=item * B<alpha2.is> => I<str>

Only return records where the 'alpha2' field equals specified value.

=item * B<alpha2.isnt> => I<str>

Only return records where the 'alpha2' field does not equal specified value.

=item * B<alpha2.max> => I<str>

Only return records where the 'alpha2' field is less than or equal to specified value.

=item * B<alpha2.min> => I<str>

Only return records where the 'alpha2' field is greater than or equal to specified value.

=item * B<alpha2.not_contains> => I<str>

Only return records where the 'alpha2' field does not contain specified text.

=item * B<alpha2.not_in> => I<array[str]>

Only return records where the 'alpha2' field is not in the specified values.

=item * B<alpha2.xmax> => I<str>

Only return records where the 'alpha2' field is less than specified value.

=item * B<alpha2.xmin> => I<str>

Only return records where the 'alpha2' field is greater than specified value.

=item * B<alpha3> => I<str>

Only return records where the 'alpha3' field equals specified value.

=item * B<alpha3.contains> => I<str>

Only return records where the 'alpha3' field contains specified text.

=item * B<alpha3.in> => I<array[str]>

Only return records where the 'alpha3' field is in the specified values.

=item * B<alpha3.is> => I<str>

Only return records where the 'alpha3' field equals specified value.

=item * B<alpha3.isnt> => I<str>

Only return records where the 'alpha3' field does not equal specified value.

=item * B<alpha3.max> => I<str>

Only return records where the 'alpha3' field is less than or equal to specified value.

=item * B<alpha3.min> => I<str>

Only return records where the 'alpha3' field is greater than or equal to specified value.

=item * B<alpha3.not_contains> => I<str>

Only return records where the 'alpha3' field does not contain specified text.

=item * B<alpha3.not_in> => I<array[str]>

Only return records where the 'alpha3' field is not in the specified values.

=item * B<alpha3.xmax> => I<str>

Only return records where the 'alpha3' field is less than specified value.

=item * B<alpha3.xmin> => I<str>

Only return records where the 'alpha3' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-LocaleCodesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LocaleCodesUtils>.

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

This software is copyright (c) 2023, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LocaleCodesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
