package Acme::CPANModules::PERLANCAR::Unused;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-06'; # DATE
our $DIST = 'Acme-CPANModules-PERLANCAR-Unused'; # DIST
our $VERSION = '0.003'; # VERSION

my $unused_dists = <<'_';
Acme-PERLANCAR-Dummy
Acme-PERLANCAR-Dummy-POD
Acme-PERLANCAR-DumpImportArgs
Acme-PERLANCAR-Prime
Acme-PERLANCAR-Test-Dependency-One
Acme-PERLANCAR-Test-Dependency-Three
Acme-PERLANCAR-Test-Dependency-Two
Acme-PERLANCAR-Test-Images
Acme-PERLANCAR-Test-MetaCPAN-HTML
Acme-PERLANCAR-Test-Misc
Acme-PERLANCAR-Test-SameRelease
Acme-PERLANCAR-Test-Versioning
Acme-Test-LocaleTextDomain
Acme-Test-LocaleTextDomainIfEnv
Acme-Test-LocaleTextDomainUTF8IfEnv
Acme-Test-crypt

Gepok
_

chomp(my @unused_modules = grep /\S/, split /^/m, $unused_dists);
s/-/::/g for @unused_modules;

our $LIST = {
    entries => [
        map { +{module=>$_} } @unused_modules,
    ],
    summary => "List of my modules which are (currently not used by me, currently not installable) ",
};


1;
# ABSTRACT: List of my modules which are (currently not used by me, currently not installable) 

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Unused - List of my modules which are (currently not used by me, currently not installable) 

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::PERLANCAR::Unused (from Perl distribution Acme-CPANModules-PERLANCAR-Unused), released on 2023-07-06.

=head1 DESCRIPTION

I use this to generate L<Task::BeLike::PERLANCAR::Used>, which in turn I use to
install all my perl modules on a new perl installation. What I usually do after
installing a perl with L<perlbrew>:

 % cpanm -n App::cpanm::perlancar
 % cpanm-perlancar -n Task::BeLike::PERLANCAR::Used

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Acme::PERLANCAR::Dummy>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Dummy::POD>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::DumpImportArgs>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Prime>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::Dependency::One>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::Dependency::Three>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::Dependency::Two>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::Images>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::MetaCPAN::HTML>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::Misc>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::SameRelease>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::PERLANCAR::Test::Versioning>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::Test::LocaleTextDomain>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::Test::LocaleTextDomainIfEnv>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::Test::LocaleTextDomainUTF8IfEnv>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::Test::crypt>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Gepok>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n PERLANCAR::Unused

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PERLANCAR::Unused | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::Unused -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::Unused -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::Unused::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-Unused>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-Unused>.

=head1 SEE ALSO

L<Task::BeLike::PERLANCAR::Used>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PERLANCAR-Unused>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
