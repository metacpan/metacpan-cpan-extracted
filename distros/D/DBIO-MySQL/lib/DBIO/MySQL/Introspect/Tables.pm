package DBIO::MySQL::Introspect::Tables;
# ABSTRACT: Introspect MySQL/MariaDB tables and views

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::MySQL::Identifier qw(quote_ident);



sub fetch {
  my ($class, $dbh) = @_;

  my $sth = $dbh->prepare(q{
    SELECT
      table_name      AS name,
      table_type      AS table_type,
      engine          AS engine,
      table_collation AS table_collation,
      row_format      AS row_format,
      table_comment   AS comment
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
    ORDER BY table_name
  });
  $sth->execute;

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $kind = ($row->{table_type} // '') eq 'VIEW' ? 'view' : 'table';
    $tables{ $row->{name} } = {
      table_name      => $row->{name},
      kind            => $kind,
      engine          => $row->{engine},
      table_collation => $row->{table_collation},
      row_format      => $row->{row_format},
      comment         => $row->{comment},
    };
  }

  # The definition of every view, without the name of this database in front
  # of the names the server qualified (see above).
  if (grep { $_->{kind} eq 'view' } values %tables) {
    my ($database) = $dbh->selectrow_array('SELECT DATABASE()');
    my $qualifier  = defined $database ? quote_ident($database) . '.' : '';
    my $views = $dbh->selectall_arrayref(
      q{SELECT table_name, view_definition FROM information_schema.views
        WHERE table_schema = DATABASE()});
    for my $view (@$views) {
      my ($name, $def) = @$view;
      next unless $tables{$name} && $tables{$name}{kind} eq 'view';
      $def =~ s/\Q$qualifier\E//g if defined $def && length $qualifier;
      $tables{$name}{view_definition} = $def;
    }
  }
  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::Tables - Introspect MySQL/MariaDB tables and views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches MySQL/MariaDB table and view metadata from
C<information_schema.tables>, scoped to the current C<DATABASE()>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::MySQL::Introspect::Tables->fetch($dbh);

Returns a hashref keyed by table name. Each value is a hashref with keys:
C<table_name>, C<kind> (C<table> or C<view>), C<engine>,
C<table_collation>, C<row_format>, C<comment>.

A view carries a further key, C<view_definition>: the C<SELECT> the server
holds for it (C<information_schema.views>), with the name of the current
database taken out of every qualified name. The server writes
C<< `db`.`table`.`column` >> into the definition it keeps, so a view made in a
temporary database -- the target of an upgrade -- would never equal the same
view in the live one, and the statement the diff creates the view with would
read from the database it was introspected in.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
