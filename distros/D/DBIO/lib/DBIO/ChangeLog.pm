package DBIO::ChangeLog;
# ABSTRACT: Row-level change tracking component

use strict;
use warnings;

use base 'DBIO::Base';

use JSON::PP ();
use Scalar::Util ();

my $json = JSON::PP->new->utf8->canonical->allow_nonref;

sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (exists $info->{changelog} and !delete $info->{changelog}) {
      $info->{_changelog_exclude} = 1;
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}


sub changelog_column_definitions {
  return ( changes => { data_type => 'text' } );
}


sub changelog_serialize_changes {
  my ($self, $changes) = @_;
  return $json->encode($changes);
}


sub changelog_deserialize_changes {
  my ($self, $raw) = @_;
  return undef unless defined $raw;
  return $json->decode($raw);
}


sub changelog_write_entry {
  my ($self, $entry) = @_;

  my $schema = $self->result_source->schema;
  my $source_name = $self->result_source->source_name;
  my $cl_source_name = $source_name . '_ChangeLog';

  $schema->resultset($cl_source_name)->create($entry);
}


sub changelog_notify { }

# ---- Internal helpers ----

sub _changelog_serialize_pk {
  my ($self) = @_;
  my @pk_cols = $self->result_source->primary_columns;
  if (@pk_cols == 1) {
    return '' . ($self->get_column($pk_cols[0]) // '');
  }
  return $json->encode([ map { $self->get_column($_) } @pk_cols ]);
}

sub _changelog_is_disabled {
  my ($self) = @_;
  my $schema = $self->result_source->schema;
  return 0 unless $schema->can('changelog_disabled');
  return $schema->changelog_disabled ? 1 : 0;
}

sub _changelog_is_tracked {
  my ($self) = @_;
  my $schema = $self->result_source->schema;
  return 1 unless $schema->can('changelog_sources');
  my $sources = $schema->changelog_sources;
  return 1 unless $sources && @$sources;
  my $source_name = $self->result_source->source_name;
  return grep { $_ eq $source_name } @$sources;
}

sub _changelog_current_changeset_id {
  my ($self) = @_;
  my $schema = $self->result_source->schema;
  return undef unless $schema->can('_changelog_current_changeset_id');
  return $schema->_changelog_current_changeset_id;
}

sub _changelog_get_timestamp {
  my ($self) = @_;
  # Use a simple ISO 8601 string; drivers can override
  require POSIX;
  return POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime);
}

sub _changelog_excluded_columns {
  my ($self) = @_;
  my $info = $self->result_source->columns_info;
  return { map { $_ => 1 } grep { $info->{$_}{_changelog_exclude} } keys %$info };
}

sub _changelog_filtered_columns {
  my ($self, %cols) = @_;
  my $exclude = $self->_changelog_excluded_columns;
  delete $cols{$_} for keys %$exclude;
  return %cols;
}

sub _changelog_record {
  my ($self, $event, $changes) = @_;

  return if $self->_changelog_is_disabled;
  return unless $self->_changelog_is_tracked;

  my $entry = {
    changeset_id => $self->_changelog_current_changeset_id,
    row_id       => $self->_changelog_serialize_pk,
    event        => $event,
    changes      => $self->changelog_serialize_changes($changes),
    created_at   => $self->_changelog_get_timestamp,
  };

  $self->changelog_write_entry($entry);
  $self->changelog_notify($event, $entry);
}

# ---- Overrides ----


sub insert {
  my ($self, @args) = @_;

  my $result = $self->next::method(@args);

  if ($self->_changelog_is_tracked && !$self->_changelog_is_disabled) {
    my %cols = $self->_changelog_filtered_columns($self->get_columns);
    $self->_changelog_record('insert', \%cols);
  }

  return $result;
}


sub update {
  my ($self, $upd) = @_;

  # Apply the update values so get_dirty_columns sees them
  $self->set_inflated_columns($upd) if $upd;

  my %dirty = $self->get_dirty_columns;

  # Filter out excluded columns
  my $exclude = $self->_changelog_excluded_columns;
  delete $dirty{$_} for keys %$exclude;

  # Capture old values before the update
  my %old_values;
  if (%dirty && $self->_changelog_is_tracked && !$self->_changelog_is_disabled) {
    for my $col (keys %dirty) {
      # _column_data_in_storage has the previously stored values
      $old_values{$col} = exists $self->{_column_data_in_storage}
        ? $self->{_column_data_in_storage}{$col}
        : undef;
    }
  }

  my $result = $self->next::method;

  if (%dirty && $self->_changelog_is_tracked && !$self->_changelog_is_disabled) {
    my %diffs;
    for my $col (keys %dirty) {
      $diffs{$col} = [ $old_values{$col}, $dirty{$col} ];
    }
    $self->_changelog_record('update', \%diffs) if %diffs;
  }

  return $result;
}


