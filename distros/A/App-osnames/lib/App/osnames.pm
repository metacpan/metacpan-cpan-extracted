package App::osnames;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'App-osnames'; # DIST
our $VERSION = '0.101'; # VERSION

our %SPEC;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Perl::osnames;

my $res = gen_read_table_func(
    name       => 'list_osnames',
    summary    => 'List possible $^O ($OSNAME) values, with description',
    description => <<'_',

This list might be useful when coding, e.g. when you want to exclude or include
certain OS (families) in your application/test.

_
    table_data => $Perl::osnames::data,
    table_def  => {
        summary => 'List of possible $^O ($OSNAME) values',
        fields  => {
            value => {
                schema   => 'str*',
                index    => 0,
                sortable => 1,
            },
            tags => {
                #schema   => [array => of => 'str*'],
                schema => 'str*',
                index    => 1,
            },
            description => {
                schema   => 'str*',
                index    => 2,
            },
        },
        pk => 'value',
    },
    enable_paging => 0, # there are only a handful of rows
    enable_random_ordering => 0,
    hooks => {
        after_fetch_data => sub {
            my %args = @_;

            # if run under pericmd-lite, convert tags array to comma-separated
            # string so the result can be displayed as a text table
            if ($args{_func_args}{-cmdline} &&
                    $args{_func_args}{-cmdline}->isa("Perinci::CmdLine::Lite") &&
                    ($args{_func_args}{-cmdline_r}{format} // '') !~ /json/) {
                my $data = $args{_data};
                for (@$data) {
                    $_->[1] = join(",", @{$_->[1]});
                }
            }
            return;
        },
    },
);
die "Can't generate list_osnames function: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

$SPEC{list_osnames}{examples} = [
    {
        argv    => [qw/ux/],
        summary => 'String search',
    },
    {
        argv    => [qw/--tags unix -l/],
        summary => 'List Unices',
    },
];

1;
# ABSTRACT: List possible $^O ($OSNAME) values, with description

__END__

=pod

=encoding UTF-8

=head1 NAME

App::osnames - List possible $^O ($OSNAME) values, with description

=head1 VERSION

This document describes version 0.101 of App::osnames (from Perl distribution App-osnames), released on 2023-02-24.

=head1 FUNCTIONS


=head2 list_osnames

Usage:

 list_osnames(%args) -> [$status_code, $reason, $payload, \%result_meta]

List possible $^O ($OSNAME) values, with description.

Examples:

=over

=item * String search:

 list_osnames(queries => ["ux"]);

Result:

 [
   200,
   "OK",
   ["dgux", "gnu", "hpux", "linux"],
   { "table.fields" => ["value"] },
 ]

=item * List Unices:

 list_osnames(detail => 1, tags => "unix");

Result:

 [
   200,
   "OK",
   [],
   { "table.fields" => ["value", "tags", "description"] },
 ]

=back

This list might be useful when coding, e.g. when you want to exclude or include
certain OS (families) in your application/test.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

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

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<tags> => I<str>

Only return records where the 'tags' field equals specified value.

=item * B<tags.contains> => I<str>

Only return records where the 'tags' field contains specified text.

=item * B<tags.in> => I<array[str]>

Only return records where the 'tags' field is in the specified values.

=item * B<tags.is> => I<str>

Only return records where the 'tags' field equals specified value.

=item * B<tags.isnt> => I<str>

Only return records where the 'tags' field does not equal specified value.

=item * B<tags.max> => I<str>

Only return records where the 'tags' field is less than or equal to specified value.

=item * B<tags.min> => I<str>

Only return records where the 'tags' field is greater than or equal to specified value.

=item * B<tags.not_contains> => I<str>

Only return records where the 'tags' field does not contain specified text.

=item * B<tags.not_in> => I<array[str]>

Only return records where the 'tags' field is not in the specified values.

=item * B<tags.xmax> => I<str>

Only return records where the 'tags' field is less than specified value.

=item * B<tags.xmin> => I<str>

Only return records where the 'tags' field is greater than specified value.

=item * B<value> => I<str>

Only return records where the 'value' field equals specified value.

=item * B<value.contains> => I<str>

Only return records where the 'value' field contains specified text.

=item * B<value.in> => I<array[str]>

Only return records where the 'value' field is in the specified values.

=item * B<value.is> => I<str>

Only return records where the 'value' field equals specified value.

=item * B<value.isnt> => I<str>

Only return records where the 'value' field does not equal specified value.

=item * B<value.max> => I<str>

Only return records where the 'value' field is less than or equal to specified value.

=item * B<value.min> => I<str>

Only return records where the 'value' field is greater than or equal to specified value.

=item * B<value.not_contains> => I<str>

Only return records where the 'value' field does not contain specified text.

=item * B<value.not_in> => I<array[str]>

Only return records where the 'value' field is not in the specified values.

=item * B<value.xmax> => I<str>

Only return records where the 'value' field is less than specified value.

=item * B<value.xmin> => I<str>

Only return records where the 'value' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-osnames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-osnames>.

=head1 SEE ALSO

L<Perl::osnames>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2023, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-osnames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
