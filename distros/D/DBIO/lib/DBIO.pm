package DBIO;
# ABSTRACT: Native relational mapping for Perl, built on DBI

use strict;
use warnings;

our $VERSION = '0.900001';

use DBIO::Base ();
use DBIO::Skills ();

sub import {
  my ($class, @args) = @_;
  my $caller = caller;

  my ($role, @opts);
  for my $arg (@args) {
    if (defined $arg && $arg =~ /^-/) { push @opts, $arg }
    elsif (!defined $role)            { $role = $arg }
    else                              { push @opts, $arg }
  }

  unless (defined $role) {
    if    ($caller =~ /::Result::[^:]+$/)    { $role = 'Core' }
    elsif ($caller =~ /::ResultSet::[^:]+$/) { $role = 'ResultSet' }
    else                                      { $role = 'Core' }
  }

  my $base = "DBIO::$role";
  eval "require $base; 1"
    or die "use DBIO '$role': cannot load $base: $@";

  {
    no strict 'refs';
    push @{"${caller}::ISA"}, $base unless $caller->isa($base);
  }

  strict->import;
  warnings->import;

  # Schema classes get the skills-override declaration sugar (see DBIO::Skills).
  _install_skill_sugar($caller) if $caller->isa('DBIO::Schema');

  _apply_shortcut($caller, $_) for @opts;
}

# Install the per-schema skills-override sugar into a schema class body:
#
#   skills { 'mysql-database' => $md, ... };   # set/replace the whole map
#   skill  'mysql-database' => $md;            # merge a single entry
#
# Both write the schema's skills() classdata (DBIO::Schema). namespace::clean
# removes the helpers after compilation, so at runtime $schema->skill(...) and
# $schema->skills resolve to the inherited DBIO::Schema accessor/method rather
# than these declaration helpers. The classdata accessor is reached via its
# fully-qualified name to bypass the (still-installed) sugar during the body.
sub _install_skill_sugar {
  my ($caller) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${caller}::skills"} = sub {
    my $map = (@_ == 1 && ref $_[0] eq 'HASH') ? $_[0] : { @_ };
    $caller->DBIO::Schema::skills($map);
  };
  *{"${caller}::skill"} = sub {
    my ($name, $markdown) = @_;
    my $cur = $caller->DBIO::Schema::skills || {};
    $caller->DBIO::Schema::skills({ %$cur, $name => $markdown });
  };
  require namespace::clean;
  namespace::clean->import(-cleanee => $caller, qw(skills skill));
}


sub skill { shift; DBIO::Skills->skill(@_) }


sub skills { shift; DBIO::Skills->skills(@_) }

# Shortcut resolution is two-tier and core never names a single driver:
#
#  1. Explicit stub DBIO::Shortcut::<key> -- a driver ships one for each
#     curated alias (e.g. -pg, -my). It is lazy-loaded here (so it works even
#     "cold") and its apply($caller) decides what to do, usually delegating to
#     DBIO->apply_driver:
#         package DBIO::Shortcut::pg;
#         sub apply { DBIO->apply_driver($_[1], 'PostgreSQL') }
#         1;
#
#  2. No stub? Fall back to an ALREADY-LOADED driver whose name matches the key
#     case-insensitively (-postgresql -> DBIO::PostgreSQL). The correct casing
#     comes from the loaded symbol table, not from guessing. This is why the
#     canonical name "just works" once the driver is loaded, with no stub.
sub _apply_shortcut {
  my ($caller, $opt) = @_;
  (my $key = lc $opt) =~ s/^-//;

  $key =~ /\A[a-z0-9_]+\z/
    or die "use DBIO: invalid shortcut '$opt'";

  my $stub = "DBIO::Shortcut::$key";
  if (eval { require "DBIO/Shortcut/$key.pm"; 1 }) {
    $stub->can('apply')
      or die "use DBIO $opt: $stub provides no apply() method";
    eval { $stub->apply($caller); 1 }
      or die "use DBIO $opt: $@";
    return;
  }
  my $stub_err = $@;
  die "use DBIO $opt: loading $stub failed: $stub_err"
    unless $stub_err =~ /\ACan't locate/;

  if (my $name = _loaded_driver_for($key)) {
    DBIO->apply_driver($caller, $name);
    return;
  }

  die "use DBIO $opt: unknown shortcut '$opt' (no $stub, and no loaded driver "
    . "named '$key' -- is the driver installed and loaded?)\n";
}

# Find an already-loaded driver whose namespace lower-cases to $key. A driver
# is a DBIO::<Name> main module whose DBIO::<Name>::Storage is loadable -- this
# guard keeps core classes (Core, Schema, ...) from ever matching.
sub _loaded_driver_for {
  my ($key) = @_;
  no strict 'refs';
  for my $ns (keys %{'DBIO::'}) {
    $ns =~ s/::$// or next;
    next unless lc $ns eq $key;
    next unless $INC{"DBIO/$ns.pm"};
    return $ns if eval { require "DBIO/$ns/Storage.pm"; 1 };
  }
  return undef;
}

