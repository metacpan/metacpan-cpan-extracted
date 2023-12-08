package Acme::CPANModules::CPANAuthors;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-28'; # DATE
our $DIST = 'Acme-CPANModules-CPANAuthors'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of Acme::CPANAUthors::* modules',
    description => <<'_',

This list tries to catalog and categorize all the existing Acme::CPANAuthors::*
modules.

## Geographical

* <pm:Acme::CPANAuthors::Australian>
* <pm:Acme::CPANAuthors::Austrian>
* <pm:Acme::CPANAuthors::Belarusian>
* <pm:Acme::CPANAuthors::Brazilian>
* <pm:Acme::CPANAuthors::British>
* <pm:Acme::CPANAuthors::British::Companies>
* <pm:Acme::CPANAuthors::Canadian>
* <pm:Acme::CPANAuthors::Catalonian>
* <pm:Acme::CPANAuthors::Chinese>
* <pm:Acme::CPANAuthors::Czech>
* <pm:Acme::CPANAuthors::Danish>
* <pm:Acme::CPANAuthors::Dutch>
* <pm:Acme::CPANAuthors::EU> - alias for ::European
* <pm:Acme::CPANAuthors::European>
* <pm:Acme::CPANAuthors::French>
* <pm:Acme::CPANAuthors::German>
* <pm:Acme::CPANAuthors::Icelandic>
* <pm:Acme::CPANAuthors::India>
* <pm:Acme::CPANAuthors::Indonesian>
* <pm:Acme::CPANAuthors::Israeli>
* <pm:Acme::CPANAuthors::Japanese>
* <pm:Acme::CPANAuthors::Korean>
* <pm:Acme::CPANAuthors::Malaysian>
* <pm:Acme::CPANAuthors::Norwegian>
* <pm:Acme::CPANAuthors::Polish>
* <pm:Acme::CPANAuthors::Portuguese>
* <pm:Acme::CPANAuthors::Russian>
* <pm:Acme::CPANAuthors::Slovak>
* <pm:Acme::CPANAuthors::Spanish>
* <pm:Acme::CPANAuthors::Swedish>
* <pm:Acme::CPANAuthors::Taiwanese>
* <pm:Acme::CPANAuthors::Turkish>


## CPAN-related

* <pm:Acme::CPANAuthors::BackPAN::OneHundred>
* <pm:Acme::CPANAuthors::CPAN::MostScripts>
* <pm:Acme::CPANAuthors::CPAN::OneHundred>
* <pm:Acme::CPANAuthors::CPAN::Streaks::DailyDistributions>
* <pm:Acme::CPANAuthors::CPAN::Streaks::DailyNewDistributions>
* <pm:Acme::CPANAuthors::CPAN::Streaks::DailyReleases>
* <pm:Acme::CPANAuthors::CPAN::Streaks::WeeklyDistributions>
* <pm:Acme::CPANAuthors::CPAN::Streaks::WeeklyNewDistributions>
* <pm:Acme::CPANAuthors::CPAN::Streaks::WeeklyReleases>
* <pm:Acme::CPANAuthors::CPAN::Streaks::MonthlyDistributions>
* <pm:Acme::CPANAuthors::CPAN::Streaks::MonthlyNewDistributions>
* <pm:Acme::CPANAuthors::CPAN::Streaks::MonthlyReleases>
* <pm:Acme::CPANAuthors::CPAN::TopDepended>
* <pm:Acme::CPANAuthors::CPAN::TopDepended::ByOthers>
* <pm:Acme::CPANAuthors::CPANTS::FiveOrMore>


## Perl-related

* <pm:Acme::CPANAuthors::Pumpkings>


## Module-related

* <pm:Acme::CPANAuthors::AnyEvent>
* <pm:Acme::CPANAuthors::DualLife> - authors of dual-life core modules (modules that are included in perl distribution as well as get released separately)
* <pm:Acme::CPANAuthors::MetaSyntactic>
* <pm:Acme::CPANAuthors::POE>
* <pm:Acme::CPANAuthors::ToBeLike>


## (Non-CPAN) project-related

* <pm:Acme::CPANAuthors::DebianDev>


## Service-related

* <pm:Acme::CPANAuthors::GitHub> - authors with github repositories


## Deceased authors

* <pm:Acme::CPANAuthors::InMemoriam>


## Defunct

