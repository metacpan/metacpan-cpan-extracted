package App::PMVersionsUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-22'; # DATE
our $DIST = 'App-PMVersionsUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to PMVersions',
};

$SPEC{version_from_pmversions} = {
    v => 1.1,
    summary => 'Get minimum Perl module version from pmversions.ini',
    args => {
        module => {
            summary => 'Module name, if unspecified will use `this-mod` to get the current module',
            schema => 'perl::modname*',
            pos => 0,
        },
        pmversions_path => {
            schema => 'filename*',
        },
    },
};
sub version_from_pmversions {
    require PMVersions::Util;

    my %args = @_;

    unless (defined $args{module}) {
        require App::ThisDist;
        $args{module} = App::ThisDist::this_mod();
    }
    unless (defined $args{module}) {
        return [400, "Please specify module"];
    }

    log_trace "Getting version of module %s from path %s ...", $args{module}, $args{path};
    [200,
     "OK",
     PMVersions::Util::version_from_pmversions($args{module}, $args{pmversions_path}),
     {'func.module'=>$args{module}},
 ];
}

1;
# ABSTRACT: CLI utilities related to PMVersions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PMVersionsUtils - CLI utilities related to PMVersions

=head1 VERSION

This document describes version 0.001 of App::PMVersionsUtils (from Perl distribution App-PMVersionsUtils), released on 2021-06-22.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
PMVersions:

=over

=item * L<version-from-pmversions>

=back

=head1 FUNCTIONS


=head2 version_from_pmversions

Usage:

 version_from_pmversions(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get minimum Perl module version from pmversions.ini.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module> => I<perl::modname>

Module name, if unspecified will use `this-mod` to get the current module.

=item * B<pmversions_path> => I<filename>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-PMVersionsUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PMVersionsUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PMVersionsUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<PMVersions::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