# Apply a driver to a class by the DBIO::<Name>::{Storage,Result} convention:
# pin the storage driver on a Schema, load the Result component on a Result
# class (only if the driver ships one). Driver shortcut stubs delegate here.
sub apply_driver {
  my ($class, $caller, $name) = @_;
  if ($caller->isa('DBIO::Schema')) {
    $caller->storage_type("+DBIO::${name}::Storage");
  }
  elsif ($caller->isa('DBIO::Core')) {
    $caller->load_components("${name}::Result")
      if eval { require "DBIO/${name}/Result.pm"; 1 };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO - Native relational mapping for Perl, built on DBI

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

The classes shown below can also be generated from an existing database with
L<dbiogen>, powered by L<DBIO::Generate>.

=head2 Schema class

  package MyApp::Schema;
  use DBIO 'Schema';

  __PACKAGE__->load_namespaces();

  1;

=head2 Vanilla style (import sugar)

  package MyApp::Schema::Result::Artist;
  use DBIO;    # Role is auto-detected from the package name: Core

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artistid');

  1;

The classic equivalent (still supported):

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';
  ...

=head2 Candy style (import sugar)

L<DBIO::Candy> removes the C<< __PACKAGE__-> >> boilerplate:

  package MyApp::Schema::Result::Artist;
  use DBIO::Candy;

  table 'artist';
  column artistid => { data_type => 'int', is_auto_increment => 1 };
  primary_key 'artistid';
  column name => { data_type => 'varchar', size => 100 };
  has_many cds => 'MyApp::Schema::Result::CD', 'artistid';

  1;

=head2 Cake style (DDL-like DSL)

L<DBIO::Cake> provides type functions that read like DDL:

  package MyApp::Schema::Result::Artist;
  use DBIO::Cake;

  table 'artist';
  col artistid => integer, auto_inc;
  col name     => varchar(100);
  primary_key 'artistid';
  has_many cds => 'MyApp::Schema::Result::CD', 'artistid';

  1;

=head2 Using your schema

  use MyApp::Schema;
  my $schema = MyApp::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);

  my @all_artists = $schema->resultset('Artist')->all;

  my $johns_rs = $schema->resultset('Artist')->search(
    { name => { like => 'John%' } }
  );

  # Joins are automatic from relationship conditions
  my @rock_cds = $schema->resultset('CD')->search(
    { 'artist.name' => 'John Doe' }
  )->all;

  # Prefetch related data in a single query
  my $millennium_cds_rs = $schema->resultset('CD')->search(
    { year => 2000 },
    { prefetch => 'artist' }
  );

  my $cd = $millennium_cds_rs->next;
  my $artist_name = $cd->artist->name;  # no extra query

  # Create, update, delete
  my $new_cd = $schema->resultset('CD')->create({ title => 'Spoon' });
  $schema->txn_do(sub { $new_cd->update({ title => 'Fork' }) });
  $millennium_cds_rs->update({ year => 2002 });

See F<t/dbio_sugar_pragma.t> for a runnable example of the C<use DBIO>
import-sugar and role auto-detection shown above.

=head1 DESCRIPTION

DBIO (DBI Objects) is a relational mapper for Perl built on top of L<DBI>.
It combines an object model for rows and result classes with a resultset API
for building queries without giving up database-native behavior.

Three styles are available for defining result classes:
L<DBIO::Cake> (DDL-like DSL), L<DBIO::Candy> (import sugar), and the
classic Vanilla style (C<use DBIO;> or C<< use base 'DBIO::Core' >>).

Database-specific features are provided by native driver distributions
(L<DBIO::PostgreSQL>, L<DBIO::MySQL>, L<DBIO::SQLite>, etc.) that speak
each database's dialect natively.

Key features:

=over 4

=item * Automatic joins from relationship conditions

=item * Lazy ResultSets that only query when you ask for rows

=item * Prefetch for efficient eager loading

=item * Multi-column primary and foreign keys

=item * Database-level paging, driver-specific SQL features

=item * Three result class styles: Cake, Candy, Vanilla

=back

B<DBIO is pre-1.0.> The core API is substantial and usable, but some edges
are still being refined. Please report anything that looks wrong or surprising.

=head1 METHODS

=head2 skill

  my $markdown = DBIO->skill('postgresql-database');

Class-level shortcut for L<DBIO::Skills/skill>: returns the markdown text of
the named agent skill from whatever DBIO distributions are currently loaded,
or C<undef>. The leading C<dbio-> is optional.

=head2 skills

  my @names = DBIO->skills;

Class-level shortcut for L<DBIO::Skills/skills>: the sorted names of all skills
available from the currently loaded DBIO distributions.

=head1 USE-AS-PRAGMA

Since C<DBIO.pm> itself is a sugar pragma (analogous to C<Moose.pm>), it can
be used directly to declare a DBIO class. The role to inherit from is
auto-detected from the package name, or can be specified explicitly.

  package MyApp::Schema::Result::Artist;
  use DBIO;                    # -> @ISA = ('DBIO::Core')

  package MyApp::Schema::ResultSet::Artist;
  use DBIO;                    # -> @ISA = ('DBIO::ResultSet')

  package MyApp::Schema;
  use DBIO 'Schema';           # -> @ISA = ('DBIO::Schema')

  package MyApp::Schema::Result::Photo;
  use DBIO 'Core';             # explicit override

Shortcuts can be combined with role selection, separated by leading dashes.
A shortcut loads a driver's C<::Result> component:

  use DBIO -pg;                # Core + load the PostgreSQL::Result component
  use DBIO 'Schema', -pg;      # Schema + load the PostgreSQL::Result component

Shortcuts are owned by the driver distributions, not by core; core never names a
single driver. A shortcut resolves in two tiers:

=over 4

=item 1.

An explicit stub C<DBIO::Shortcut::E<lt>keyE<gt>>, which a driver ships for each
curated alias (C<-pg>, C<-my>, ...). Core lazy-loads it and calls its
C<apply($caller)>, which usually just delegates to C<DBIO-E<gt>apply_driver>:

  package DBIO::Shortcut::pg;
  sub apply { DBIO->apply_driver($_[1], 'PostgreSQL') }
  1;

=item 2.

If there is no stub, core falls back to an already-loaded driver whose name
matches the key case-insensitively -- so C<-postgresql> resolves to
C<DBIO::PostgreSQL> once that driver is loaded, with no stub needed.

=back

C<apply_driver($caller, $name)> applies the driver by convention: on a Schema it
pins C<storage_type('+DBIO::E<lt>nameE<gt>::Storage')>; on a Result class it
loads the C<E<lt>nameE<gt>::Result> component if the driver ships one. So every
driver gets a shortcut (the Schema path works for all), and a C<::Result>
component is just an extra. A shortcut that resolves to nothing dies with a
helpful message -- it only works when its driver is installed (and, for the
bare canonical name, loaded).

Role auto-detection rules:

=over 4

=item * package matches C<< /::Result::WORD$/ >> E<rarr> role C<Core>

=item * package matches C<< /::ResultSet::WORD$/ >> E<rarr> role C<ResultSet>

=item * anything else E<rarr> role C<Core> (the most common case)

=back

C<use DBIO;> additionally enables C<strict> and C<warnings> in the caller,
matching the behavior of L<DBIO::Candy>, L<DBIO::Cake>, L<DBIO::Moo> and
L<DBIO::Moose>.

=head1 WHERE TO START

See L<DBIO::Manual::DocMap> for the full documentation map. New users should
start with L<DBIO::Manual::QuickStart>.

=head1 HERITAGE

DBIO is a fork of L<DBIx::Class> with a clean namespace break. Key changes:

=over 4

=item * Namespace: C<DBIO::> replaces C<DBIx::Class::>

=item * L<SQL::Abstract> replaces L<SQL::Abstract::Classic>

=item * LIMIT/OFFSET via C<apply_limit> on the driver's SQLMaker instead of
string-based dialect dispatch

=item * L<SQL::Translator> has been removed; schema introspection, diff, and
deployment are handled by DB-specific native modules

=item * Shared utilities (L<DBIO::SQL::Util>) provide C<_quote_ident> and
C<_split_statement> for cross-driver use

=item * L<DBIx::Class::TimeStamp> and L<DBIx::Class::Helpers> functionality
integrated into core

=item * Native driver distributions for each database (L<DBIO::PostgreSQL>,
L<DBIO::MySQL>, L<DBIO::SQLite>, L<DBIO::DuckDB>) use desired-state
deployment via test-and-compare; extracted drivers
(L<DBIO::DB2>, L<DBIO::Firebird>, L<DBIO::Informix>, L<DBIO::MSSQL>,
L<DBIO::Oracle>, L<DBIO::Sybase>) follow the same pattern

=item * Meta-infrastructure has been split into L<DBIO::Base> (inherited by
all internal classes); C<DBIO.pm> is now a pure sugar pragma

=back

=head1 GETTING HELP

=over

=item * Codeberg Issues: L<https://codeberg.org/dbio/dbio/issues>

=item * IRC: C<#dbio> on C<irc.perl.org>

=back

=head1 CONTRIBUTING

Contributions are welcome: bug reports, documentation improvements, pull
requests, or patches.

=over

=item * Repository: L<https://codeberg.org/dbio/dbio>

=back

=head1 AUTHORS

DBIO is built on top of L<DBIx::Class>, which was a long-running collaborative
effort by many contributors. See the F<AUTHORS> file for the full list.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
