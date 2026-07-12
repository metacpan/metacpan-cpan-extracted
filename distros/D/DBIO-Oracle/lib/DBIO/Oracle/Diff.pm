package DBIO::Oracle::Diff;
# ABSTRACT: Compare two introspected Oracle models

use strict;
use warnings;

use base 'DBIO::Diff::Base';


use DBIO::Oracle::Diff::Table     ();
use DBIO::Oracle::Diff::Column    ();
use DBIO::Oracle::Diff::Index     ();

my %_REGISTRY = (
  tables     => 'DBIO::Oracle::Diff::Table',
  columns    => 'DBIO::Oracle::Diff::Column',
  indexes    => 'DBIO::Oracle::Diff::Index',
);

my @_ORDER = qw(tables columns indexes);

my %_NEEDS_TABLES = map { $_ => 1 } qw(columns);

sub _build_operations {
  my ($self) = @_;
  my @ops;

  for my $key (@_ORDER) {
    my $diff_cls = $_REGISTRY{$key} or next;
    next unless exists $self->source->{$key} || exists $self->target->{$key};

    my @extra;
    if ($_NEEDS_TABLES{$key}) {
      @extra = (
        $self->source->{tables} // {},
        $self->target->{tables} // {},
      );
    }

    push @ops, $diff_cls->diff(
      $self->source->{$key} // {},
      $self->target->{$key} // {},
      @extra,
    );
  }

  return \@ops;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff - Compare two introspected Oracle models

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::Oracle::Diff> compares two introspected Oracle database models
(as produced by L<DBIO::Oracle::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL
or a human-readable summary.

    my $diff = DBIO::Oracle::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are generated in dependency order: tables first, then
columns, then indexes. Drops come last.

=seealso

=over 4

=item * L<DBIO::Oracle::Deploy> - orchestrates introspection and diff

=item * L<DBIO::Oracle::Introspect> - produces the models being compared

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
