package App::ListPerlReleases;

use 5.010001;
use strict;
use warnings;

use Exporter;
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Sah::Schema::filename; # for scan_prereqs

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-01'; # DATE
our $DIST = 'App-ListPerlReleases'; # DIST
our $VERSION = '0.004'; # VERSION

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
    description => <<'_',

This utility uses <pm:CPAN::Perl::Releases>'s `perl_tarballs()` to list releases
of Perl interpreters. For each release, it provides information such as version
number and location of tarballs in releaser author's directory on CPAN.

Update the CPAN::Perl::Releases module to get the latest list of releases.

_
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

This document describes version 0.004 of App::ListPerlReleases (from Perl distribution App-ListPerlReleases), released on 2021-01-01.

=head1 SYNOPSIS

See the included script L<list-perl-releases>.

=head1 DESCRIPTION

This distribution offers L<list-perl-releases>, a CLI front-end for
L<CPAN::Perl::Releases>.

=head1 FUNCTIONS


=head2 list_perl_releases

Usage:

 list_perl_releases(%args) -> [$status_code, $reason, $payload, \%result_meta]

List of Perl releases.

This utility uses L<CPAN::Perl::Releases>'s C<perl_tarballs()> to list releases
of Perl interpreters. For each release, it provides information such as version
number and location of tarballs in releaser author's directory on CPAN.

Update the CPAN::Perl::Releases module to get the latest list of releases.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

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

=item * B<tarball> => I<str>

Only return records where the 'tarball' field equals specified value.

=item * B<tarball.contains> => I<str>

Only return records where the 'tarball' field contains specified text.

=item * B<tarball.in> => I<array[str]>

Only return records where the 'tarball' field is in the specified values.

=item * B<tarball.is> => I<str>

Only return records where the 'tarball' field equals specified value.

=item * B<tarball.isnt> => I<str>

Only return records where the 'tarball' field does not equal specified value.

=item * B<tarball.max> => I<str>

Only return records where the 'tarball' field is less than or equal to specified value.

=item * B<tarball.min> => I<str>

Only return records where the 'tarball' field is greater than or equal to specified value.

=item * B<tarball.not_contains> => I<str>

Only return records where the 'tarball' field does not contain specified text.

=item * B<tarball.not_in> => I<array[str]>

Only return records where the 'tarball' field is not in the specified values.

=item * B<tarball.xmax> => I<str>

Only return records where the 'tarball' field is less than specified value.

=item * B<tarball.xmin> => I<str>

Only return records where the 'tarball' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ListPerlReleases>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ListPerlReleases>.

=head1 SEE ALSO

L<CPAN::Perl::Releases>

L<App::perlbrew> also offers "perlbrew available" or "perlbrew available --all"
to list Perl releases.

L<https://www.cpan.org>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ListPerlReleases>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
