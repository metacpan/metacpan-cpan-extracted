package DBIO::DB2::Introspect::Tables;
# ABSTRACT: Introspect DB2 tables and views

use strict;
use warnings;

our $VERSION = '0.900004';


# SYSCAT.VIEWS.TEXT is the whole CREATE VIEW statement as it was written:
# CREATE VIEW <name> [(columns)] AS <select>. The view's name, with the schema
# in front when the statement had one, is cut off, so the view of the live
# schema and that of the compare schema (ADR 0006) compare by what they read.
my $IDENT = qr/"(?:[^"]|"")*"|[A-Za-z_][\w\$#@]*/;

sub _view_definition {
  my ($text) = @_;
  return undef unless defined $text;
  $text =~ s/\A\s+//;
  $text =~ s/[\s;]+\z//;
  return $text =~ /\ACREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+(?:$IDENT\s*\.\s*)?$IDENT\s*(.*)\z/is
    ? $1 : undef;
}


sub fetch {
  my ($class, $dbh, $schema) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys

  my $sth = $dbh->prepare(q{
    SELECT t.tabname, t.type, t.tabschema,
           CASE WHEN t.type = 'V'
                THEN (SELECT CAST(v.text AS VARCHAR(32000))
                      FROM syscat.views v
                      WHERE v.viewschema = t.tabschema AND v.viewname = t.tabname
                      FETCH FIRST 1 ROW ONLY)
           END AS view_text
    FROM syscat.tables t
    WHERE t.tabschema = ?
    ORDER BY t.tabname
  });
  # No tabname filter, deliberately: a `NOT LIKE 'EX%'` here once hid real
  # user tables (EXPENSES, EXPORT, ...) and ghosted them into every diff as
  # phantom CREATE TABLE (SQL0601N). The EXPLAIN_* tables that filter was
  # aimed at live in SYSTOOLS (SYSINSTALLOBJECTS, karr k27), a schema this
  # query never reads -- tabschema is the only scope.
  $sth->execute($schema);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    # syscat.tables.type is a single char: 'V' = view, 'T' = table, etc.
    my $type = uc($row->{type} // '');
    my $kind = $type eq 'V' ? 'view' : 'table';
    $tables{ $row->{tabname} } = {
      table_name => $row->{tabname},
      kind       => $kind,
      schema     => $row->{tabschema},
      ($kind eq 'view' ? (view_definition => _view_definition($row->{view_text})) : ()),
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect::Tables - Introspect DB2 tables and views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches DB2 table and view metadata via C<SYSCAT.TABLES>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::DB2::Introspect::Tables->fetch($dbh, $schema);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>), C<schema>. A view also has C<view_definition>,
what C<SYSCAT.VIEWS.TEXT> holds of the C<CREATE VIEW> statement after the
view's name (C<AS SELECT ...>, with the column list in front when it was
written with one); undef when the text is not of that shape (ADR 0011).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
