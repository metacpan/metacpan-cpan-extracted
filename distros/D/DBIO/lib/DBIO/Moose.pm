package DBIO::Moose;
# ABSTRACT: Enable Moose attributes in DBIO result classes

use strict;
use warnings;

use DBIO::Util ();

sub import {
  my ($class) = @_;
  my $caller = caller;

  # Activate Moose + MooseX::NonMoose in the caller package.
  # MooseX::NonMoose provides the constructor bridge plumbing for
  # non-Moose base classes, but its default FOREIGNBUILDARGS passes
  # all args through — we install our own below to filter out pure
  # Moose attributes that DBIO::Row::new does not know about.
  eval "package $caller; use Moose; use MooseX::NonMoose; 1" or die $@;  ## no critic

  # Set up DBIO::Core as the base class via Moose's extends
  require DBIO::Core;
  unless ( $caller->isa('DBIO::Core') ) {
    eval "package $caller; extends 'DBIO::Core'; 1" or die $@;  ## no critic
  }

  # Override MooseX::NonMoose's default FOREIGNBUILDARGS with one that
  # filters pure-Moose attributes out of the DBIO constructor call.
  # We must register via the Moose metaclass (not just the glob) so that
  # make_immutable's inlined constructor sees our version, not the
  # MooseX::NonMoose pass-through that was installed earlier.
  $caller->meta->add_method( FOREIGNBUILDARGS => \&DBIO::Util::foreignbuildargs );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Moose - Enable Moose attributes in DBIO result classes

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use DBIO::Moose;
  use DBIO::Cake;

  table 'artists';

  col id   => serial;
  col name => varchar(100);

  primary_key 'id';

  # Moose attribute — lazy, computed from column data on first access
  has display_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_display_name',
  );
  sub _build_display_name { 'Artist: ' . $_[0]->name }

  # Moose attribute with a default — MUST be lazy (see L</The lazy requirement>)
  has score => (is => 'rw', isa => 'Int', lazy => 1, default => 0);

  __PACKAGE__->meta->make_immutable;
  1;

See F<t/moose.t> for a runnable example.

=head1 DESCRIPTION

C<DBIO::Moose> is a thin bridge that activates L<Moose> and
L<MooseX::NonMoose> in a DBIO result class so that Moose attributes and DBIO
columns coexist without conflict.

When you C<use DBIO::Moose>:

=over 4

=item * L<Moose> and L<MooseX::NonMoose> are activated in the calling package.

=item * L<DBIO::Core> is set as the base class via Moose's C<extends>.

=item * A custom C<FOREIGNBUILDARGS> method is installed that filters
constructor arguments so only DBIO-known keys reach C<DBIO::Row::new>. This
replaces C<MooseX::NonMoose>'s default pass-through implementation.

=back

Call C<< __PACKAGE__->meta->make_immutable >> at the end of your class
definition for full Moose optimization. It is safe to do so alongside DBIO.

=head2 The constructor problem

This section explains why plain C<use base> or C<extends> cannot work, and
why both C<MooseX::NonMoose> and a custom C<FOREIGNBUILDARGS> are required.

A DBIO result class's constructor is C<DBIO::Row::new>. It expects a single
hashref and calls C<store_column> for every key it receives. If it sees a key
that is not a declared column, relationship, or C<-> prefixed internal key, it
dies: C<< No such column 'score' in table 'artists' >>.

When you C<use Moose> and C<extends 'DBIO::Core'>, Moose generates a new
C<new()> in your class. The problem: B<Moose's generated C<new()> does not
know how to call a non-Moose parent's C<new()>>. Moose's construction protocol
(C<new_object>, C<BUILD>, attribute initializers) is entirely separate from
the non-Moose parent's constructor. Without explicit bridging, the non-Moose
parent constructor is never called, and the DBIO internals are never
initialized.

=head2 What MooseX::NonMoose provides

