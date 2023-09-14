package Bencher::Scenarios::HTTP::Tiny::Plugin;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-HTTP-Tiny-Plugin'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Scenarios to benchmark HTTP::Tiny::Plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::HTTP::Tiny::Plugin - Scenarios to benchmark HTTP::Tiny::Plugin

=head1 VERSION

This document describes version 0.002 of Bencher::Scenarios::HTTP::Tiny::Plugin (from Perl distribution Bencher-Scenarios-HTTP-Tiny-Plugin), released on 2023-01-19.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::HTTP::Tiny::Plugin::Startup>

=item * L<Bencher::Scenario::HTTP::Tiny::Plugin::request_overhead>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HTTP-Tiny-Plugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HTTP-Tiny-Plugin>.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HTTP-Tiny-Plugin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
