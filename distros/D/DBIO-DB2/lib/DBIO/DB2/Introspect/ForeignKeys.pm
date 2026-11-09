package DBIO::DB2::Introspect::ForeignKeys;
# ABSTRACT: Introspect DB2 foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Introspect::Base ();

# SYSCAT.REFERENCES stores DELETERULE/UPDATERULE as single-char codes. Normalize
# them to the SQL keywords the model carries everywhere else, so the FK clause
# emitter (DBIO::DB2::DDL::_fk_constraint_clause) renders e.g. ON DELETE CASCADE
# (not ON DELETE C) and a rule comparison against install_ddl-shaped FKs matches.
my %RULE = (
  A => 'NO ACTION',
  C => 'CASCADE',
  N => 'SET NULL',
  R => 'RESTRICT',
);

sub _rule {
  my ($code) = @_;
  return undef unless defined $code;
  $code =~ s/\s+$//;
  return $RULE{ uc $code } // $code;
}



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys
  my %fks;

  my $sth = $dbh->prepare(q{
    SELECT tc.constname, tc.tabname,
           kcu.colname, kcu.colseq,
           sr.reftabname, sr.reftabschema, sr.refkeyname,
           sr.deleterule, sr.updaterule
    FROM syscat.tabconst tc
    JOIN syscat.keycoluse kcu
      ON tc.constname = kcu.constname
        AND tc.tabschema = kcu.tabschema
        AND tc.tabname = kcu.tabname
    JOIN syscat.references sr
      ON tc.constname = sr.constname
        AND tc.tabschema = sr.tabschema
        AND tc.tabname = sr.tabname
    WHERE tc.tabschema = ?
      AND tc.type = 'F'
    ORDER BY tc.tabname, tc.constname, kcu.colseq
  });

  my $ok = eval { $sth->execute($schema); 1 };
  return \%fks unless $ok;

  # Collect the flat rows (one per FK column, in colseq order) and group them by
  # constraint via the core ordered aggregator, which preserves column order
  # within each FK.
  my @rows;
  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{tabname} };
    $row->{_grp} = $row->{tabname} . "\0" . $row->{constname};
    push @rows, $row;
  }
  my $groups = DBIO::Introspect::Base->_aggregate_by_ordered(\@rows, '_grp');

  # Columns of the referenced key: SYSCAT.REFERENCES.REFKEYNAME names the
  # parent's key (primary key or UNIQUE constraint) in REFTABSCHEMA.REFTABNAME,
  # and SYSCAT.KEYCOLUSE holds its columns in COLSEQ order. Resolving the
  # parent's primary key instead gave the wrong columns for an FK onto a
  # UNIQUE constraint (karr k45).
  my $key_sth = $dbh->prepare(q{
    SELECT colname, colseq
    FROM syscat.keycoluse
    WHERE constname = ? AND tabschema = ? AND tabname = ?
    ORDER BY colseq
  });

  for my $pair (@$groups) {
    my ($key, $group) = @$pair;
    my $first = $group->[0];
    my $fk = {
      constraint_name => $first->{constname},
      from_table   => $first->{tabname},
      from_columns => [ map { $_->{colname} } @$group ],
      to_table     => $first->{reftabname},
      to_schema    => $first->{reftabschema},
      to_columns   => [],
      on_update    => _rule($first->{updaterule}),
      on_delete    => _rule($first->{deleterule}),
    };

    my @to_cols;
    if (eval { $key_sth->execute($first->{refkeyname}, $fk->{to_schema}, $fk->{to_table}); 1 }) {
      while (my $r = $key_sth->fetchrow_hashref) {
        push @to_cols, $r->{colname};
      }
    }
    $fk->{to_columns} = \@to_cols;
    push @{ $fks{ $fk->{from_table} } }, $fk;
  }

  return \%fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect::ForeignKeys - Introspect DB2 foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches foreign-key metadata via C<SYSCAT.TABCONST> joined with
C<SYSCAT.KEYCOLUSE> and C<SYSCAT.REFERENCES>. Composite FKs are
grouped by constraint name.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::DB2::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

Returns a hashref keyed by table name, each value an arrayref of FK
hashrefs with: C<constraint_name>, C<from_columns>, C<to_table>,
C<to_columns>, C<on_update>, C<on_delete>. C<to_columns> are the columns of the
key the FK references (C<SYSCAT.REFERENCES.REFKEYNAME>): the parent's primary
key or one of its C<UNIQUE> constraints. C<constraint_name> is the
canonical FK key blessed by core ADR 0021.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
