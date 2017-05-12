package App::ReleaseUtils;

our $DATE = '2017-02-10'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

1;
# ABSTRACT: Collection of utilities related to software releases

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ReleaseUtils - Collection of utilities related to software releases

=head1 VERSION

This document describes version 0.002 of App::ReleaseUtils (from Perl distribution App-ReleaseUtils), released on 2017-02-10.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
software releases:

=over

=item * L<list-git-release-tags>

=item * L<list-git-release-years>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ReleaseUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ReleaseUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ReleaseUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
