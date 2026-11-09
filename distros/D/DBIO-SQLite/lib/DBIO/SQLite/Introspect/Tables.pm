package DBIO::SQLite::Introspect::Tables;
# ABSTRACT: Introspect SQLite tables and views

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();
use DBIO::SQLite::Util qw(create_name_index create_table_name_index sql_tokens);



sub fetch {
  my ($class, $dbh) = @_;

  $class->_refuse_attached_databases($dbh);

  my $sth = $dbh->prepare(q{
    SELECT name, type, sql
    FROM sqlite_master
    WHERE type IN ('table', 'view')
      AND name NOT LIKE 'sqlite_%'
    ORDER BY name
  });
  $sth->execute;

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $sql = $row->{sql} // '';

    my ($without_rowid, $strict) = _table_options($sql);

    $tables{ $row->{name} } = {
      table_name    => $row->{name},
      kind          => $row->{type},
      sql           => $sql,
      without_rowid => $without_rowid,
      strict        => $strict,
    };
  }

  $class->_drop_shadow_tables($dbh, \%tables);

  return \%tables;
}

# (without_rowid, strict) of a stored statement, each 1 or 0: the two options
# a CREATE TABLE may carry behind the closing parenthesis of its column list,
# in either order and any letter case -- `) WITHOUT ROWID, STRICT`. They are
# read there, with the driver's lexer, and nowhere else: a column named
# "strict", a default 'WITHOUT ROWID' or a view that selects such a string is
# not an option. A view and a virtual table have neither.
#
# Two regular expressions over the whole statement used to do this. The one
# for STRICT wanted it directly behind the parenthesis and at the end, and so
# missed it beside WITHOUT ROWID in both orders; the one for WITHOUT ROWID
# found the words anywhere, in a string or a quoted name as well (karr k72).
sub _table_options {
  my ($sql) = @_;
  my @tokens = sql_tokens($sql);
  my $at     = create_table_name_index(\@tokens);
  return (0, 0) unless defined $at;

  # Behind the name: the column list, to its own closing parenthesis.
  my $depth = 0;
  for ($at++; $at <= $#tokens; $at++) {
    my ($kind, $text) = @{ $tokens[$at] };
    next unless $kind eq 'punct';
    $depth++ if $text eq '(';
    $depth-- if $text eq ')';
    last if $text eq ')' && $depth == 0;
  }

  my @words = map { uc $_->[1] } grep { $_->[0] eq 'word' } @tokens[ $at + 1 .. $#tokens ];
  my $without_rowid = grep {
    $words[$_] eq 'WITHOUT' && ($words[ $_ + 1 ] // '') eq 'ROWID'
  } 0 .. $#words;
  my $strict = grep { $_ eq 'STRICT' } @words;
  return ($without_rowid ? 1 : 0, $strict ? 1 : 0);
}


sub _refuse_attached_databases {
  my ($class, $dbh) = @_;

  my $list = $dbh->selectall_arrayref('PRAGMA database_list', { Slice => {} });
  my @attached =
    grep { $_ ne 'main' && $_ ne 'temp' }
    map  { $_->{name} // '' } @$list;

  return unless @attached;

  Carp::croak(
    'refusing to introspect: this SQLite handle has attached database(s) '
    . join(', ', map { "'$_'" } @attached)
    . ". Introspection reads only main's sqlite_master, so every table in an "
    . 'attached database is invisible here. A deploy diff would then read those '
    . 'tables as missing and emit CREATE TABLE for them in main, shadowing the '
    . 'real, still-populated attached tables with fresh empty ones in main -- '
    . 'silent data loss. Introspect a handle without attached databases.'
  );
}

# Remove the shadow tables of virtual tables from an already-collected
# sqlite_master result. Restricted to schema 'main' on purpose: sqlite_master
# without a schema prefix is main's, so anything table_list reports for an
# ATTACHed database describes names this fetch never collected.
sub _drop_shadow_tables {
  my ($class, $dbh, $tables) = @_;

  my ($version, $numeric) = _libsqlite_version($dbh);

  if ($numeric < 3_037_000) {
    # A virtual table is known by how its stored statement begins, read with
    # the driver's lexer as DBIO::SQLite::Diff reads it. The words anywhere
    # else -- in a default, a comment, a view's SELECT -- make none, and no
    # refusal (karr k53).
    my ($virtual) = sort grep {
      my @tokens = sql_tokens($tables->{$_}{sql} // '');
      defined create_name_index(\@tokens, 'VIRTUAL', 'TABLE');
    } keys %$tables;

    # No virtual table, no shadow tables, nothing to classify.
    return unless defined $virtual;

    Carp::croak(
      "cannot introspect virtual table '$virtual' on libsqlite $version: "
      . 'identifying its shadow tables needs PRAGMA table_list (libsqlite '
      . '3.37+). Without it the shadow tables could only be guessed from '
      . 'their names, and a wrong guess is worse than no answer: SQLite drops '
      . 'the shadow tables together with the virtual table, so every '
      . 'additional DROP TABLE the diff emits fails with "no such table" and '
      . 'the non-transactional DDL run aborts partway through'
    );
  }

  my $list = $dbh->selectall_arrayref('PRAGMA table_list', { Slice => {} });
  for my $entry (@$list) {
    next unless ($entry->{schema} // '') eq 'main';
    next unless ($entry->{type}   // '') eq 'shadow';
    delete $tables->{ $entry->{name} };
  }

  return;
}

# Returns the libsqlite version as ($string, $comparable_integer). Compared
# numerically per component, never as text: "3.9" lt "3.37" is true as a
# string and false as a version.
sub _libsqlite_version {
  my ($dbh) = @_;
  my ($version) = $dbh->selectrow_array('SELECT sqlite_version()');
  my @part = split /\./, ($version // '0');
  return (
    $version // '(unknown)',
    ($part[0] // 0) * 1_000_000 + ($part[1] // 0) * 1_000 + ($part[2] // 0),
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect::Tables - Introspect SQLite tables and views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches SQLite table and view metadata from C<sqlite_master>. Skips
internal C<sqlite_*> objects and the B<shadow tables> of virtual tables.

The shadow tables matter because C<sqlite_master> gives them away as nothing
special: an FTS5 table C<docs> stores itself in C<docs_config>,
C<docs_content>, C<docs_data>, C<docs_docsize> and C<docs_idx>, all listed as
C<type = 'table'> with names no filter on C<sqlite_%> catches. Carried into the
model they become six user tables where there is one, and a diff that drops
C<docs> emits a C<DROP TABLE> for each of them. Only the first one works:
SQLite removes the shadow tables together with the virtual table, so the five
that follow fail with C<no such table>. L<DBIO::SQLite::Deploy>'s DDL loop is
non-transactional, so the upgrade aborts midway, after the first C<DROP> has
already run.

So the shadow tables stay out of the model, and a cascade SQLite performs by
itself is never emitted a second time as separate statements. The virtual
table itself stays in the model -- it is a user object -- and keeps C<< kind => 'table' >>, which is what
C<sqlite_master> reports for it.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::SQLite::Introspect::Tables->fetch($dbh);

Returns a hashref keyed by table name. Each value is a hashref with
keys: C<table_name>, C<kind> (C<table> or C<view>), C<sql> (the original
C<CREATE> statement from C<sqlite_master>), C<without_rowid>, C<strict>.

C<without_rowid> and C<strict> are 1 when the table's statement carries that
option behind the closing parenthesis of its column list -- C<WITHOUT ROWID>,
C<STRICT>, both in either order, in any letter case -- and 0 otherwise, for a
view and a virtual table always. The words are read at that place only, so a
column named C<strict> or a string that holds C<WITHOUT ROWID> sets neither.

C<sqlite_master> stays the source of the names and of every field; C<PRAGMA
table_list> (libsqlite 3.37+) is used only as a classifier, to learn which of
those names are shadow tables of the C<main> schema.

C<sqlite_master> without a schema prefix is C<main>'s alone, so a table living
in a database brought in with C<ATTACH> is invisible here. This refuses that
case up front rather than describing a database it cannot see: a diff that took
this partial model at face value would treat every attached table as missing
and emit C<CREATE TABLE> for it in C<main>, shadowing the real, still-populated
attached table with a fresh empty one -- silent data loss. See
L</_refuse_attached_databases>.

On a libsqlite older than 3.37 there is no classifier, and this croaks --
B<but only if the database actually holds a virtual table>. Without one there
are no shadow tables, so nothing is at stake and the behaviour is exactly what
it always was. With one, the shadow tables could only be guessed from their
names, and a wrong guess is not a missing feature but the unexecutable
C<DROP> chain described above; refusing loudly is the lesser harm.

=head2 _refuse_attached_databases

Croaks if the handle carries any C<ATTACH>ed database, before a single row of
C<sqlite_master> is read.

C<fetch> reads only C<main>'s C<sqlite_master>, so tables in an attached
database are simply not in the model it returns. Left to run, that partial
model is worse than an error: the deploy diff reads the attached tables as
B<missing> and emits C<CREATE TABLE> for them in C<main>. The C<CREATE>
succeeds, an empty table in C<main> now shadows the populated attached one, and
an unqualified C<SELECT> reads the empty copy while the data sits untouched in
the attached database -- silent, error-free data loss.

C<PRAGMA database_list> names every schema on the handle and is available in
every libsqlite, so no version gate is needed. C<main> and C<temp> are the
connection's own schemas, not attachments, and are allowed; anything else is an
C<ATTACH>, and the introspection refuses it, naming the attached databases.
The model covers the schemas of the connection itself.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
