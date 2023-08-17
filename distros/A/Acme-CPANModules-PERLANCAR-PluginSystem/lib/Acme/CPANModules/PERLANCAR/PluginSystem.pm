package Acme::CPANModules::PERLANCAR::PluginSystem;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-23'; # DATE
our $DIST = 'Acme-CPANModules-PERLANCAR-PluginSystem'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of my modules/frameworks which use a particular plugin system style',
    description => <<'_',

This is a personal list of my modules/frameworks which use a particular plugin
system style which I will someday extract into its own framework
(<pm:Plugin::System>). (And I am also slowly converting more of my
plugin-supporting projects to use this style). Some of the features of this
particular plugin style:

* a plugin can be installed more than once and parameterized (like in <pm:Dist::Zilla> or <pm:Pod::Weaver>) [flexibility];
* execution order of plugins is by priority, then by its order of activation;
* a plugin has a default priority value but the value can be overriden by user [flexibility];
* a plugin has a default event in which it participates, but user can overrides this [flexibility];
* support for repeating an event [flexibility];
* support for skipping (aborting) an event [flexibility];

_
    entries => [

        {
            module => 'Plugin::System',
            description => <<'_',

The current name of what the plugin system will be refactored into.

_
        },

        {
            module => "ScriptX",
            description => <<'_',

Started in late 2019, this is the first framework where the I thought out the
rough feature set that I want. ScriptX was written to eventually replace
<pm:Perinci::CmdLine>: I want a framework that can be used to write web
scripts/form handlers as well as CLI scripts, with more flexibility in composing
behavior/functionality (i.e. plugin-based). But turns out I haven't had enough
time to hack on it, and making CLI scripts are 99% of what I use Perl for; thus
Perinci::CmdLine lives on for now (with plugins since 1.900).

_
        },

        {
            module => "Perinci::CmdLine::Lite",
            description => <<'_',

While waiting for <pm:ScriptX> to get into a usable form, I implemented a
similar system to my CLI framework, <pm:Perinci::CmdLine> starting from 1.900
(released in Oct 2020).

_
        },

        {
            module => "Require::HookPlugin",
            description => <<'_',

Another project where I implemented the same plugin system to a require hook
framework. Require::HookPlugin (RHP) was started in July 2023 because I found
hook ordering in <pm:Require::HookChain> (RHC) to be fragile and error-prone.
Plus, I want more customizability and composability than what RHC provides.

_
        },

    ],
};

1;
# ABSTRACT: List of my modules/frameworks which use a particular plugin system style

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::PluginSystem - List of my modules/frameworks which use a particular plugin system style

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::PluginSystem (from Perl distribution Acme-CPANModules-PERLANCAR-PluginSystem), released on 2023-07-23.

=head1 DESCRIPTION

This is a personal list of my modules/frameworks which use a particular plugin
system style which I will someday extract into its own framework
(L<Plugin::System>). (And I am also slowly converting more of my
plugin-supporting projects to use this style). Some of the features of this
particular plugin style:

=over

=item * a plugin can be installed more than once and parameterized (like in L<Dist::Zilla> or L<Pod::Weaver>) [flexibility];

=item * execution order of plugins is by priority, then by its order of activation;

=item * a plugin has a default priority value but the value can be overriden by user [flexibility];

=item * a plugin has a default event in which it participates, but user can overrides this [flexibility];

=item * support for repeating an event [flexibility];

=item * support for skipping (aborting) an event [flexibility];

=back

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Plugin::System>

The current name of what the plugin system will be refactored into.


=item L<ScriptX>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Started in late 2019, this is the first framework where the I thought out the
rough feature set that I want. ScriptX was written to eventually replace
L<Perinci::CmdLine>: I want a framework that can be used to write web
scripts/form handlers as well as CLI scripts, with more flexibility in composing
behavior/functionality (i.e. plugin-based). But turns out I haven't had enough
time to hack on it, and making CLI scripts are 99% of what I use Perl for; thus
Perinci::CmdLine lives on for now (with plugins since 1.900).


=item L<Perinci::CmdLine::Lite>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

While waiting for L<ScriptX> to get into a usable form, I implemented a
similar system to my CLI framework, L<Perinci::CmdLine> starting from 1.900
(released in Oct 2020).


=item L<Require::HookPlugin>

Another project where I implemented the same plugin system to a require hook
framework. Require::HookPlugin (RHP) was started in July 2023 because I found
hook ordering in L<Require::HookChain> (RHC) to be fragile and error-prone.
Plus, I want more customizability and composability than what RHC provides.


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

 % cpanm-cpanmodules -n PERLANCAR::PluginSystem

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PERLANCAR::PluginSystem | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::PluginSystem -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::PluginSystem -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::PluginSystem::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-PluginSystem>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-PluginSystem>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PERLANCAR-PluginSystem>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
