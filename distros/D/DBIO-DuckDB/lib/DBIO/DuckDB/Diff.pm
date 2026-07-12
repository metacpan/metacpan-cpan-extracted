package DBIO::DuckDB::Diff;
# ABSTRACT: Compare two introspected DuckDB models

use strict;
use warnings;

use base 'DBIO::Diff::Base';

use DBIO::DuckDB::Diff::Table;
use DBIO::DuckDB::Diff::Column;
use DBIO::DuckDB::Diff::Index;


sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::DuckDB::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );
  push @ops, DBIO::DuckDB::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::DuckDB::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
    $self->source->{tables},  $self->target->{tables},
  );

  return \@ops;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Diff - Compare two introspected DuckDB models

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::DuckDB::Diff> compares two introspected DuckDB models (produced
by L<DBIO::DuckDB::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::DuckDB::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables, then columns, then
indexes. Drops come last for each layer.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
