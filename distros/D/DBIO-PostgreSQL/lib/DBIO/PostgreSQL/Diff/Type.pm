package DBIO::PostgreSQL::Diff::Type;
# ABSTRACT: Diff operations for PostgreSQL types (enums, composites, ranges)

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(type_key type_info added_values));






sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  for my $key (sort keys %$target) {
    if (!exists $source->{$key}) {
      push @ops, $class->new(
        action    => 'create',
        type_key  => $key,
        type_info => $target->{$key},
      );
      next;
    }

    # Existing type — check for enum value additions
    my $src = $source->{$key};
    my $tgt = $target->{$key};

    if ($tgt->{type_kind} eq 'enum' && $src->{type_kind} eq 'enum') {
      my %src_vals = map { $_ => 1 } @{ $src->{values} };
      my @new_vals = grep { !$src_vals{$_} } @{ $tgt->{values} };
      if (@new_vals) {
        push @ops, $class->new(
          action       => 'add_value',
          type_key     => $key,
          type_info    => $tgt,
          added_values => \@new_vals,
        );
      }
    }
  }

  for my $key (sort keys %$source) {
    next if exists $target->{$key};
    push @ops, $class->new(
      action    => 'drop',
      type_key  => $key,
      type_info => $source->{$key},
    );
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $info = $self->type_info;

  if ($self->action eq 'create') {
    if ($info->{type_kind} eq 'enum') {
      my $values = join ', ', map { "'$_'" } @{ $info->{values} };
      return sprintf "CREATE TYPE %s AS ENUM (%s);", $self->type_key, $values;
    }
    elsif ($info->{type_kind} eq 'composite') {
      my $attrs = join ",\n  ", map {
        "$_->{name} $_->{type}"
      } @{ $info->{attributes} };
      return sprintf "CREATE TYPE %s AS (\n  %s\n);", $self->type_key, $attrs;
    }
    elsif ($info->{type_kind} eq 'range') {
      return sprintf "CREATE TYPE %s AS RANGE (SUBTYPE = %s);",
        $self->type_key, $info->{subtype};
    }
  }
  elsif ($self->action eq 'drop') {
    return sprintf "DROP TYPE %s CASCADE;", $self->type_key;
  }
  elsif ($self->action eq 'add_value') {
    return join "\n", map {
      sprintf "ALTER TYPE %s ADD VALUE '%s';", $self->type_key, $_
    } @{ $self->added_values };
  }
}


sub summary {
  my ($self) = @_;
  if ($self->action eq 'add_value') {
    my $count = scalar @{ $self->added_values };
    my $vals = join ', ', @{ $self->added_values };
    return sprintf '  ~type: %s +%d value(s) (%s)', $self->type_key, $count, $vals;
  }
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %stype: %s (%s)', $prefix, $self->type_key, $self->type_info->{type_kind};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Type - Diff operations for PostgreSQL types (enums, composites, ranges)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a type-level diff operation: C<CREATE TYPE>, C<DROP TYPE CASCADE>,
or C<ALTER TYPE ... ADD VALUE> (for enum value additions). Handles enum,
composite, and range types. Note that enum value removal is not supported by
PostgreSQL -- only addition is possible without recreating the type.

=head1 ATTRIBUTES

=head2 type_key

The C<schema.type_name> key.

=head2 type_key

The C<schema.type_name> key.

=head2 type_info

Type metadata hashref from introspection (C<type_kind>, C<values>,
C<attributes>, or C<subtype> depending on kind).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Type->diff($source, $target);

Compares two type hashrefs. Produces C<create> operations for new types,
C<drop> for removed types, and C<add_value> for enum types that have gained
new values.

=head2 as_sql

Returns the SQL for this operation. For C<add_value>, returns one
C<ALTER TYPE ... ADD VALUE> statement per new enum value.

=head2 summary

Returns a one-line description such as C<+type: auth.role_type (enum)> or
C<~type auth.role_type: +1 value(s) (superadmin)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
