package App::osnames;

our $DATE = '2015-09-15'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
use warnings;

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
    table_spec => {
        summary => 'List of possible $^O ($OSNAME) values',
        fields  => {
            value => {
                schema   => 'str*',
                index    => 0,
                sortable => 1,
            },
            tags => {
                schema   => [array => of => 'str*'],
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

$SPEC{list_osnames}{args}{query}{pos} = 0;
$SPEC{list_osnames}{examples} = [
    {
        argv    => [qw/ux/],
        summary => 'String search',
    },
    {
        argv    => [qw/--tags-has unix --detail/],
        summary => 'List Unices',
    },
    {
        argv    => [qw/--tags-lacks unix --detail/],
        summary => 'List non-Unices',
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

This document describes version 0.10 of App::osnames (from Perl distribution App-osnames), released on 2015-09-15.

=head1 SEE ALSO

L<Perl::osnames>

=head1 FUNCTIONS


=head2 list_osnames(%args) -> [status, msg, result, meta]

List possible $^O ($OSNAME) values, with description.

Examples:

 list_osnames( query => "ux");


String search.


 list_osnames( "detail" => 1, "tags.has" => ["unix"]);


List Unices.


 list_osnames( "detail" => 1, "tags.lacks" => ["unix"]);


List non-Unices.


This list might be useful when coding, e.g. when you want to exclude or include
certain OS (families) in your application/test.

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

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<query> => I<str>

Search.

=item * B<sort> => I<str>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<tags> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.has> => I<array[str]>

Only return records where the 'tags' field is an array/list which contains specified value.

=item * B<tags.is> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.isnt> => I<array>

Only return records where the 'tags' field does not equal specified value.

=item * B<tags.lacks> => I<array[str]>

Only return records where the 'tags' field is an array/list which does not contain specified value.

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

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-osnames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-osnames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-osnames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
