package Acme::CPANModules::RequireHooks;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-08'; # DATE
our $DIST = 'Acme-CPANModules-RequireHooks'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of modules that utilize require() hook',
    description => <<'_',

This list tries to catalog all modules that utilize or provide `require()`
hook(s) to do various things.


**Blocking/filtering module loading**

<pm:Require::Hook::Noop>

<pm:lib::filter>


**Fetching module source from CPAN automatically upon use**

<pm:CPAN::AutoINC>

<pm:lib::xi>

<pm:Module::AutoINC>


**Fetching module source from alternative sources**

<pm:Require::HookChain::source::metacpan>

<pm:Require::Hook::Source::MetaCPAN>

<pm:Require::HookChain::source::dzil_build>

<pm:Require::Hook::Source::DzilBuild>


**Frameworks**

<pm:Require::Hook>

<pm:Require::HookChain>


**Logging**

<pm:Require::HookChain::log::stderr>

<pm:Require::HookChain::log::logger>


**Munging loaded source code**

<pm:Require::Hook::More>

<pm:Require::HookChain::munge::prepend>


**Packing dependencies**

<pm:App::FatPacker>

<pm:Module::FatPack>

<pm:Module::DataPack>

<pm:App::depak>


**Tracing dependencies**

<pm:App::tracepm>


_
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description();

1;
# ABSTRACT: List of modules that utilize require() hook

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RequireHooks - List of modules that utilize require() hook

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::RequireHooks (from Perl distribution Acme-CPANModules-RequireHooks), released on 2023-02-08.

=head1 DESCRIPTION

This list tries to catalog all modules that utilize or provide C<require()>
hook(s) to do various things.

B<Blocking/filtering module loading>

L<Require::Hook::Noop>

L<lib::filter>

B<Fetching module source from CPAN automatically upon use>

L<CPAN::AutoINC>

L<lib::xi>

L<Module::AutoINC>

B<Fetching module source from alternative sources>

L<Require::HookChain::source::metacpan>

L<Require::Hook::Source::MetaCPAN>

L<Require::HookChain::source::dzil_build>

L<Require::Hook::Source::DzilBuild>

B<Frameworks>

L<Require::Hook>

L<Require::HookChain>

B<Logging>

L<Require::HookChain::log::stderr>

L<Require::HookChain::log::logger>

B<Munging loaded source code>

L<Require::Hook::More>

L<Require::HookChain::munge::prepend>

B<Packing dependencies>

L<App::FatPacker>

L<Module::FatPack>

L<Module::DataPack>

L<App::depak>

B<Tracing dependencies>

L<App::tracepm>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Require::Hook::Noop>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<lib::filter>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<CPAN::AutoINC>

Author: L<DONS|https://metacpan.org/author/DONS>

=item L<lib::xi>

Author: L<GFUJI|https://metacpan.org/author/GFUJI>

=item L<Module::AutoINC>

Author: L<MACKENZIE|https://metacpan.org/author/MACKENZIE>

=item L<Require::HookChain::source::metacpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::Hook::Source::MetaCPAN>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain::source::dzil_build>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::Hook::Source::DzilBuild>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::Hook>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain::log::stderr>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain::log::logger>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::Hook::More>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Require::HookChain::munge::prepend>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::FatPacker>

Author: L<MSTROUT|https://metacpan.org/author/MSTROUT>

=item L<Module::FatPack>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Module::DataPack>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::depak>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::tracepm>

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

 % cpanm-cpanmodules -n RequireHooks

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RequireHooks | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RequireHooks -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RequireHooks -E'say $_->{module} for @{ $Acme::CPANModules::RequireHooks::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RequireHooks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RequireHooks>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RequireHooks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
