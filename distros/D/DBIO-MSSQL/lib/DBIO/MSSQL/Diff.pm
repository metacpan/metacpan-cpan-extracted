package DBIO::MSSQL::Diff;
# ABSTRACT: Compare two introspected MSSQL models

use strict;
use warnings;

use base 'DBIO::Diff::Base';


use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::Column;
use DBIO::MSSQL::Diff::Index;
use DBIO::MSSQL::Diff::ForeignKey;

sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::MSSQL::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );
  push @ops, DBIO::MSSQL::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::MSSQL::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::MSSQL::Diff::ForeignKey->diff(
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

DBIO::MSSQL::Diff - Compare two introspected MSSQL models

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MSSQL::Diff> compares two introspected MSSQL models (produced
by L<DBIO::MSSQL::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::MSSQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables, then columns, then
indexes, then foreign keys. New-table FKs are created inline by
L<DBIO::MSSQL::Diff::Table>; L<DBIO::MSSQL::Diff::ForeignKey> handles FK
changes on tables present in both models. Drops come last for each layer.

=seealso

=over

=item * L<DBIO::MSSQL::Introspect> - produces the models this class compares

=item * L<DBIO::MSSQL::Deploy> - uses this class for upgrade diffs

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
