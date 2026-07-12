package DBIO::PostgreSQL::Diff::Extension;
# ABSTRACT: Diff operations for PostgreSQL extensions

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(extension_name extension_info old_version new_version));





sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  for my $name (sort keys %$target) {
    if (!exists $source->{$name}) {
      push @ops, $class->new(
        action         => 'create',
        extension_name => $name,
        extension_info => $target->{$name},
      );
      next;
    }
    # Version changes
    my $src_ver = $source->{$name}{version} // '';
    my $tgt_ver = $target->{$name}{version} // '';
    if ($src_ver ne $tgt_ver) {
      push @ops, $class->new(
        action         => 'update',
        extension_name => $name,
        extension_info => $target->{$name},
        old_version    => $src_ver,
        new_version    => $tgt_ver,
      );
    }
  }

  for my $name (sort keys %$source) {
    next if exists $target->{$name};
    push @ops, $class->new(
      action         => 'drop',
      extension_name => $name,
      extension_info => $source->{$name},
    );
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'create') {
    return sprintf 'CREATE EXTENSION IF NOT EXISTS %s;', $self->extension_name;
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP EXTENSION %s;', $self->extension_name;
  }
  elsif ($self->action eq 'update') {
    return sprintf "ALTER EXTENSION %s UPDATE TO '%s';",
      $self->extension_name, $self->new_version;
  }
}


sub summary {
  my ($self) = @_;
  if ($self->action eq 'update') {
    return sprintf '  ~extension: %s (%s -> %s)',
      $self->extension_name, $self->old_version, $self->new_version;
  }
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %sextension: %s', $prefix, $self->extension_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Extension - Diff operations for PostgreSQL extensions

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents an extension-level diff operation: C<CREATE EXTENSION IF NOT
EXISTS>, C<DROP EXTENSION>, or C<ALTER EXTENSION ... UPDATE TO> (version
change). Extensions are compared by name; version differences produce an update
operation.

=head1 ATTRIBUTES

=head2 extension_name

The PostgreSQL extension name (e.g. C<pgcrypto>, C<postgis>).

=head2 extension_info

Extension metadata hashref (C<version>, C<schema_name>, C<relocatable>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Extension->diff($source, $target);

Compares extension hashrefs. Produces C<create>, C<update> (version changed),
or C<drop> operations.

=head2 as_sql

Returns the SQL for this operation.

=head2 summary

Returns a one-line description such as C<+extension: pgcrypto> or
C<~extension: postgis (3.3 -E<gt> 3.4)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