* <pm:Acme::CPANAuthors::CodeRepos> - authors using <https://coderepos.org/>, a now-defunct service


## Others

* <pm:Acme::CPANAuthors::GeekHouse> - authors who have visited The Geek House ever
* <pm:Acme::CPANAuthors::MBTI> - authors by MBTI types
* <pm:Acme::CPANAuthors::MBTI::INTP> - authors with "INTP" personality type
* <pm:Acme::CPANAuthors::Misanthrope> - authors who see into your soul with perfect clarity
* <pm:Acme::CPANAuthors::Nonhuman>
* <pm:Acme::CPANAuthors::Not>
* <pm:Acme::CPANAuthors::You::re_using>


## *Not* lists of authors

* Acme::CPANAuthors::Factory - a utility module
* Acme::CPANAuthors::Register
* Acme::CPANAuthors::Utils
* Acme::CPANAuthors::Utils::Authors
* Acme::CPANAuthors::Utils::CPANIndex
* Acme::CPANAuthors::Utils::Kwalitee
* Acme::CPANAuthors::Utils::Packages

_
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of Acme::CPANAUthors::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CPANAuthors - List of Acme::CPANAUthors::* modules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CPANAuthors (from Perl distribution Acme-CPANModules-CPANAuthors), released on 2023-11-28.

=head1 DESCRIPTION

This list tries to catalog and categorize all the existing Acme::CPANAuthors::*
modules.

=head2 Geographical

=over

=item * L<Acme::CPANAuthors::Australian>

=item * L<Acme::CPANAuthors::Austrian>

=item * L<Acme::CPANAuthors::Belarusian>

=item * L<Acme::CPANAuthors::Brazilian>

=item * L<Acme::CPANAuthors::British>

=item * L<Acme::CPANAuthors::British::Companies>

=item * L<Acme::CPANAuthors::Canadian>

=item * L<Acme::CPANAuthors::Catalonian>

=item * L<Acme::CPANAuthors::Chinese>

=item * L<Acme::CPANAuthors::Czech>

=item * L<Acme::CPANAuthors::Danish>

=item * L<Acme::CPANAuthors::Dutch>

=item * L<Acme::CPANAuthors::EU> - alias for ::European

=item * L<Acme::CPANAuthors::European>

=item * L<Acme::CPANAuthors::French>

=item * L<Acme::CPANAuthors::German>

=item * L<Acme::CPANAuthors::Icelandic>

=item * L<Acme::CPANAuthors::India>

=item * L<Acme::CPANAuthors::Indonesian>

=item * L<Acme::CPANAuthors::Israeli>

=item * L<Acme::CPANAuthors::Japanese>

=item * L<Acme::CPANAuthors::Korean>

=item * L<Acme::CPANAuthors::Malaysian>

=item * L<Acme::CPANAuthors::Norwegian>

=item * L<Acme::CPANAuthors::Polish>

=item * L<Acme::CPANAuthors::Portuguese>

=item * L<Acme::CPANAuthors::Russian>

=item * L<Acme::CPANAuthors::Slovak>

=item * L<Acme::CPANAuthors::Spanish>

=item * L<Acme::CPANAuthors::Swedish>

=item * L<Acme::CPANAuthors::Taiwanese>

=item * L<Acme::CPANAuthors::Turkish>

=back

=head2 CPAN-related

=over

=item * L<Acme::CPANAuthors::BackPAN::OneHundred>

=item * L<Acme::CPANAuthors::CPAN::MostScripts>

=item * L<Acme::CPANAuthors::CPAN::OneHundred>

=item * L<Acme::CPANAuthors::CPAN::Streaks::DailyDistributions>

=item * L<Acme::CPANAuthors::CPAN::Streaks::DailyNewDistributions>

=item * L<Acme::CPANAuthors::CPAN::Streaks::DailyReleases>

=item * L<Acme::CPANAuthors::CPAN::Streaks::WeeklyDistributions>

=item * L<Acme::CPANAuthors::CPAN::Streaks::WeeklyNewDistributions>

=item * L<Acme::CPANAuthors::CPAN::Streaks::WeeklyReleases>

=item * L<Acme::CPANAuthors::CPAN::Streaks::MonthlyDistributions>

=item * L<Acme::CPANAuthors::CPAN::Streaks::MonthlyNewDistributions>

=item * L<Acme::CPANAuthors::CPAN::Streaks::MonthlyReleases>