sub delete {
  my ($self, @args) = @_;

  my %cols;
  if (ref $self && $self->_changelog_is_tracked && !$self->_changelog_is_disabled) {
    %cols = $self->_changelog_filtered_columns($self->get_columns);
  }

  my $result = $self->next::method(@args);

  if (%cols) {
    $self->_changelog_record('delete', \%cols);
  }

  return $result;
}


sub log_event {
  my ($self, $event_name, $details) = @_;
  $details //= {};
  $self->_changelog_record($event_name, $details);
}


sub changelog {
  my ($self) = @_;
  my $schema = $self->result_source->schema;
  my $source_name = $self->result_source->source_name;
  my $cl_source_name = $source_name . '_ChangeLog';

  return $schema->resultset($cl_source_name)->search({
    row_id => $self->_changelog_serialize_pk,
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ChangeLog - Row-level change tracking component

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id            => { data_type => 'integer', is_auto_increment => 1 },
    name          => { data_type => 'varchar', size => 100 },
    password_hash => { data_type => 'varchar', size => 255, changelog => 0 },
  );
  __PACKAGE__->set_primary_key('id');

See F<t/changelog/> for a runnable example.

=head1 DESCRIPTION

Automatically tracks insert, update, and delete operations on a Result
class. Load via C<load_components('ChangeLog')> on any Result class
whose changes you want to record.

Changelog entries are written to a per-source C<< <table>_changelog >>
table that is auto-generated by L<DBIO::ChangeLog::Schema>.

=head1 METHODS

=head2 changelog_column_definitions

  my %cols = $self->changelog_column_definitions;

Returns the column definitions hash for the C<changes> column of the
changelog entry table.  Drivers override this to use native types
(e.g. C<jsonb> for PostgreSQL).

=head2 changelog_serialize_changes

  my $json_str = $self->changelog_serialize_changes(\%changes);

Serializes the changes hashref for storage.  Base implementation uses
L<JSON::PP>.

=head2 changelog_deserialize_changes

  my $href = $self->changelog_deserialize_changes($raw);

Deserializes stored changes back to a hashref.  Base implementation
uses L<JSON::PP>.

=head2 changelog_write_entry

  $self->changelog_write_entry(\%entry);

Writes a single changelog entry to the changelog table.  The base
implementation uses resultset->create on the changelog source.

B<Error handling:> If the write fails (e.g., foreign key constraint
violation, disk full), the exception propagates to the caller.  This
allows the transaction to be rolled back if the changelog write is
critical.  Wrap in try/catch if you need to handle failures gracefully.

Drivers can override this to batch writes, use COPY, or async insert.

=head2 changelog_notify

  $self->changelog_notify($event, \%entry);

Called after a changelog entry is written.  No-op in the base
implementation.  Drivers can override to send notifications (e.g.
PostgreSQL C<pg_notify>).

=head2 insert

After C<next::method>, creates a changelog entry recording all column
values (excluding L</changelog_exclude_columns>).

=head2 update

Before C<next::method>, captures dirty columns.  After a successful
update, creates a changelog entry with C<< { col => [old, new] } >>
diffs.  Skips if no tracked columns changed.

=head2 delete

After C<next::method>, captures all column values.  Creates a
changelog entry with the deleted values, then performs the delete.
The changelog entry is written after the delete to ensure the
audit-log guarantee that a changelog entry implies the operation succeeded.

=head2 log_event

  $row->log_event('approved', { by => $admin_id, reason => 'verified' });

Creates a custom changelog entry.  The C<changeset_id> is set if called
inside a L<DBIO::ChangeLog::Schema/txn_do>, otherwise it is C<NULL>.

=head2 changelog

  my $rs = $row->changelog;

Returns a ResultSet of changelog entries for this row, filtered by
C<row_id>.

=head1 COLUMN FLAGS

=over 4

=item C<< changelog =E<gt> 0 >>

The column is omitted from changelog entries for insert and delete
events; changes to it are not recorded in update events. Useful for
sensitive fields like password hashes.

=back

=head1 OVERRIDABLE METHODS

Drivers (e.g. L<DBIO::PostgreSQL::ChangeLog>) override these via
C<next::method> to customize storage formats, write paths, and
notification.

=over 4

=item C<changelog_column_definitions>

Column definitions hash for the C<changes> column of the changelog
entry table. Drivers override to use native types (e.g. C<jsonb> for
PostgreSQL).

=item C<changelog_serialize_changes($href)>

Serialise the changes hashref for storage. Default: L<JSON::PP>.

=item C<changelog_deserialize_changes($raw)>

Inverse of the above.

=item C<changelog_write_entry($entry)>

Write a single changelog entry. Default: C<create_related> on the
C<changelog> relationship. Drivers can override for batch writes,
COPY, or async insert.

=item C<changelog_notify($event, $entry)>

Called after a changelog entry is written. No-op by default. Drivers
can override to e.g. send a C<pg_notify>.

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
