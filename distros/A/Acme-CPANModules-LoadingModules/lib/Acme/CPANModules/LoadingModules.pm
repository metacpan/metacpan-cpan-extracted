package Acme::CPANModules::LoadingModules;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'Acme-CPANModules-LoadingModules'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'MARKDOWN';

**Basics**

<pm:Module::Load> is basically just a thin wrapper over Perl's builtin
`require()` to translate between module name and path name, since the
traditional behavior of `require()` is to expect module name in bareword form
but path name in string form. This confusion will likely be fixed in future perl
versions. For example, see PPC 0006 [1].

[1] <https://github.com/Perl/PPCs/blob/main/ppcs/ppc0006-load-module.md>


**Installing modules automatically on demand**

Since Perl provides require hooks, one can trap the module loading process and
check for an uninstalled module and attempt to install it automatically on
demand when a code wants to load that module. Probably not suitable for use in
production. See separate list: <pm:Acme::CPANModule::ModuleAutoinstallers>.


**Loading module on demand**

Aside from require hook, Perl also provides the AUTOLOAD mechanism (see
`perlsub` documentation for more details). This lets you catch unknown function
being called and lets you attempt to load a module that might provide that
function. It is not exactly "loading modules on demand" but close enough for a
lot of cases. See separate list: <pm:Acme::CPANModule::ModuleAutoloaders>.


**Loading multiple modules at once**

<pm:all> requires all packages under a namespace. It will search the filesystem
for installed module source files under a specified namespace and load them all.

<pm:lib::require::all> loads all modules in a directory.


**Logging module loading**

<pm:Require::HookChain::log::logger>

<pm:Require::HookChain::log::stderr>


**Preventing loading certain modules**

<pm:lib::filter>, <pm:lib::disallow>


**Require hook frameworks**

These frameworks let you create require hook more easily.

<pm:Require::Hook>

<pm:Require::Hook::More>

<pm:Require::HookChain>


**Specifying relative paths**

<pm:lib::relative>

MARKDOWN

our $LIST = {
    summary => 'List of modules to load other Perl modules',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to load other Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::LoadingModules - List of modules to load other Perl modules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::LoadingModules (from Perl distribution Acme-CPANModules-LoadingModules), released on 2023-11-20.

=head1 DESCRIPTION

B<Basics>

L<Module::Load> is basically just a thin wrapper over Perl's builtin
C<require()> to translate between module name and path name, since the
traditional behavior of C<require()> is to expect module name in bareword form
but path name in string form. This confusion will likely be fixed in future perl
versions. For example, see PPC 0006 [1].

[1] L<https://github.com/Perl/PPCs/blob/main/ppcs/ppc0006-load-module.md>

B<Installing modules automatically on demand>

Since Perl provides require hooks, one can trap the module loading process and
check for an uninstalled module and attempt to install it automatically on
demand when a code wants to load that module. Probably not suitable for use in
production. See separate list: L<Acme::CPANModule::ModuleAutoinstallers>.

B<Loading module on demand>

Aside from require hook, Perl also provides the AUTOLOAD mechanism (see
C<perlsub> documentation for more details). This lets you catch unknown function
being called and lets you attempt to load a module that might provide that
function. It is not exactly "loading modules on demand" but close enough for a
lot of cases. See separate list: L<Acme::CPANModule::ModuleAutoloaders>.

B<Loading multiple modules at once>

L<all> requires all packages under a namespace. It will search the filesystem
for installed module source files under a specified namespace and load them all.

L<lib::require::all> loads all modules in a directory.

B<Logging module loading>

L<Require::HookChain::log::logger>

L<Require::HookChain::log::stderr>

B<Preventing loading certain modules>

L<lib::filter>, L<lib::disallow>

B<Require hook frameworks>

These frameworks let you create require hook more easily.

L<Require::Hook>

L<Require::Hook::More>

L<Require::HookChain>

B<Specifying relative paths>

L<lib::relative>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Module::Load>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item L<Acme::CPANModule::ModuleAutoinstallers>

=item L<Acme::CPANModule::ModuleAutoloaders>

=item L<all>

Author: L<DEXTER|https://metacpan.org/author/DEXTER>

=item L<lib::require::all>

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

=item L<Require::HookChain::log::logger>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain::log::stderr>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<lib::filter>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<lib::disallow>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::Hook>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::Hook::More>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<lib::relative>

Author: L<DBOOK|https://metacpan.org/author/DBOOK>

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

 % cpanm-cpanmodules -n LoadingModules

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries LoadingModules | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=LoadingModules -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::LoadingModules -E'say $_->{module} for @{ $Acme::CPANModules::LoadingModules::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-LoadingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-LoadingModules>.

=head1 SEE ALSO

L<Acme::CPANModules::ModuleAutoinstallers>

L<Acme::CPANModules::ModuleAutoloaders>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-LoadingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