=item * L<Acme::CPANAuthors::CPAN::TopDepended>

=item * L<Acme::CPANAuthors::CPAN::TopDepended::ByOthers>

=item * L<Acme::CPANAuthors::CPANTS::FiveOrMore>

=back

=head2 Perl-related

=over

=item * L<Acme::CPANAuthors::Pumpkings>

=back

=head2 Module-related

=over

=item * L<Acme::CPANAuthors::AnyEvent>

=item * L<Acme::CPANAuthors::DualLife> - authors of dual-life core modules (modules that are included in perl distribution as well as get released separately)

=item * L<Acme::CPANAuthors::MetaSyntactic>

=item * L<Acme::CPANAuthors::POE>

=item * L<Acme::CPANAuthors::ToBeLike>

=back

=head2 (Non-CPAN) project-related

=over

=item * L<Acme::CPANAuthors::DebianDev>

=back

=head2 Service-related

=over

=item * L<Acme::CPANAuthors::GitHub> - authors with github repositories

=back

=head2 Deceased authors

=over

=item * L<Acme::CPANAuthors::InMemoriam>

=back

=head2 Defunct

=over

=item * L<Acme::CPANAuthors::CodeRepos> - authors using LL<https://coderepos.org/>, a now-defunct service

=back

=head2 Others

=over

=item * L<Acme::CPANAuthors::GeekHouse> - authors who have visited The Geek House ever

=item * L<Acme::CPANAuthors::MBTI> - authors by MBTI types

=item * L<Acme::CPANAuthors::MBTI::INTP> - authors with "INTP" personality type

=item * L<Acme::CPANAuthors::Misanthrope> - authors who see into your soul with perfect clarity

=item * L<Acme::CPANAuthors::Nonhuman>

=item * L<Acme::CPANAuthors::Not>

=item * L<Acme::CPANAuthors::You::re_using>

=back

=head2 I<Not> lists of authors

=over

=item * Acme::CPANAuthors::Factory - a utility module

=item * Acme::CPANAuthors::Register

=item * Acme::CPANAuthors::Utils

=item * Acme::CPANAuthors::Utils::Authors

=item * Acme::CPANAuthors::Utils::CPANIndex

=item * Acme::CPANAuthors::Utils::Kwalitee

=item * Acme::CPANAuthors::Utils::Packages

=back

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Acme::CPANAuthors::Australian>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<Acme::CPANAuthors::Austrian>

Author: L<GORTAN|https://metacpan.org/author/GORTAN>

=item L<Acme::CPANAuthors::Belarusian>

Author: L<SROMANOV|https://metacpan.org/author/SROMANOV>

=item L<Acme::CPANAuthors::Brazilian>

Author: L<GARU|https://metacpan.org/author/GARU>

=item L<Acme::CPANAuthors::British>

Author: L<BARBIE|https://metacpan.org/author/BARBIE>

=item L<Acme::CPANAuthors::British::Companies>

Author: L<BARBIE|https://metacpan.org/author/BARBIE>

=item L<Acme::CPANAuthors::Canadian>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<Acme::CPANAuthors::Catalonian>

Author: L<ALEXM|https://metacpan.org/author/ALEXM>

=item L<Acme::CPANAuthors::Chinese>

Author: L<FAYLAND|https://metacpan.org/author/FAYLAND>

=item L<Acme::CPANAuthors::Czech>

Author: L<SKIM|https://metacpan.org/author/SKIM>

=item L<Acme::CPANAuthors::Danish>

Author: L<KAARE|https://metacpan.org/author/KAARE>

=item L<Acme::CPANAuthors::Dutch>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item L<Acme::CPANAuthors::EU>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item L<Acme::CPANAuthors::European>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item L<Acme::CPANAuthors::French>

Author: L<SAPER|https://metacpan.org/author/SAPER>

=item L<Acme::CPANAuthors::German>

Author: L<RBO|https://metacpan.org/author/RBO>

=item L<Acme::CPANAuthors::Icelandic>

Author: L<HINRIK|https://metacpan.org/author/HINRIK>

=item L<Acme::CPANAuthors::India>

Author: L<SHANTANU|https://metacpan.org/author/SHANTANU>

=item L<Acme::CPANAuthors::Indonesian>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::Israeli>

Author: L<SHLOMIF|https://metacpan.org/author/SHLOMIF>

=item L<Acme::CPANAuthors::Japanese>

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item L<Acme::CPANAuthors::Korean>

