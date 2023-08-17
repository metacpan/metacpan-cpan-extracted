package App::DGIPUtils::Table;

use strict;
use warnings;

use Exporter qw(import);
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use TableData::Business::ID::DGIP::Class;

our @EXPORT_OK = qw(list_dgip_classes);

my $res;

my $table = TableData::Business::ID::DGIP::Class->new;
$res = gen_read_table_func(
    name => 'list_dgip_classes',
    summary => 'List classes of products/services recognized by DGIP',
    table_data => $table,
);
$res->[0] == 200 or die "Can't generate list_dgip_classes(): $res->[0] - $res->[1]";

1;
# ABSTRACT: List classes of products/services recognized by DGIP

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DGIPUtils::Table - List classes of products/services recognized by DGIP

=head1 VERSION

This document describes version 0.001 of App::DGIPUtils::Table (from Perl distribution App-DGIPUtils), released on 2023-07-05.

=head1 FUNCTIONS


=head2 list_dgip_classes

Usage:

 list_dgip_classes(%args) -> [$status_code, $reason, $payload, \%result_meta]

List classes of productsE<sol>services recognized by DGIP.

REPLACE ME

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class> => I<str>

Only return records where the 'class' field equals specified value.

=item * B<class.contains> => I<str>

Only return records where the 'class' field contains specified text.

=item * B<class.in> => I<array[str]>

Only return records where the 'class' field is in the specified values.

=item * B<class.is> => I<str>

Only return records where the 'class' field equals specified value.

=item * B<class.isnt> => I<str>

Only return records where the 'class' field does not equal specified value.

=item * B<class.max> => I<str>

Only return records where the 'class' field is less than or equal to specified value.

=item * B<class.min> => I<str>

Only return records where the 'class' field is greater than or equal to specified value.

=item * B<class.not_contains> => I<str>

Only return records where the 'class' field does not contain specified text.

=item * B<class.not_in> => I<array[str]>

Only return records where the 'class' field is not in the specified values.

=item * B<class.xmax> => I<str>

Only return records where the 'class' field is less than specified value.

=item * B<class.xmin> => I<str>

Only return records where the 'class' field is greater than specified value.

=item * B<description> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.contains> => I<str>

Only return records where the 'description' field contains specified text.

=item * B<description.in> => I<array[str]>

Only return records where the 'description' field is in the specified values.

=item * B<description.is> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.isnt> => I<str>

Only return records where the 'description' field does not equal specified value.

=item * B<description.max> => I<str>

Only return records where the 'description' field is less than or equal to specified value.

=item * B<description.min> => I<str>

Only return records where the 'description' field is greater than or equal to specified value.

=item * B<description.not_contains> => I<str>

Only return records where the 'description' field does not contain specified text.

=item * B<description.not_in> => I<array[str]>

Only return records where the 'description' field is not in the specified values.

=item * B<description.xmax> => I<str>

Only return records where the 'description' field is less than specified value.

=item * B<description.xmin> => I<str>

Only return records where the 'description' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-DGIPUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DGIPUtils>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DGIPUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
