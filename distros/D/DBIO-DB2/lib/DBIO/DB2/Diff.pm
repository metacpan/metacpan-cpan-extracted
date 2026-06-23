package DBIO::DB2::Diff;
# ABSTRACT: Compare two introspected DB2 models

use strict;
use warnings;

use base 'DBIO::Diff::Base';

use DBIO::DB2::Diff::Table;
use DBIO::DB2::Diff::Column;
use DBIO::DB2::Diff::Index;
use DBIO::DB2::Diff::ForeignKey;


sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::DB2::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );
  push @ops, DBIO::DB2::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::DB2::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
  );
  push @ops, DBIO::DB2::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
    $self->source->{tables},       $self->target->{tables},
  );

  return \@ops;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff - Compare two introspected DB2 models

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::DB2::Diff> compares two introspected DB2 models (produced
by L<DBIO::DB2::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::DB2::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables, then columns, then
indexes, then foreign keys. New-table FKs are created inline by
L<DBIO::DB2::Diff::Table>; L<DBIO::DB2::Diff::ForeignKey> handles FK changes
on tables present in both models. FKs come last so any referenced table or
column already exists. Drops come last for each layer.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
