package App::ListPerlReleases;

our $DATE = '2018-06-24'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_perl_releases
               );

my $res = gen_read_table_func(
    name => 'list_perl_releases',
    table_data => sub {
        require CPAN::Perl::Releases;

        my @data;
        my @vers = CPAN::Perl::Releases::perl_versions();
        for my $ver (@vers) {
            my $tarballs = CPAN::Perl::Releases::perl_tarballs($ver);
            my $tarball = $tarballs->{ (sort keys %$tarballs)[0] };
            push @data, {
                version => $ver,
                tarball => $tarball,
            };
        }

        {data => \@data};
    },
    table_spec => {
        summary => 'List of Perl releases',
        fields => {
            version => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            tarball => {
                schema => 'filename*',
                pos => 1,
                sortable => 1,
            },
        },
        pk => 'version',
    },
);
die "BUG: Can't generate list_perl_releases: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

1;
# ABSTRACT: List Perl releases

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ListPerlReleases - List Perl releases

=head1 VERSION

This document describes version 0.001 of App::ListPerlReleases (from Perl distribution App-ListPerlReleases), released on 2018-06-24.

=head1 SYNOPSIS

See the included script L<list-perl-releases>.

=head1 DESCRIPTION

This distribution offers L<list-perl-releases>, a CLI front-end for
L<CPAN::Perl::Releases>.

=head1 FUNCTIONS


=head2 list_perl_releases

Usage:

 list_perl_releases(%args) -> [status, msg, result, meta]

List of Perl releases.

REPLACE ME

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<query> => I<str>

Search.

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

=item * B<tarball> => I<filename>

Only return records where the 'tarball' field equals specified value.

=item * B<tarball.in> => I<array[filename]>

Only return records where the 'tarball' field is in the specified values.

=item * B<tarball.is> => I<filename>

Only return records where the 'tarball' field equals specified value.

=item * B<tarball.isnt> => I<filename>

Only return records where the 'tarball' field does not equal specified value.

=item * B<tarball.not_in> => I<array[filename]>

Only return records where the 'tarball' field is not in the specified values.

=item * B<version> => I<str>

Only return records where the 'version' field equals specified value.

=item * B<version.contains> => I<str>

Only return records where the 'version' field contains specified text.

=item * B<version.in> => I<array[str]>

Only return records where the 'version' field is in the specified values.

=item * B<version.is> => I<str>

Only return records where the 'version' field equals specified value.

=item * B<version.isnt> => I<str>

Only return records where the 'version' field does not equal specified value.

=item * B<version.max> => I<str>

Only return records where the 'version' field is less than or equal to specified value.

=item * B<version.min> => I<str>

Only return records where the 'version' field is greater than or equal to specified value.

=item * B<version.not_contains> => I<str>

Only return records where the 'version' field does not contain specified text.

=item * B<version.not_in> => I<array[str]>

Only return records where the 'version' field is not in the specified values.

=item * B<version.xmax> => I<str>

Only return records where the 'version' field is less than specified value.

=item * B<version.xmin> => I<str>

Only return records where the 'version' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ListPerlReleases>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ListPerlReleases>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ListPerlReleases>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Perl::Releases>

L<App::perlbrew> also offers "perlbrew available" or "perlbrew available --all"
to list Perl releases.

L<https://www.cpan.org>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
