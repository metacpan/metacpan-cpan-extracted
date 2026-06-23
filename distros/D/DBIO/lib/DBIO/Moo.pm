package DBIO::Moo;
# ABSTRACT: Enable Moo attributes in DBIO result classes

use strict;
use warnings;

use DBIO::Util ();

sub import {
  my ($class) = @_;
  my $caller = caller;

  # Activate Moo in the caller package
  eval "package $caller; use Moo; 1" or die $@;  ## no critic

  # Set up DBIO::Core as the base class via Moo's extends
  require DBIO::Core;
  unless ( $caller->isa('DBIO::Core') ) {
    eval "package $caller; extends 'DBIO::Core'; 1" or die $@;  ## no critic
  }

  # Install FOREIGNBUILDARGS to bridge Moo's new() and DBIO's new()
  # Without this, Moo does not call the non-Moo parent constructor at all.
  no strict 'refs';
  *{"${caller}::FOREIGNBUILDARGS"} = \&DBIO::Util::foreignbuildargs
    unless $caller->can('FOREIGNBUILDARGS');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Moo - Enable Moo attributes in DBIO result classes

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use DBIO::Moo;
  use DBIO::Cake;

  table 'artists';

  col id   => serial;
  col name => varchar(100);

  primary_key 'id';

  # Moo attribute — lazy, computed from column data on first access
  has display_name => (is => 'lazy');
  sub _build_display_name { 'Artist: ' . $_[0]->name }

  # Moo attribute with a default — MUST be lazy (see L</The lazy requirement>)
  has score => (is => 'rw', lazy => 1, default => sub { 0 });

  1;

=head1 DESCRIPTION

C<DBIO::Moo> is a thin bridge that activates L<Moo> in a DBIO result class
and wires up the constructor so that Moo attributes and DBIO columns coexist
without conflict.

When you C<use DBIO::Moo>:

=over 4

=item * L<Moo> is activated (C<use Moo>) in the calling package.

=item * L<DBIO::Core> is set as the base class via Moo's C<extends>.

=item * A C<FOREIGNBUILDARGS> method is installed that filters constructor
arguments so only DBIO-known keys reach C<DBIO::Row::new>.

=back

After C<use DBIO::Moo>, C<use DBIO::Cake> for DDL-style column declarations
or use the plain C<< __PACKAGE__->add_columns(...) >> API. Either way, Moo's
C<has>, C<with>, C<before/after/around> are all available.

=head2 The constructor problem

This section explains why a naive C<use base> or C<extends> cannot work, and
why C<FOREIGNBUILDARGS> is necessary.

A DBIO result class's constructor is C<DBIO::Row::new>. It expects a single
hashref and calls C<store_column> for every key it receives. If it sees a key
that is not a declared column, relationship, or C<-> prefixed internal key, it
dies: C<< No such column 'score' in table 'artists' >>.

When you C<use Moo> and then C<extends 'DBIO::Core'>, Moo generates a new
C<new()> in your class that wraps the Moo constructor machinery. The
fundamental problem is: B<Moo's generated C<new()> does not automatically call
the non-Moo parent's C<new()>>. By default, the non-Moo parent constructor is
simply skipped. Without explicit plumbing, you get a Moo object that has none
of the DBIO internals set up.

The plumbing Moo provides for this is C<FOREIGNBUILDARGS>. When Moo detects
that it is subclassing a non-Moo class, it calls C<FOREIGNBUILDARGS> with the
same arguments as C<new()> and passes the return list directly to the non-Moo
parent's C<new>. If C<FOREIGNBUILDARGS> is not defined, Moo does I<not> call
the parent constructor at all.

C<DBIO::Moo> installs a C<FOREIGNBUILDARGS> that:

=over 4

=item 1. Normalizes args to a hashref.

=item 2. Looks up the result source to find declared columns and relationships.

=item 3. Passes only DBIO-known keys (columns, relationships, C<-> prefixed
internals) to C<DBIO::Row::new>.

=item 4. Leaves pure Moo attributes out of the forwarded args — Moo handles
those itself via its own C<BUILD>/accessor initialization.

=back

Without this filtering, passing C<< { name => 'X', score => 42 } >> to C<new>
would cause C<DBIO::Row::new> to call C<store_column('score', 42)> and die
because C<score> is not a database column.

=head2 Two construction paths

Understanding the distinction between C<new()> and C<inflate_result> is
critical for using Moo attributes correctly.

=over 4

=item B<new()> — programmatic construction

Used by C<< $rs->create(...) >> and C<< $rs->new_result(...) >>. Moo's
generated constructor runs, initializes Moo attributes, calls
C<FOREIGNBUILDARGS> to get filtered args, then calls C<DBIO::Row::new> with
those filtered args to set up the DBIO internals (column data, result source,
storage link).

=item B<inflate_result()> — construction from database rows

Used by every query: C<find>, C<search>, C<all>, etc. C<DBIO::Row::inflate_result>
blesses a pre-built hash directly into your class and sets up the DBIO internals
without going through C<new()> at all:

  bless { _column_data => \%row, _result_source => $rsrc, ... }, $class;

Moo's constructor B<never runs>. This means: Moo attributes are never
initialized by the constructor when a row is fetched from the database.

=back

=head2 The lazy requirement

Because C<inflate_result> bypasses C<new()>, Moo attributes on DB-fetched
rows have uninitialized internal slots. Non-lazy attributes with defaults are
normally set during Moo's C<new()> — but since C<new()> does not run, those
slots remain unset and reading them returns C<undef> instead of the default.

The solution is B<always declare defaults with C<lazy =E<gt> 1>>:

  # WRONG — default never applied to inflate_result rows
  has score => (is => 'rw', default => sub { 0 });

  # CORRECT — default computed on first access, works for both paths
  has score => (is => 'rw', lazy => 1, default => sub { 0 });

With C<lazy =E<gt> 1>, the default is evaluated the first time the accessor is
called, regardless of how the object was created. Both C<new()>-created and
C<inflate_result>-created rows behave identically.

Attributes without defaults (C<is =E<gt> 'rw'> with no C<default> or
C<builder>) do not need C<lazy>: they simply start as unset regardless of
construction path, which is expected.

Attributes with C<builder> (C<is =E<gt> 'lazy'>) are inherently lazy by
Moo's definition and work correctly on both construction paths without any
additional configuration.

=head2 Manual setup without DBIO::Moo

If you prefer to wire things up yourself instead of using C<DBIO::Moo>, here is
exactly what C<use DBIO::Moo> does, spelled out explicitly:

  package MyApp::Schema::Result::Artist;

  # 1. Activate Moo
  use Moo;

  # 2. Set DBIO::Core as the base class
  use DBIO::Core ();
  extends 'DBIO::Core';

  # 3. Define FOREIGNBUILDARGS to bridge Moo and DBIO constructors
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

  # 4. Now declare your columns and Moo attributes as normal
  use DBIO::Cake;

  table 'artists';
  col id   => serial;
  col name => varchar(100);
  primary_key 'id';

  has score => (is => 'rw', lazy => 1, default => sub { 0 });

  1;

=head2 Historical context

L<DBIx::Class::Moo::ResultClass> (by ribasushi) was the original solution for
combining Moo with DBIx::Class. It used the same C<FOREIGNBUILDARGS> approach
and was the reference implementation that informed DBIO::Moo's design.

The key insight from that work: the C<FOREIGNBUILDARGS> filter is essential.
Without it, every call to C<< $rs->create({ name => 'X', score => 5 }) >>
would die because DBIO's C<store_column> rejects unknown keys. With it, Moo
handles C<score> and DBIO handles C<name> — each layer sees only what it owns.

=head2 Interaction with DBIO::Cake

C<DBIO::Cake> keywords (C<table>, C<col>, C<primary_key>, etc.) call
C<< __PACKAGE__->add_columns >>, C<< __PACKAGE__->set_primary_key >>, etc.
on the result class at compile time. This works correctly after C<use DBIO::Moo>
because C<DBIO::Core> is already in the inheritance chain when the keywords
run.

=head2 Interaction with Moo roles

Moo roles applied with C<with> work normally. The role's C<requires> are
satisfied by either DBIO column accessors (they are plain subs installed in the
package) or other Moo attributes.

  with 'MyApp::Role::HasDisplayName';

=head1 SEE ALSO

L<DBIO::Core>, L<DBIO::Cake>, L<DBIO::Moose>, L<Moo>, L<Moo::Role>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
