package DBIO::Oracle::Introspect::Views;
# ABSTRACT: Introspect the definitions of Oracle views

use strict;
use warnings;

our $VERSION = '0.900004';


use constant LONG_READ_LEN => 16 * 1024 * 1024;


sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $tables //= {};

  my %views;
  return \%views unless grep { ( $_->{kind} // '' ) eq 'view' } values %$tables;

  local $dbh->{LongReadLen} = LONG_READ_LEN;
  local $dbh->{LongTruncOk} = 0;

  my $sth = $dbh->prepare(q{
    SELECT view_name, text
    FROM all_views
    WHERE owner = ?
    ORDER BY view_name
  });
  $sth->execute($schema);

  while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
    my $name = $row->{view_name};
    next unless ( $tables->{$name}{kind} // '' ) eq 'view';
    $views{$name} = { view_name => $name, definition => $row->{text}, columns => [], depends_on => [] };
  }

  # The names of the columns, in order: the text of a view does not hold the
  # ones a column list gave (karr k65).
  my $csth = $dbh->prepare(q{
    SELECT table_name, column_name
    FROM all_tab_columns
    WHERE owner = ? AND column_id IS NOT NULL
    ORDER BY table_name, column_id
  });
  $csth->execute($schema);
  while (my $c = $csth->fetchrow_hashref('NAME_lc')) {
    my $v = $views{ $c->{table_name} } or next;
    push @{ $v->{columns} }, $c->{column_name};
  }

  # The views a view rests on (karr k65): bare when in this schema, else
  # owner.view. The diff orders the views by it.
  my $dsth = $dbh->prepare(q{
    SELECT name, referenced_owner, referenced_name
    FROM all_dependencies
    WHERE owner = ? AND type = 'VIEW' AND referenced_type = 'VIEW'
    ORDER BY name, referenced_owner, referenced_name
  });
  $dsth->execute($schema);
  while (my $d = $dsth->fetchrow_hashref('NAME_lc')) {
    my $v = $views{ $d->{name} } or next;
    push @{ $v->{depends_on} },
      $d->{referenced_owner} eq $schema ? $d->{referenced_name}
                                        : "$d->{referenced_owner}.$d->{referenced_name}";
  }

  return \%views;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect::Views - Introspect the definitions of Oracle views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches the defining query of the views of a schema from C<all_views.text>,
the part of the model L<DBIO::Oracle::Diff::View> compares and writes C<CREATE
OR REPLACE VIEW> from. The text is what Oracle stores, not what was written:
see L<DBIO::Oracle::Diff::View/DESCRIPTION> for what it rewrites.

C<text> is a C<LONG> column, so C<LongReadLen> is raised to 16 MiB for the
fetch (set before the statement is prepared, when DBD::Oracle sizes the
buffer) and C<LongTruncOk> is off: a definition that does not fit ends the
fetch with an error instead of being cut. The setting of the handle is
restored afterwards.

=head1 METHODS

=head2 fetch

    my $views = DBIO::Oracle::Introspect::Views->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Oracle::Introspect::Tables>, returns a
hashref keyed by view name, for each table of C<kind> C<view>:
C<< { view_name => $name, definition => $text, columns => \@names, depends_on => \@views } >>.
C<definition> is C<undef> when the server gives no text. C<columns> lists the
names of the columns of the view in C<COLUMN_ID> order, as Oracle has them
(from C<all_tab_columns>): the text does not hold the names a column list
C<CREATE VIEW v (a, b) AS ...> gave, and the diff writes them back. C<depends_on> lists
the views the view rests on, from C<all_dependencies>: a view of this schema
by its bare name, one of another schema as C<owner.view>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
