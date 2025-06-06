## no critic: TestingAndDebugging::RequireUseStrict
package Acme::PERLANCAR::Test::Require::PrintTwo;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-06'; # DATE
our $DIST = 'Acme-PERLANCAR-Test-Require'; # DIST
our $VERSION = '0.001'; # VERSION

print "2\n";

1;
# ABSTRACT: Print "2" when loaded

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Test::Require::PrintTwo - Print "2" when loaded

=head1 VERSION

This document describes version 0.001 of Acme::PERLANCAR::Test::Require::PrintTwo (from Perl distribution Acme-PERLANCAR-Test-Require), released on 2023-12-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Test-Require>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Test-Require>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Test-Require>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