Author: L<JEEN|https://metacpan.org/author/JEEN>

=item L<Acme::CPANAuthors::Malaysian>

Author: L<KIANMENG|https://metacpan.org/author/KIANMENG>

=item L<Acme::CPANAuthors::Norwegian>

Author: L<SHARIFULN|https://metacpan.org/author/SHARIFULN>

=item L<Acme::CPANAuthors::Polish>

Author: L<BRTASTIC|https://metacpan.org/author/BRTASTIC>

=item L<Acme::CPANAuthors::Portuguese>

Author: L<BRACETA|https://metacpan.org/author/BRACETA>

=item L<Acme::CPANAuthors::Russian>

Author: L<SHARIFULN|https://metacpan.org/author/SHARIFULN>

=item L<Acme::CPANAuthors::Slovak>

Author: L<SKIM|https://metacpan.org/author/SKIM>

=item L<Acme::CPANAuthors::Spanish>

Author: L<ALEXM|https://metacpan.org/author/ALEXM>

=item L<Acme::CPANAuthors::Swedish>

Author: L<WOLDRICH|https://metacpan.org/author/WOLDRICH>

=item L<Acme::CPANAuthors::Taiwanese>

Author: L<GUGOD|https://metacpan.org/author/GUGOD>

=item L<Acme::CPANAuthors::Turkish>

Author: L<BURAK|https://metacpan.org/author/BURAK>

=item L<Acme::CPANAuthors::BackPAN::OneHundred>

Author: L<BARBIE|https://metacpan.org/author/BARBIE>

=item L<Acme::CPANAuthors::CPAN::MostScripts>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::OneHundred>

Author: L<BARBIE|https://metacpan.org/author/BARBIE>

=item L<Acme::CPANAuthors::CPAN::Streaks::DailyDistributions>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::DailyNewDistributions>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::DailyReleases>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::WeeklyDistributions>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::WeeklyNewDistributions>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::WeeklyReleases>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::MonthlyDistributions>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::MonthlyNewDistributions>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::Streaks::MonthlyReleases>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::TopDepended>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPAN::TopDepended::ByOthers>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANAuthors::CPANTS::FiveOrMore>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item L<Acme::CPANAuthors::Pumpkings>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item L<Acme::CPANAuthors::AnyEvent>

Author: L<MONS|https://metacpan.org/author/MONS>

=item L<Acme::CPANAuthors::DualLife>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item L<Acme::CPANAuthors::MetaSyntactic>

Author: L<BOOK|https://metacpan.org/author/BOOK>

=item L<Acme::CPANAuthors::POE>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item L<Acme::CPANAuthors::ToBeLike>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item L<Acme::CPANAuthors::DebianDev>

Author: L<BOOK|https://metacpan.org/author/BOOK>

=item L<Acme::CPANAuthors::GitHub>

Author: L<GRAY|https://metacpan.org/author/GRAY>

=item L<Acme::CPANAuthors::InMemoriam>

Author: L<BARBIE|https://metacpan.org/author/BARBIE>

=item L<Acme::CPANAuthors::CodeRepos>

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item L<Acme::CPANAuthors::GeekHouse>

Author: L<KENTARO|https://metacpan.org/author/KENTARO>

=item L<Acme::CPANAuthors::MBTI>

Author: L<KENTNL|https://metacpan.org/author/KENTNL>

=item L<Acme::CPANAuthors::MBTI::INTP>

Author: L<KENTNL|https://metacpan.org/author/KENTNL>

=item L<Acme::CPANAuthors::Misanthrope>

Author: L<ASHLEY|https://metacpan.org/author/ASHLEY>

=item L<Acme::CPANAuthors::Nonhuman>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<Acme::CPANAuthors::Not>

Author: L<SFINK|https://metacpan.org/author/SFINK>

=item L<Acme::CPANAuthors::You::re_using>

Author: L<VPIT|https://metacpan.org/author/VPIT>

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

 % cpanm-cpanmodules -n CPANAuthors

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CPANAuthors | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CPANAuthors -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CPANAuthors -E'say $_->{module} for @{ $Acme::CPANModules::CPANAuthors::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CPANAuthors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CPANAuthors>.

=head1 SEE ALSO

L<Acme::CPANAuthors> itself lists many of the existing Acme::CPANAuthors::*
modules though not updated as often.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CPANAuthors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
