package DBIO::ChangeLog::Schema;
# ABSTRACT: Schema-level change tracking component

use strict;
use warnings;

use base 'DBIO::Schema';

use DBIO::ChangeLog::Set;
use DBIO::ChangeLog::Entry;
use DBIO::ResultSource::Table;


__PACKAGE__->mk_classdata('changelog_sources');

__PACKAGE__->mk_group_accessors(simple => qw/
  _changelog_user
  _changelog_session
  _changelog_disabled_flag
  _changelog_current_changeset_id
  _changelog_sources_registered
/);


sub changelog_user {
  my $self = shift;
  if (@_) {
    $self->_changelog_user($_[0]);
    return $self;
  }
  return $self->_changelog_user;
}


sub changelog_session {
  my $self = shift;
  if (@_) {
    $self->_changelog_session($_[0]);
    return $self;
  }
  return $self->_changelog_session;
}


sub changelog_disabled {
  my $self = shift;
  if (@_) {
    $self->_changelog_disabled_flag($_[0]);
    return $self;
  }
  return $self->_changelog_disabled_flag;
}


sub connection {
  my $self = shift;
  my $ret = $self->next::method(@_);
  $ret->_register_changelog_sources
    unless $ret->_changelog_sources_registered;
  return $ret;
}


sub txn_do {
  my ($self, $coderef, @args) = @_;

  # If changelog is disabled or we already have a changeset (nested),
  # just delegate
  if ($self->changelog_disabled || $self->_changelog_current_changeset_id) {
    return $self->next::method($coderef, @args);
  }

  # Wrap: create changeset, set as current, run coderef
  my $outer = $self;
  return $self->next::method(sub {
    # Create the changeset row
    my $cs = $outer->resultset('ChangeLog_Set')->create({
      user_id    => $outer->changelog_user,
      session_id => $outer->changelog_session,
      created_at => _now(),
    });

    # Use local so rollback naturally clears this
    local $outer->{_changelog_current_changeset_id} = $cs->id;

    return $coderef->(@args);
  });
}


sub deploy_changelog {
  my ($self) = @_;

  my @tables;

  if (my $set_source = $self->source('ChangeLog_Set')) {
    push @tables, $set_source;
  }

  for my $source_name ($self->sources) {
    next if $source_name =~ /_ChangeLog$/ || $source_name eq 'ChangeLog_Set';
    if (my $cl = $self->source($source_name . '_ChangeLog')) {
      push @tables, $cl;
    }
  }

  for my $table (@tables) {
    $self->storage->deploy($table);
  }

  return $self;
}

# ---- Internal ----

sub _register_changelog_sources {
  my ($self) = @_;

  # Register changelog_set source
  my $set_def = DBIO::ChangeLog::Set->source_definition;
  my $set_source = $self->_build_changelog_source(
    'ChangeLog_Set', $set_def,
  );
  $self->register_extra_source('ChangeLog_Set', $set_source);

  # Register per-source changelog tables
  my @source_names = $self->sources;
  my $tracked = $self->changelog_sources;

  for my $source_name (@source_names) {
    # Skip changelog sources themselves
    next if $source_name =~ /_ChangeLog$/ || $source_name eq 'ChangeLog_Set';

    # If tracked sources are specified, skip untracked ones
    if ($tracked && @$tracked) {
      next unless grep { $_ eq $source_name } @$tracked;
    }

    my $orig_source = $self->source($source_name);
    my $table_name = $orig_source->name;
    next unless defined $table_name && length $table_name;

    my $entry_def = DBIO::ChangeLog::Entry->source_definition(
      table => $table_name,
    );
    my $entry_source = $self->_build_changelog_source(
      $source_name . '_ChangeLog', $entry_def,
    );
    $self->register_extra_source(
      $source_name . '_ChangeLog', $entry_source,
    );
  }

  $self->_changelog_sources_registered(1);
}

sub _build_changelog_source {
  my ($self, $source_name, $def) = @_;

  my $result_class = "DBIO::ChangeLog::Result::$source_name";
  {
    no strict 'refs';
    @{"${result_class}::ISA"} = ('DBIO::Core');
  }

  my $source = DBIO::ResultSource::Table->new({
    source_name  => $source_name,
    result_class => $result_class,
  });

  $source->name($def->{table});

  # Add columns in order
  for my $col (@{ $def->{column_order} }) {
    $source->add_columns($col => $def->{columns}{$col});
  }

  $source->set_primary_key(@{ $def->{primary_key} });

  $result_class->mk_classdata('result_source_instance');
  $result_class->result_source_instance($source);

  return $source;
}

sub _now {
  require POSIX;
  return POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ChangeLog::Schema - Schema-level change tracking component

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';

  __PACKAGE__->load_components('ChangeLog::Schema');

  # Optional: restrict which sources are tracked (default: all)
  __PACKAGE__->changelog_sources([qw/ Artist Album /]);

=head1 DESCRIPTION

A schema-level component that enables automatic change tracking.
When loaded, it:

=over 4

=item *

Overrides L<DBIO::Schema/txn_do> to automatically create changesets
that group changelog entries within a transaction.

=item *

At connection time, dynamically registers ResultSource objects for the
C<changelog_set> table and each C<< <source>_changelog >> table.

=item *

Provides L</changelog_user> and L</changelog_session> accessors for
recording who made changes.

=back

=head1 METHODS

=head2 changelog_user

  $schema->changelog_user($user_id);
  my $uid = $schema->changelog_user;

Sets or gets the user identifier for future changesets.

=head2 changelog_session

  $schema->changelog_session($session_id);
  my $sid = $schema->changelog_session;

Sets or gets the session identifier for future changesets.

=head2 changelog_disabled

  local $schema->{_changelog_disabled_flag} = 1;
  $schema->changelog_disabled(1);

Flag to skip change tracking entirely.

=head2 connection

Override of L<DBIO::Schema/connection>.  After establishing the
connection, registers the changelog ResultSources if not yet done.

=head2 txn_do

  $schema->txn_do(sub {
    # all changes here are grouped in one changeset
  });

Wraps the inherited C<txn_do> in changeset creation.  A new
C<changelog_set> row is inserted before the coderef runs.  If the
transaction rolls back, the changeset row is naturally rolled back too
(thanks to C<local> scoping of the changeset ID).

Nested calls to C<txn_do> reuse the parent changeset.

=head2 deploy_changelog

  $schema->deploy_changelog;

Deploys all changelog tables (C<changelog_set> and every
C<< <source>_changelog >> table) via the storage layer.  Call this after
deploying your main schema.

=head1 SEE ALSO

L<DBIO::ChangeLog>, L<DBIO::ChangeLog::Entry>, L<DBIO::ChangeLog::Set>,
L<DBIO::ChangeLog::Table>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
