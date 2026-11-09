package DBIO::MSSQL::Diff::Schema;
# ABSTRACT: Diff operations for MSSQL schemas

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::MSSQL::DDL qw(_quote_ident _schema_prefix);


__PACKAGE__->mk_diff_accessors(qw/schema_name/);


sub diff {
  my ($class, $source, $target) = @_;
  my $coll = $source->{collation};
  my $fold = $coll && !$coll->{case_sensitive} ? sub { lc $_[0] } : sub { $_[0] };

  my %have = (dbo => 1);
  $have{ $fold->($_) } = 1 for keys %{ $source->{schemas} // {} };
  for my $name (keys %{ $source->{tables} // {} }) {
    $have{ $fold->($1) } = 1 if $name =~ /\A([^.]+)\./;
  }

  my (%want);
  my $tables = $target->{tables} // {};
  for my $name (keys %$tables) {
    next unless $name =~ /\A([^.]+)\./;
    my $schema = $1;
    $want{$schema} = 1 unless $have{ $fold->($schema) };
  }
  return map { $class->new(action => 'create', schema_name => $_) } sort keys %want;
}


sub as_sql {
  my ($self) = @_;
  return sprintf 'CREATE SCHEMA %s;', _quote_ident($self->schema_name);
}


sub summary {
  my ($self) = @_;
  return sprintf '%s schema: %s', $self->summary_prefix, $self->schema_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff::Schema - Diff operations for MSSQL schemas

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<CREATE SCHEMA> for a schema that the target needs and the live database
lacks. A table named C<schema.table> in the classes is made in that
schema, and the schema must exist first; L<DBIO::MSSQL::Diff> puts these
operations before everything else. A schema that is no longer needed is B<not>
dropped (not decided; the tables in it are dropped, the schema stays).

Each statement is a batch of its own for the server: C<CREATE SCHEMA> has to be
the first statement of a batch, and the deploy runs the statements one at a
time.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MSSQL::Diff::Schema->diff($source_model, $target_model);

The schemas the tables of the target model name (a model key C<schema.table>, a
view's too) that the source model has neither in its
C<schemas> section nor in the keys of its tables. C<dbo> is always there. When
the source model says its database ignores case (C<collation>), schema names
are compared ignoring case. Sorted by name.

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
