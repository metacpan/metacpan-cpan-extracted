package DBIO::ChangeLog::Table;
# ABSTRACT: Shared utilities for changelog table source definitions

use strict;
use warnings;

use base 'DBIO::Base';



sub validate_definition {
  my ($class, $def) = @_;
  require Carp;
  Carp::croak("source_definition must return a hashref")
    unless ref $def eq 'HASH';

  for my $key (qw/ table columns column_order primary_key /) {
    Carp::croak("source_definition missing required key: $key")
      unless exists $def->{$key};
  }

  Carp::croak("columns must be a hashref")
    unless ref $def->{columns} eq 'HASH';

  Carp::croak("column_order must be an arrayref")
    unless ref $def->{column_order} eq 'ARRAY';

  Carp::croak("primary_key must be an arrayref")
    unless ref $def->{primary_key} eq 'ARRAY';

  return $def;
}


sub build_source {
  my ($class, $def) = @_;
  $class->validate_definition($def);

  return {
    table         => $def->{table},
    columns       => $def->{columns},
    column_order  => $def->{column_order},
    primary_key   => $def->{primary_key},
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ChangeLog::Table - Shared utilities for changelog table source definitions

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

Shared utilities for L<DBIO::ChangeLog::Entry> and L<DBIO::ChangeLog::Set>.
Provides validation and building helpers for source_definition hashes.

=head1 METHODS

=head2 validate_definition

  DBIO::ChangeLog::Table->validate_definition(\%def);

Validates that a source_definition hash contains all required keys:
C<table>, C<columns>, C<column_order>, and C<primary_key>.  Croaks on
invalid input.

=head2 build_source

  my $def_hash = DBIO::ChangeLog::Table->build_source(\%def);

Validates the definition and returns a plain hashref with C<table>,
C<columns>, C<column_order>, and C<primary_key> keys.  Used by
L<DBIO::ChangeLog::Entry> and L<DBIO::ChangeLog::Set> to build their
source definitions.

=head1 NAME

DBIO::ChangeLog::Table — Shared utilities for changelog source definitions

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
