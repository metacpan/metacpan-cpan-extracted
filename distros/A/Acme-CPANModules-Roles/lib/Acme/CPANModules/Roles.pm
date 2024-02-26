package Acme::CPANModules::Roles;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-Roles'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of libraries for doing roles with Perl",
    description => <<'_',

Roles are a way to write classes by composing them from simpler components,
instead of using inheritance from parent classes.

The Perl core does not provide a role mechanism for you, but there are several
role frameworks you can choose in Perl. This list orders them from the most
lightweight.

<pm:Role::Tiny>. Basic role support plus method modifiers (`before`, `after`,
`around`).

<pm:Moo::Role>. Based on Role::Tiny, it adds attribute support. Suitable if you
use <pm:Moo> as your object system.

<pm:Role::Basic>. Despite having less features than Role::Tiny (no method
modifiers), Role::Basic starts a bit slower because it loads some more modules.

<pm:Mouse::Role>. Suitable only if you are already using <pm:Mouse> as your
object system.

<pm:Moose::Role>. Offers the most features (particularly the meta protocol), but
also the heaviest. Suitable only if you are already using <pm:Moose> as your
object system.
_
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of libraries for doing roles with Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Roles - List of libraries for doing roles with Perl

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::Roles (from Perl distribution Acme-CPANModules-Roles), released on 2023-10-31.

=head1 DESCRIPTION

Roles are a way to write classes by composing them from simpler components,
instead of using inheritance from parent classes.

The Perl core does not provide a role mechanism for you, but there are several
role frameworks you can choose in Perl. This list orders them from the most
lightweight.

L<Role::Tiny>. Basic role support plus method modifiers (C<before>, C<after>,
C<around>).

L<Moo::Role>. Based on Role::Tiny, it adds attribute support. Suitable if you
use L<Moo> as your object system.

L<Role::Basic>. Despite having less features than Role::Tiny (no method
modifiers), Role::Basic starts a bit slower because it loads some more modules.

L<Mouse::Role>. Suitable only if you are already using L<Mouse> as your
object system.

L<Moose::Role>. Offers the most features (particularly the meta protocol), but
also the heaviest. Suitable only if you are already using L<Moose> as your
object system.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Role::Tiny>

Author: L<HAARG|https://metacpan.org/author/HAARG>

=item L<Moo::Role>

Author: L<HAARG|https://metacpan.org/author/HAARG>

=item L<Moo>

Author: L<HAARG|https://metacpan.org/author/HAARG>

=item L<Role::Basic>

Author: L<OVID|https://metacpan.org/author/OVID>

=item L<Mouse::Role>

Author: L<SKAJI|https://metacpan.org/author/SKAJI>

=item L<Mouse>

Author: L<SKAJI|https://metacpan.org/author/SKAJI>

=item L<Moose::Role>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<Moose>

Author: L<ETHER|https://metacpan.org/author/ETHER>

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

 % cpanm-cpanmodules -n Roles

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Roles | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Roles -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Roles -E'say $_->{module} for @{ $Acme::CPANModules::Roles::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Roles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Roles>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Roles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
