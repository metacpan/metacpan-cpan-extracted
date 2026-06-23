package DBIO::Sybase::Diff;
# ABSTRACT: Compare two introspected Sybase ASE models

use strict;
use warnings;

use base 'DBIO::Diff::Base';


use DBIO::Sybase::Diff::Table      ();
use DBIO::Sybase::Diff::Column     ();
use DBIO::Sybase::Diff::Index      ();
use DBIO::Sybase::Diff::ForeignKey ();

sub _build_operations {
  my ($self) = @_;
  my @ops;

  # Foreign keys are diffed once, then split: drops must precede table/column
  # drops, adds must follow table/column creates. ASE FKs are not altered in
  # place, so an attribute change is already a drop+create pair from ::ForeignKey.
  my @fk_ops = DBIO::Sybase::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
  );
  my @fk_drops = grep { $_->action eq 'drop'   } @fk_ops;
  my @fk_adds  = grep { $_->action eq 'create' } @fk_ops;

  push @ops, @fk_drops;
  push @ops, DBIO::Sybase::Diff::Table->diff(
    $self->source->{tables},       $self->target->{tables},
    $self->target->{columns},     $self->target->{foreign_keys},
  );
  push @ops, DBIO::Sybase::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::Sybase::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
  );
  push @ops, @fk_adds;

  return \@ops;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff - Compare two introspected Sybase ASE models

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Sybase::Diff> compares two introspected Sybase ASE database models
(as produced by L<DBIO::Sybase::Introspect>) and produces a list of
structured diff operations that can be rendered to SQL or a human-readable
summary.

    my $diff = DBIO::Sybase::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are generated in dependency order: foreign-key drops first
(so a referenced table/column can then be dropped), then tables, columns and
indexes, then foreign-key adds last (so the tables/columns they reference
already exist).

=seealso

=over

=item * L<DBIO::Sybase::Deploy> - orchestrates introspection and diff

=item * L<DBIO::Sybase::Introspect> - produces the models being compared

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
