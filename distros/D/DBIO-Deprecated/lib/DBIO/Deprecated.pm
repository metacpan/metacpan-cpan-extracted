package DBIO::Deprecated;
our $VERSION = '0.900004';
# ABSTRACT: Registry of CPAN redirect stubs for renamed/retired DBIO modules

use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Deprecated - Registry of CPAN redirect stubs for renamed/retired DBIO modules

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Deprecated> is the permanent home for "tombstone" redirect stub
modules: when a DBIO module gets renamed or retired, the old module name
stays indexed on PAUSE forever against the last release that shipped it --
PAUSE has no delete. Anyone still running C<cpanm Old::Module::Name> would
keep installing that stale, superseded code with no hint a replacement
exists.

This is not only a cross-distribution problem. PAUSE indexes per B<module
name>, not per distribution: it resolves each module name to whichever
shipped release -- of any distribution, including a later release of the
I<same> one -- carries the highest C<$VERSION> for that name. A module that
moves to a different CPAN distribution orphans its old name exactly the same
way a module that is renamed or deleted within its own distribution's later
releases does: either way, the old name simply stops appearing in anything
newer, and PAUSE keeps pointing at the last release that had it.

This distribution fixes that with the standard CPAN redirect-takeover
pattern: it ships a small stub package under the OLD module name and is
released at a version strictly higher than the last CPAN release that
shipped that name. PAUSE then indexes I<this> distribution as canonical for
the old name. The deciding version is this distribution's own release
version, not a literal hand-written into the stub -- see L</HOW THE TAKEOVER
WORKS>. The stub does nothing at runtime except C<die> immediately on
load -- naming the replacement module and distribution when there is one, or
saying plainly that the module was removed with no replacement -- so
C<cpanm Old::Module::Name> (or a cpanfile pinning it) now installs a clear,
actionable message instead of silently reinstalling dead code.

This dist itself (C<DBIO::Deprecated>, this module) has no runtime behaviour
of its own -- it is a documentation landing page and the dzil main module.
Each tombstone module is self-contained and carries no dependency on DBIO
core.

For the step-by-step procedure to add a new tombstone when a future rename
or removal happens -- including how to audit the family for orphaned module
names -- see the C<dbio-deprecated> skill
(C<.claude/skills/dbio-deprecated/SKILL.md> in this repo; packaged into the
sharedir at build time).

=head1 HOW THE TAKEOVER WORKS

What decides the takeover is the release version of B<this distribution> --
not the C<$VERSION> literal written into an individual tombstone file.

C<DBIO-Deprecated> is a non-core dist, so C<[@DBIO]>
(L<Dist::Zilla::PluginBundle::DBIO>) builds it through
C<@Git::VersionManager> with C<RewriteVersion::Transitional> configured
C<global = 1> and finder C<[:InstallModules]>. That finder covers every
shipped module, so the dist version is stamped into all of them at build
time: a hand-written literal in a tombstone is B<overwritten>, and a
tombstone with no C<$VERSION> line at all has one B<inserted>. The literal
is a record, not a lever -- editing it up or down changes nothing about what
is released.

What PAUSE reads is the C<provides> block of the built C<META>. That block
comes from C<MetaProvides::Package>, which runs with C<inherit_version = 1>
(its default): every package in the dist is listed at the B<distribution's>
version, whatever its file says. Both paths agree, and both name the same
number.

That distribution version comes from the C<$VERSION> literal in this module,
F<lib/DBIO/Deprecated.pm> (the bundle's fallback provider being
C<Git::NextVersion>) -- the one version in this dist that is maintained
deliberately. It is kept in step with the coordinated family release
version; the per-module numbers are stamped in bulk and are never computed
per tombstone.

=head2 The operating rule when adding a tombstone

For the tombstones already shipped here, nothing is left to defend against:
none of the old names exists in its origin distribution's current HEAD any
more, and two of those distributions (C<DBIO-MySQL-Async>,
C<DBIO-PostgreSQL-Async>) no longer exist as repositories at all. A later
release of an origin distribution cannot re-claim a name it no longer ships,
so an existing tombstone here cannot be overtaken. (A name that comes back
live in another dist is the one exception: it must lose its tombstone, and
F<t/03-no-live-collision.t> fails when that happens.)

The risk is a B<new> tombstone. It inherits whatever version this
distribution is released at, so if C<DBIO-Deprecated> lags behind the
family, that version can be B<lower> than the origin distribution's release
that last shipped the orphaned name -- and the takeover then fails silently:
the build is clean, the tests pass, and PAUSE simply keeps pointing at the
stale code.

So when adding a tombstone: establish the origin release (recorded in each
tombstone's C<$VERSION> comment, and in the table below) and check that the
B<next release version of this distribution> is strictly higher than it. If
it is not, raise this distribution's version -- writing a bigger number into
the stub does not help, because the build overwrites it.

=head1 CURRENT TOMBSTONES

  Old module                                       Redirects to                                New distribution
  --------------------------------------------------------------------------------------------------------------------------
  From dbio-mysql-ev (old dist DBIO-MySQL-Async, last released 0.900000):
  DBIO::MySQL::Async                                DBIO::MySQL::EV                              DBIO-MySQL-EV
  DBIO::MySQL::Async::Pool                          DBIO::MySQL::EV::Pool                         DBIO-MySQL-EV
  DBIO::MySQL::Async::QueryExecutor                 DBIO::MySQL::EV::QueryExecutor                DBIO-MySQL-EV
  DBIO::MySQL::Async::Storage                       DBIO::MySQL::EV::Storage                      DBIO-MySQL-EV
  DBIO::MySQL::Async::TransactionContext            DBIO::MySQL::EV::TransactionContext           DBIO-MySQL-EV

  From dbio-postgresql-ev (old dist DBIO-PostgreSQL-Async, last released 0.900000):
  DBIO::PostgreSQL::Async                           DBIO::PostgreSQL::EV                          DBIO-PostgreSQL-EV
  DBIO::PostgreSQL::Async::ConnectInfo              DBIO::PostgreSQL::EV::ConnectInfo             DBIO-PostgreSQL-EV
  DBIO::PostgreSQL::Async::Pool                     DBIO::PostgreSQL::EV::Pool                    DBIO-PostgreSQL-EV
  DBIO::PostgreSQL::Async::Storage                  DBIO::PostgreSQL::EV::Storage                 DBIO-PostgreSQL-EV
  DBIO::PostgreSQL::Async::TransactionContext       DBIO::PostgreSQL::EV::TransactionContext      DBIO-PostgreSQL-EV

  From dbio core (dist DBIO, last released with these names 0.900000):
  DBIO::StartupCheck                                (removed, no replacement)                     --
  DBIO::Schema::Versioned                           (removed, no replacement)                     --

  From dbio core (dist DBIO, last released with these names 0.900002):
  DBIO::Version                                     (removed, no replacement)                     --
  DBIO::Version::Table                              (removed, no replacement)                     --
  DBIO::ResultSourceHandle                          (removed, no replacement)                     --

  From dbio-dzil (dist Dist-Zilla-PluginBundle-DBIO, same-distribution rename, last released 0.900001):
  Dist::Zilla::Plugin::DBIO::SetCopyrightHolder     Dist::Zilla::Plugin::DBIO::SetMeta            Dist-Zilla-PluginBundle-DBIO

=head1 SEE ALSO

L<DBIO::MySQL::EV>, L<DBIO::PostgreSQL::EV>, L<DBIO::DeploymentHandler>,
L<Dist::Zilla::Plugin::DBIO::SetMeta>, L<DBIO>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