L<MooseX::NonMoose> is a Moose extension that adds non-Moose parent constructor
support. It works by overriding C<new()> in the generated metaclass to call
the non-Moose parent's C<new()> first, then Moose's own initialization. The
mechanism it uses mirrors Moo's: a method called C<FOREIGNBUILDARGS>.

Moose calls C<FOREIGNBUILDARGS> with the same arguments as C<new()> and passes
the return list to the non-Moose parent's C<new>. The default
C<FOREIGNBUILDARGS> installed by C<MooseX::NonMoose> is a pass-through: it
returns all args unchanged.

That default is wrong for DBIO. Passing C<< { name => 'X', score => 42 } >>
to C<DBIO::Row::new> causes C<store_column('score', 42)> to die because
C<score> is a Moose attribute, not a database column.

C<DBIO::Moose> installs a replacement C<FOREIGNBUILDARGS> that:

=over 4

=item 1. Normalizes args to a hashref.

=item 2. Looks up the result source to find declared columns and relationships.

=item 3. Forwards only DBIO-known keys (columns, relationships, C<-> prefixed
internals) to C<DBIO::Row::new>.

=item 4. Leaves pure Moose attributes out — Moose handles those itself via
attribute initialization.

=back

Note that C<DBIO::Moose> always installs C<FOREIGNBUILDARGS> unconditionally
(unlike C<DBIO::Moo>, which skips it if one already exists). This ensures the
filtering version replaces C<MooseX::NonMoose>'s pass-through default, which
has already been installed into the class by the time C<import> runs.

=head2 Two construction paths

Understanding the distinction between C<new()> and C<inflate_result> is
critical for using Moose attributes correctly.

=over 4

=item B<new()> — programmatic construction

Used by C<< $rs->create(...) >> and C<< $rs->new_result(...) >>. The
C<MooseX::NonMoose>-enhanced Moose constructor runs, calls
C<FOREIGNBUILDARGS> to get filtered args, calls C<DBIO::Row::new> with those
filtered args (setting up column data, result source, storage link), then
initializes Moose attributes.

=item B<inflate_result()> — construction from database rows

Used by every query: C<find>, C<search>, C<all>, etc. C<DBIO::Row::inflate_result>
blesses a pre-built hash directly into your class without going through
C<new()> at all:

  bless { _column_data => \%row, _result_source => $rsrc, ... }, $class;

Moose's constructor B<never runs>. Moose attributes are never initialized by
the constructor when a row is fetched from the database.

=back

=head2 The lazy requirement

Because C<inflate_result> bypasses C<new()>, Moose attributes on DB-fetched
rows have uninitialized internal slots. Non-lazy attributes with defaults are
normally set during Moose's C<new()> — but since C<new()> does not run, those
slots remain unset and reading them returns C<undef> instead of the default.

The solution is B<always declare defaults with C<lazy =E<gt> 1>>:

  # WRONG — default never applied to inflate_result rows
  has score => (is => 'rw', isa => 'Int', default => 0);

  # CORRECT — default computed on first access, works for both paths
  has score => (is => 'rw', isa => 'Int', lazy => 1, default => 0);

With C<lazy =E<gt> 1>, the default is evaluated the first time the accessor
is called, regardless of how the object was created. This applies to C<default>
and C<builder> alike. Attributes declared with C<builder> should also be
marked C<lazy =E<gt> 1> unless the build method does not depend on column data.

=head2 make_immutable and DBIO

Calling C<< __PACKAGE__->meta->make_immutable >> replaces the Moose-generated
C<new()> with a faster, inlined version. This is safe with DBIO because:

=over 4

=item * C<inflate_result> never calls C<new()> — make_immutable does not
affect the database-fetch path at all.

=item * The inlined C<new()> preserves the C<FOREIGNBUILDARGS> call added by
C<MooseX::NonMoose>, so DBIO initialization still happens correctly for
C<create> and C<new_result>.

