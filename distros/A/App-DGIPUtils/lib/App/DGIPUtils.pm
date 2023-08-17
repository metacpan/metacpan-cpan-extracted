package App::DGIPUtils;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-05'; # DATE
our $DIST = 'App-DGIPUtils'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Utilities related to Indonesian DGIP (Directorate General of Intellectual Property)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DGIPUtils - Utilities related to Indonesian DGIP (Directorate General of Intellectual Property)

=head1 VERSION

This document describes version 0.001 of App::DGIPUtils (from Perl distribution App-DGIPUtils), released on 2023-07-05.

=head1 DESCRIPTION

This distribution provides CLI utilities related to Indonesian DGIP (Directorate
General of Intellectual Property).

=over

=item * L<list-dgip-classes>

=back

Keywords: DJKI (Direktorat Jenderal Kekayaan Intelektual), trademark, merek,
patent, paten, industrial design, desain industri, copyright, hak cipta,
geographical indication, indikasi geografis.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DGIPUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DGIPUtils>.

=head1 SEE ALSO

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
