package DBIO::PostgreSQL::Diff::Trigger;
# ABSTRACT: Diff operations for PostgreSQL triggers

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table_key trigger_name trigger_info));






sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  for my $table_key (sort keys %$target) {
    my $src_trgs = $source->{$table_key} // {};
    my $tgt_trgs = $target->{$table_key};

    for my $name (sort keys %$tgt_trgs) {
      if (!exists $src_trgs->{$name}) {
        push @ops, $class->new(
          action       => 'create',
          table_key    => $table_key,
          trigger_name => $name,
          trigger_info => $tgt_trgs->{$name},
        );
        next;
      }
      # Changed: compare definitions
      my $src_def = $src_trgs->{$name}{definition} // '';
      my $tgt_def = $tgt_trgs->{$name}{definition} // '';
      if ($src_def ne $tgt_def) {
        push @ops, $class->new(
          action       => 'drop',
          table_key    => $table_key,
          trigger_name => $name,
          trigger_info => $src_trgs->{$name},
        );
        push @ops, $class->new(
          action       => 'create',
          table_key    => $table_key,
          trigger_name => $name,
          trigger_info => $tgt_trgs->{$name},
        );
      }
    }
  }

  for my $table_key (sort keys %$source) {
    my $src_trgs = $source->{$table_key};
    my $tgt_trgs = $target->{$table_key} // {};

    for my $name (sort keys %$src_trgs) {
      next if exists $tgt_trgs->{$name};
      push @ops, $class->new(
        action       => 'drop',
        table_key    => $table_key,
        trigger_name => $name,
        trigger_info => $src_trgs->{$name},
      );
    }
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'create') {
    if ($self->trigger_info->{definition}) {
      return $self->trigger_info->{definition} . ';';
    }
    return sprintf '-- CREATE TRIGGER %s ON %s (definition unavailable)',
      $self->trigger_name, $self->table_key;
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP TRIGGER %s ON %s;', $self->trigger_name, $self->table_key;
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %strigger: %s on %s', $prefix, $self->trigger_name, $self->table_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Trigger - Diff operations for PostgreSQL triggers

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a trigger-level diff operation: C<CREATE TRIGGER> or C<DROP
TRIGGER>. When a trigger definition changes, it produces a C<DROP> followed by
a C<CREATE>. Triggers are compared using the full C<pg_get_triggerdef> output.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key identifying which table the trigger belongs to.

=head2 trigger_name

The trigger name.

=head2 trigger_info

Trigger metadata hashref (C<definition>, C<timing>, C<event>, etc.).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Trigger->diff($source, $target);

Compares trigger sets per table. Definition changes produce a drop-then-create
pair.

=head2 as_sql

Returns C<CREATE TRIGGER ...;> using the full definition from introspection,
or C<DROP TRIGGER name ON table;>.

=head2 summary

Returns a one-line description such as C<+trigger: users_modified_at on auth.users>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