=back

Always call C<make_immutable> at the end of your class definition, after all
C<has>, C<with>, and C<before/after/around> declarations, and after any
C<use DBIO::Cake> column declarations.

=head2 Moose roles

Moose roles applied with C<with> work normally. The role's C<requires> are
satisfied by either DBIO column accessors (they are plain subs installed in
the package) or other Moose attributes.

  with 'MyApp::Role::HasDisplayName';

  # or multiple roles at once:
  with 'MyApp::Role::HasDisplayName', 'MyApp::Role::Auditable';

Type constraints (C<isa>) in roles are enforced at object construction time and
on every mutation, as expected.

=head2 Manual setup without DBIO::Moose

If you prefer to wire things up yourself instead of using C<DBIO::Moose>, here
is exactly what C<use DBIO::Moose> does, spelled out explicitly:

  package MyApp::Schema::Result::Artist;

  # 1. Activate Moose and MooseX::NonMoose
  use Moose;
  use MooseX::NonMoose;

  # 2. Set DBIO::Core as the base class
  use DBIO::Core ();
  extends 'DBIO::Core';

  # 3. Override MooseX::NonMoose's pass-through FOREIGNBUILDARGS with a
  #    filtering version that keeps only DBIO-known keys
  sub FOREIGNBUILDARGS {
    my ($class, @args) = @_;

    my $attrs = ref $args[0] eq 'HASH' ? $args[0]
              : @args                   ? { @args }
              :                           {};

    my $rsrc = do { local $@; eval { $class->result_source_instance } };
    return ($attrs) unless $rsrc;

    my %dbio_args;
    for my $key (keys %$attrs) {
      if ($key =~ /^-/ || $rsrc->has_column($key) || $rsrc->has_relationship($key)) {
        $dbio_args{$key} = $attrs->{$key};
      }
    }
    return (\%dbio_args);
  }

  # 4. Now declare your columns and Moose attributes as normal
  use DBIO::Cake;

  table 'artists';
  col id   => serial;
  col name => varchar(100);
  primary_key 'id';

  has score => (is => 'rw', isa => 'Int', lazy => 1, default => 0);

  __PACKAGE__->meta->make_immutable;
  1;

B<Important>: If you use C<MooseX::NonMoose> without defining your own
C<FOREIGNBUILDARGS>, C<MooseX::NonMoose>'s default pass-through is used,
and C<DBIO::Row::new> will die on any Moose attribute key it receives.
You must override C<FOREIGNBUILDARGS> as shown above.

=head2 Historical context

The combination of Moose with a non-Moose ORM has a long history in the Perl
ecosystem. L<MooseX::NonMoose> was written specifically to handle this class
of problem. The DBIO::Moose design mirrors what L<DBIx::Class::Moo::ResultClass>
does for Moo (by ribasushi): install a filtering C<FOREIGNBUILDARGS> to separate
the ORM constructor arguments from the OO framework attributes.

The key insight: neither DBIO nor Moose is wrong. DBIO's C<store_column>
correctly rejects unknown keys — that is a feature, not a limitation. Moose
correctly passes all constructor arguments to attribute initializers — that is
also a feature. The role of C<FOREIGNBUILDARGS> is to stand between the two and
give each framework only the keys it owns.

=head2 Interaction with DBIO::Cake

C<DBIO::Cake> keywords (C<table>, C<col>, C<primary_key>, etc.) call
C<< __PACKAGE__->add_columns >>, C<< __PACKAGE__->set_primary_key >>, etc.
on the result class at compile time. This works correctly after C<use DBIO::Moose>
because C<DBIO::Core> is already in the inheritance chain when the keywords
run.

=head1 SEE ALSO

L<DBIO::Core>, L<DBIO::Cake>, L<DBIO::Moo>, L<Moose>, L<Moose::Role>,
L<MooseX::NonMoose>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
