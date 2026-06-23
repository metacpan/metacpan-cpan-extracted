package DBIO::PostgreSQL::Diff::Function;
# ABSTRACT: Diff operations for PostgreSQL functions

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(function_key function_info));





sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  for my $key (sort keys %$target) {
    if (!exists $source->{$key}) {
      push @ops, $class->new(
        action        => 'create',
        function_key  => $key,
        function_info => $target->{$key},
      );
      next;
    }
    # Compare definitions
    my $src_def = $source->{$key}{definition} // '';
    my $tgt_def = $target->{$key}{definition} // '';
    if ($src_def ne $tgt_def) {
      push @ops, $class->new(
        action        => 'replace',
        function_key  => $key,
        function_info => $target->{$key},
      );
    }
  }

  for my $key (sort keys %$source) {
    next if exists $target->{$key};
    push @ops, $class->new(
      action        => 'drop',
      function_key  => $key,
      function_info => $source->{$key},
    );
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $info = $self->function_info;

  if ($self->action eq 'create' || $self->action eq 'replace') {
    if ($info->{definition}) {
      my $def = $info->{definition};
      $def =~ s/\s*$//;
      $def .= ';' unless $def =~ /;\s*$/;
      return $def;
    }
    return sprintf '-- CREATE OR REPLACE FUNCTION %s (definition unavailable)', $self->function_key;
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP FUNCTION %s;', $self->function_key;
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : $self->action eq 'drop' ? '-' : '~';
  return sprintf '  %sfunction: %s', $prefix, $self->function_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Function - Diff operations for PostgreSQL functions

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a function-level diff operation: C<CREATE FUNCTION>, C<DROP
FUNCTION>, or C<CREATE OR REPLACE FUNCTION> (when the definition has changed).
Function identity is by the full signature key C<schema.name(identity_args)>.

=head1 ATTRIBUTES

=head2 function_key

The function's identity string: C<schema.name(args)>.

=head2 function_info

Function metadata hashref (C<definition>, C<language>, C<return_type>, etc.).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Function->diff($source, $target);

Compares function hashrefs by identity key. Produces C<create>, C<replace>
(definition changed), or C<drop> operations.

=head2 as_sql

Returns the SQL. For C<create> and C<replace>, emits the full function
definition from introspection. For C<drop>, returns C<DROP FUNCTION key;>.

=head2 summary

Returns a one-line description such as C<+function: auth.update_modified_at()>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
