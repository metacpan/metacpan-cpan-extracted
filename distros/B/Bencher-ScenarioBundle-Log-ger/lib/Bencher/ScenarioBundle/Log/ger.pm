package Bencher::ScenarioBundle::Log::ger;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

1;
# ABSTRACT: Scenarios for benchmarking Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioBundle::Log::ger - Scenarios for benchmarking Log::ger

=head1 VERSION

This document describes version 0.020 of Bencher::ScenarioBundle::Log::ger (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::Log::ger::InitTarget>

=item * L<Bencher::Scenario::Log::ger::Startup>

=item * L<Bencher::Scenario::Log::ger::NullOutput>

=item * L<Bencher::Scenario::Log::ger::OutputStartup>

=item * L<Bencher::Scenario::Log::ger::NumericLevel>

=item * L<Bencher::Scenario::Log::ger::LayoutStartup>

=item * L<Bencher::Scenario::Log::ger::StringLevel>

=item * L<Bencher::Scenario::Log::ger::Overhead>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Log-ger>.

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

This software is copyright (c) 2024, 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
