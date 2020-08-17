package Acme::CPANModules::Roles;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-04'; # DATE
our $DIST = 'Acme-CPANModules-Roles'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => "Doing roles with Perl",
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
# ABSTRACT: Doing roles with Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Roles - Doing roles with Perl

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Roles (from Perl distribution Acme-CPANModules-Roles), released on 2020-05-04.

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

=head1 INCLUDED MODULES

=over

=item * L<Role::Tiny>

=item * L<Moo::Role>

=item * L<Moo>

=item * L<Role::Basic>

=item * L<Mouse::Role>

=item * L<Mouse>

=item * L<Moose::Role>

=item * L<Moose>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries Roles | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Roles -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Roles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Roles>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Roles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
