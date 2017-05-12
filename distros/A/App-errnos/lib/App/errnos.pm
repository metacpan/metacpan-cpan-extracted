package App::errnos;

our $DATE = '2015-09-10'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our @ERRNOS;
{
    my $i = 0;
    local $!;
    while (1) {
        $i++;
        $! = $i;
        my $msg = "$!";
        last if $msg =~ /unknown error/i;
        push @ERRNOS, [$i, $msg];
        # hard limit
        last if $i > 1000;
    }
}

my $res = gen_read_table_func(
    name       => 'list_errnos',
    summary    => 'List possible $! ($OS_ERROR, $ERRNO) values on your system',
    description => <<'_',

_
    table_data => \@ERRNOS,
    table_spec => {
        summary => 'List of possible $! ($OS_ERROR, $ERRNO) values',
        fields  => {
            number => {
                schema   => 'int*',
                index    => 0,
                sortable => 1,
            },
            string => {
                schema   => 'str*',
                index    => 1,
            },
        },
        pk => 'number',
    },
    enable_paging => 0,
    enable_random_ordering => 0,
);
die "Can't generate list_errnos function: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

$SPEC{list_errnos}{args}{query}{pos} = 0;
$SPEC{list_errnos}{args}{detail}{cmdline_aliases} = {l=>{}};
$SPEC{list_errnos}{args}{query}{pos} = 0;
$SPEC{list_errnos}{examples} = [
    {
        summary => 'List possible errno numbers with their messages',
        argv => ["-l"],
    },
    {
        summary => 'Search specific errnos',
        argv => ["-l", "No such"],
    },
];

1;
# ABSTRACT: List possible $! ($OS_ERROR, $ERRNO) values on your system

__END__

=pod

=encoding UTF-8

=head1 NAME

App::errnos - List possible $! ($OS_ERROR, $ERRNO) values on your system

=head1 VERSION

This document describes version 0.02 of App::errnos (from Perl distribution App-errnos), released on 2015-09-10.

=head1 SEE ALSO

perldata

=head1 FUNCTIONS


=head2 list_errnos(%args) -> [status, msg, result, meta]

List possible $! ($OS_ERROR, $ERRNO) values on your system.

Examples:

 list_errnos( detail => 1);


List possible errno numbers with their messages.


 list_errnos( detail => 1, query => "'No such'");


Search specific errnos.


Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<number> => I<int>

Only return records where the 'number' field equals specified value.

=item * B<number.in> => I<array[int]>

Only return records where the 'number' field is in the specified values.

=item * B<number.is> => I<int>

Only return records where the 'number' field equals specified value.

=item * B<number.isnt> => I<int>

Only return records where the 'number' field does not equal specified value.

=item * B<number.max> => I<int>

Only return records where the 'number' field is less than or equal to specified value.

=item * B<number.min> => I<int>

Only return records where the 'number' field is greater than or equal to specified value.

=item * B<number.not_in> => I<array[int]>

Only return records where the 'number' field is not in the specified values.

=item * B<number.xmax> => I<int>

Only return records where the 'number' field is less than specified value.

=item * B<number.xmin> => I<int>

Only return records where the 'number' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<sort> => I<str>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<string> => I<str>

Only return records where the 'string' field equals specified value.

=item * B<string.contains> => I<str>

Only return records where the 'string' field contains specified text.

=item * B<string.in> => I<array[str]>

Only return records where the 'string' field is in the specified values.

=item * B<string.is> => I<str>

Only return records where the 'string' field equals specified value.

=item * B<string.isnt> => I<str>

Only return records where the 'string' field does not equal specified value.

=item * B<string.max> => I<str>

Only return records where the 'string' field is less than or equal to specified value.

=item * B<string.min> => I<str>

Only return records where the 'string' field is greater than or equal to specified value.

=item * B<string.not_contains> => I<str>

Only return records where the 'string' field does not contain specified text.

=item * B<string.not_in> => I<array[str]>

Only return records where the 'string' field is not in the specified values.

=item * B<string.xmax> => I<str>

Only return records where the 'string' field is less than specified value.

=item * B<string.xmin> => I<str>

Only return records where the 'string' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-errnos>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-errnos>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-errnos>

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
