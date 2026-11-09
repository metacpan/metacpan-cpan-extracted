package DBIO::DB2::Introspect::UniqueConstraints;
# ABSTRACT: Introspect DB2 unique constraints

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys
  my %ucs = map { $_ => [] } keys %$tables;

  my $sth = $dbh->prepare(q{
    SELECT tc.tabname, tc.constname, kcu.colname, kcu.colseq
    FROM syscat.tabconst tc
    JOIN syscat.keycoluse kcu
      ON tc.constname = kcu.constname
        AND tc.tabschema = kcu.tabschema
        AND tc.tabname = kcu.tabname
    WHERE tc.tabschema = ?
      AND tc.type = 'U'
    ORDER BY tc.tabname, tc.constname, kcu.colseq
  });
  $sth->execute($schema);

  my (%by_name, @order);
  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{tabname} };
    my $key = join "\0", $row->{tabname}, $row->{constname};
    push @order, [ $row->{tabname}, $row->{constname} ] unless $by_name{$key};
    push @{ $by_name{$key} }, $row->{colname};
  }
  push @{ $ucs{ $_->[0] } }, [ $_->[1], $by_name{ join "\0", @$_ } ] for @order;

  return \%ucs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect::UniqueConstraints - Introspect DB2 unique constraints

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches the C<UNIQUE> constraints of a schema: C<SYSCAT.TABCONST> rows of type
C<U> with their columns from C<SYSCAT.KEYCOLUSE>. The primary key (type C<P>)
is not one, and neither is a unique index made with C<CREATE UNIQUE INDEX>.

Db2 keeps an index of the constraint's name behind each constraint
(C<SYSCAT.INDEXES>, C<system_required> 1). That index is the constraint, not a
second object: L<DBIO::DB2::Introspect::Indexes> leaves it out (ADR 0009).

=head1 METHODS

=head2 fetch

    my $ucs = DBIO::DB2::Introspect::UniqueConstraints->fetch($dbh, $schema, $tables);

Returns the C<unique_constraints> section of the model as
L<DBIO::Introspect::Base> defines it: a hashref keyed by table name, each value
an arrayref of C<[ $constraint_name, \@columns ]> pairs, the columns in key
order (C<COLSEQ>). Every table of C<$tables> has an entry, an empty one for a
table without constraints.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
