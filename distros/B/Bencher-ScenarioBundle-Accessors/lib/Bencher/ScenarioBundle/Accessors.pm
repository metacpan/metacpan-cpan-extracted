package Bencher::ScenarioBundle::Accessors;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

1;
# ABSTRACT: Scenarios to benchmark class accessors

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioBundle::Accessors - Scenarios to benchmark class accessors

=head1 VERSION

This document describes version 0.151 of Bencher::ScenarioBundle::Accessors (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::Accessors::Get>

=item * L<Bencher::Scenario::Accessors::Construction>

=item * L<Bencher::Scenario::Accessors::GeneratorStartup>

=item * L<Bencher::Scenario::Accessors::ClassStartup>

=item * L<Bencher::Scenario::Accessors::Set>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 SEE ALSO

The L<Benchmark::Perl::Formance> distribution contains various benchmarks, in
particular the C<Benchmark::Perl::Formance::Plugin::Accessors*> modules.

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

This software is copyright (c) 2024, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
