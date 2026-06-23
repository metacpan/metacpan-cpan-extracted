package DBIO::Firebird::Diff;
# ABSTRACT: Compare two introspected Firebird models

use strict;
use warnings;

use base 'DBIO::Diff::Base';


use DBIO::Firebird::Diff::Table ();
use DBIO::Firebird::Diff::Column ();
use DBIO::Firebird::Diff::Index ();

sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::Firebird::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );
  push @ops, DBIO::Firebird::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::Firebird::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
  );

  return \@ops;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Diff - Compare two introspected Firebird models

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Firebird::Diff> compares two introspected Firebird database models
(as produced by L<DBIO::Firebird::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL or a
human-readable summary.

    my $diff = DBIO::Firebird::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are generated in dependency order: tables first, then
columns, then indexes.

=seealso

=over 4

=item * L<DBIO::Firebird::Deploy> - orchestrates introspection and diff

=item * L<DBIO::Firebird::Introspect> - produces the models being compared

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
