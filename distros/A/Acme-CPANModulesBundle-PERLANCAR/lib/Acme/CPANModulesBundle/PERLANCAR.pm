# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Acme::CPANModulesBundle::PERLANCAR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-01'; # DATE
our $DIST = 'Acme-CPANModulesBundle-PERLANCAR'; # DIST
our $VERSION = '0.014'; # VERSION

1;
# ABSTRACT: Bundle of Acme::CPANModules::PERLANCAR::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModulesBundle::PERLANCAR - Bundle of Acme::CPANModules::PERLANCAR::* modules

=head1 VERSION

This document describes version 0.014 of Acme::CPANModulesBundle::PERLANCAR (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2023-11-01.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES MODULES

The following Acme::CPANModules::* modules are included in this distribution:

=over

=item * L<PERLANCAR::Avoided|Acme::CPANModules::PERLANCAR::Avoided>

List of modules I'm currently avoiding.

This is a list of modules I'm currently avoiding to use in my code, for some
reason. Most of the modules wered used in my code in the past.

Using a L<Dist::Zilla> plugin
L<Dist::Zilla::Plugin::Acme::CPANModules::Blacklist>, you can make sure that
during building, your distribution does not specify a prerequisite to any of the
modules listed here. (You should make your own blacklist though).


=item * L<PERLANCAR::MyCLIWithSubcommands|Acme::CPANModules::PERLANCAR::MyCLIWithSubcommands>

List of distributions that contain CLI scripts with subcommands.

=item * L<PERLANCAR::MyGetoptLongExperiment|Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment>

List of my experiments writing Getopt::Long replacementsE<sol>alternatives.

Most of these modules provide a L<Getopt::Long>-compatible interface, but they
differ in some aspect: either they offer more features (or less).


=item * L<PERLANCAR::MyRetired|Acme::CPANModules::PERLANCAR::MyRetired>

List of my retired modules.

This is a list of some of the modules which I wrote but have now been retired
and purged from CPAN, for various reasons but mostly because they are no longer
necessary. I've purged/retired more modules than these (mostly failed
experiments) but they are not worth mentioning here because nobody else seems to
have used them.

Note that you can always get these retired modules from BackPAN or GitHub (I
don't purge most of the repos) if needed.


=item * L<PERLANCAR::Weird|Acme::CPANModules::PERLANCAR::Weird>

List of weird modules.

List of modules I find weird (non-pejoratively speaking) in one way or another,
e.g. peculiar API, name.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 SEE ALSO

L<Acme::CPANModules> - the specification

L<App::cpanmodules> - the main CLI

L<App::CPANModulesUtils> - other CLIs

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

This software is copyright (c) 2023, 2021, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
