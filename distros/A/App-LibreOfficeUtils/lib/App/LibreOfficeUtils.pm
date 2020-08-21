package App::LibreOfficeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-21'; # DATE
our $DIST = 'App-LibreOfficeUtils'; # DIST
our $VERSION = '0.000'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{delete_libreoffice_profile} = {
    v => 1.1,
    summary => 'Delete LibreOffice user profile',
    description => <<'_',

When your LibreOffice crashes and you look for help, a common thing people tell
you is to reset your user profile or start in safe mode. This user profile is a
directory of files which LibreOffice itself writes but due to some reason will
often gets corrupted. (As to why LibreOffice gets confused by things it itself
writes, is left for us to wonder.) This script will help delete your user
profile.

_
    args => {
    },
};
sub delete_libreoffice_profile {
    [501, "Not yet implemented"];
}

1;
# ABSTRACT: Utilities related to LibreOffice

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LibreOfficeUtils - Utilities related to LibreOffice

=head1 VERSION

This document describes version 0.000 of App::LibreOfficeUtils (from Perl distribution App-LibreOfficeUtils), released on 2020-08-21.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=back

=head1 FUNCTIONS


=head2 delete_libreoffice_profile

Usage:

 delete_libreoffice_profile() -> [status, msg, payload, meta]

Delete LibreOffice user profile.

When your LibreOffice crashes and you look for help, a common thing people tell
you is to reset your user profile or start in safe mode. This user profile is a
directory of files which LibreOffice itself writes but due to some reason will
often gets corrupted. (As to why LibreOffice gets confused by things it itself
writes, is left for us to wonder.) This script will help delete your user
profile.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LibreOfficeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LibreOfficeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LibreOfficeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::MSOfficeUtils>

L<App::OfficeUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
