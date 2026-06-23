package DBIO::Diff::Base;
# ABSTRACT: Base class for DBIO driver diff orchestrators

use strict;
use warnings;


sub new { my ($class, %args) = @_; bless \%args, $class }

sub source { $_[0]->{source} }


sub target { $_[0]->{target} }


sub operations { $_[0]->{operations} //= $_[0]->_build_operations }


sub _build_operations {
  my ($self) = @_;
  die ref($self) . '::_build_operations not implemented';
}


sub has_changes {
  my ($self) = @_;
  return scalar @{ $self->operations } > 0;
}


sub as_sql {
  my ($self) = @_;
  return join "\n", map { $_->as_sql } @{ $self->operations };
}


sub summary {
  my ($self) = @_;
  return join "\n", map { $_->summary } @{ $self->operations };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Diff::Base - Base class for DBIO driver diff orchestrators

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Base class for driver-specific diff orchestrators
(L<DBIO::PostgreSQL::Diff>, L<DBIO::SQLite::Diff>, L<DBIO::MySQL::Diff>).
Provides the full public interface; subclasses implement only
C<_build_operations>.

=head1 ATTRIBUTES

=head2 source

The current (live) database model hashref. Required.

=head2 target

The desired (deployed from DBIO classes) database model hashref. Required.

=head2 operations

ArrayRef of diff operation objects. Built lazily. Each object must respond to
C<as_sql> and C<summary>.

=head1 METHODS

=head2 has_changes

    if ($diff->has_changes) { ... }

Returns true if there is at least one diff operation.

=head2 as_sql

    my $sql = $diff->as_sql;

Returns all diff operations concatenated as a SQL migration script.

=head2 summary

    my $text = $diff->summary;

Returns a human-readable summary of all diff operations.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
