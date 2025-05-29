package App::CdUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-05-29'; # DATE
our $DIST = 'App-CdUtils'; # DIST
our $VERSION = '0.008'; # VERSION

1;

# ABSTRACT: CLI utilities related to changing directories

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CdUtils - CLI utilities related to changing directories

=head1 VERSION

This document describes version 0.008 of App::CdUtils (from Perl distribution App-CdUtils), released on 2025-05-29.

=head1 DESCRIPTION

This distribution contains the following utilities:

=over

=item * L<cdpart-backend>

=item * L<cdsibling-backend>

=item * L<cdtarget-backend>

=item * L<cdtree-backend>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CdUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CdUtils>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CdUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
