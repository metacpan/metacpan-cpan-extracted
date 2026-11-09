package DBIO::Informix::Storage;
# ABSTRACT: Base Storage Class for Informix Support

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->register_driver('Informix' => __PACKAGE__);

use Context::Preserve 'preserve_context';
use DBI ();
use Scalar::Util ();
use DBIO::Exception ();
use DBIO::Informix::Types qw(lob_kind is_numeric_type);
use namespace::clean;

__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type (
  'DBIO::Informix::Storage::DateTime::Format'
);
__PACKAGE__->sql_maker_class('DBIO::Informix::SQLMaker');

sub dbio_deploy_class { 'DBIO::Informix::Deploy' }


sub deploy_setup { }


sub _connect {
  my $self = shift;
  local $ENV{DELIMIDENT} = 'y';
  return $self->next::method(@_);
}


# ADR 0026 (karr k23) -- DDL in a LOGGED Informix database is part of the
# transaction and is undone by ROLLBACK. Measured against Informix 15.0.1:
# CREATE TABLE, DROP TABLE, ALTER TABLE ADD / DROP / MODIFY of a column,
# ADD / DROP CONSTRAINT FOREIGN KEY, CREATE [UNIQUE] INDEX, DROP INDEX,
# CREATE VIEW, RENAME COLUMN and RENAME TABLE, each issued after BEGIN WORK,
# were all taken back by ROLLBACK WORK (t/65-transactional-ddl.t, live block).
# So core wraps a deploy's DDL loop in txn_do and a failing statement takes
# the earlier ones with it.
#
# The one place it does not hold is an UNLOGGED database (CREATE DATABASE
# without WITH LOG): there BEGIN WORK is SQL -256 "Transaction not available"
# and a connection with AutoCommit off cannot be made at all, so no DBIO
# transaction exists there, DDL or not, and declaring 1 changes nothing for
# it. The answer is therefore a class fact and not a probe of
# sysmaster:sysdatabases.is_logging.
__PACKAGE__->_use_transactional_ddl(1);

# ADR 0037 (karr k23) -- Informix 15.0.1 takes a FROM-less SELECT and takes
# FROM sysmaster:sysdual. Neither is what this hook may rely on: it is a
# static class fact that cannot ask which release it talks to, a FROM-less
# SELECT is not something the older releases are known to take, and sysdual
# is a cross-database reference into sysmaster. systables is in every
# database of every release, and tabid 1 is systables itself, so exactly one
# row. Only the FROM clause is ours; the CASE spelling stays core's.
sub _exists_value_sql {
  my $self = shift;

  return $self->next::method(@_) . ' FROM systables WHERE tabid = 1';
}

__PACKAGE__->_use_supports_exists_query(1);

# ADR 0039 (karr k23) -- UNION, UNION ALL, INTERSECT and EXCEPT are spelled
# as core's base map spells them (all four measured on Informix 15.0.1; MINUS
# is a synonym of EXCEPT). INTERSECT ALL and EXCEPT ALL are SQL -201 there.
# The refusal is unconditional: the hook cannot ask the server's release, and
# no release is known to have them.
my %UNSUPPORTED_SET_OPERATION = map { $_ => 1 } qw(intersect_all except_all);

sub _set_operation_keyword {
  my ($self, $op) = @_;

  $self->throw_exception(
    "Informix cannot express the set operation '$op': it has UNION, UNION ALL, "
  . 'INTERSECT and EXCEPT (MINUS) and only in their distinct forms -- '
  . 'INTERSECT ALL and EXCEPT ALL are a syntax error, SQL -201 (measured on '
  . 'Informix 15.0.1). The refusal holds for every release because this hook '
  . 'chooses the keyword without a connection (ADR 0039 section 7). The '
  . 'distinct forms, INTERSECT and EXCEPT, are available as $rs->intersect '
  . 'and $rs->except.'
  ) if defined $op and $UNSUPPORTED_SET_OPERATION{$op};

  return $self->next::method($op);
}

# ADR 0011 / karr k23 -- Informix 15.0.1 has no random-number function:
# RANDOM(), RAND(), DBMS_RANDOM_RANDOM() and a dbms_random package are all
# SQL -674 "Routine can not be resolved" (and the SQL Syntax reference lists
# no such function among the math functions). Inheriting core's RANDOM()
# would be the same -674 from the server; naming something invented
# (a session id, a clock) would shuffle nothing. So the hook refuses, at
# query-build time, and says why.
sub _random_function {
  my $self = shift;

  $self->throw_exception(
    'Informix has no random-number function, so $rs->rand cannot order by '
  . 'one: RANDOM(), RAND() and DBMS_RANDOM are all SQL -674 (routine can not '
  . 'be resolved) on Informix 15.0.1. A random function has to exist on the '
  . 'server first (an SPL or UDR routine of your own), and can then be '
  . 'ordered by through the order_by attribute.'
  );
}

# ADR 0040 section 7 (karr k23) -- the engine answers somewhere this seam does
# not reach. Informix has no EXPLAIN statement (core's inherited one is SQL
# -201); its plan facility is SET EXPLAIN ON [AVOID_EXECUTE], which writes the
# plan to the file sqexplain.out on the SERVER. The one place SQL can see a
# plan, sysmaster:syssqexplain, lists the statements running at the moment of
# the query that reads it (measured on 15.0.1: the row's plan is that of the
# query reading the view, the explained statement of a moment earlier is not
# there), so there is no second statement to read a plan back with. Refused
# before any statement is issued; in particular SET EXPLAIN is never turned on
# for the session as a side effect.
sub _explain_query {
  my $self = shift;

  $self->throw_exception(
    'Informix cannot return a query plan as rows: it has no EXPLAIN '
  . 'statement (SQL -201), and SET EXPLAIN ON [AVOID_EXECUTE] writes the plan '
  . 'to the file sqexplain.out on the database server, where no statement of '
  . 'this connection can read it back. sysmaster:syssqexplain shows only the '
  . 'statements running at that moment, not the one explained before. Read '
  . 'the plan from sqexplain.out on the server.'
  );
}

# ADR 0057 (karr k23) -- DBD::Informix takes dbi:Informix:database[@server]
# and nothing else: dbi:Informix:database=x and dbi:Informix:dbname=x;server=y
# are SQL -354. What follows the @ is a DBSERVERNAME of the sqlhosts file,
# not a host name: "database@a.host.name" and "database@server:9088" are both
# SQL -25555 "Server ... is not listed as a dbserver name in sqlhosts".
sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;

  my ($dbname, $host, $port) = @{$params}{qw(dbname host port)};

  my $form = "DBD::$driver connects with dbi:$driver:<database>[\@<server>], "
    . 'where the server is a DBSERVERNAME of the sqlhosts file';

  $self->throw_exception(
    "Cannot build a DBD::$driver DSN from connection parameters without a "
  . "dbname: $form, and a DBIO storage needs a database. Give dbname, or "
  . 'supply a dsn instead.'
  ) unless defined $dbname;

  $self->throw_exception(
    "Cannot build a DBD::$driver DSN from the connection parameter port: "
  . "$form. The port belongs to that server's entry in sqlhosts and the DSN "
  . 'has no place for it, so a port given here would be dropped and the '
  . 'connection would go wherever sqlhosts says. Leave port out (host is '
  . 'the DBSERVERNAME), or supply a dsn instead.'
  ) if defined $port;

  return defined $host
    ? "dbi:$driver:$dbname\@$host"
    : "dbi:$driver:$dbname";
}

# ADR 0013 addendum (karr k23) -- the HostBound view's seam. The same form,
# the same meaning of the host: the view's host replaces the DBSERVERNAME of
# dbi:Informix:database@server, and a DSN that names none gets it. A view
# that carries a port declines: the DSN cannot say it (see above). Every
# other form -- the key=value one core's default writes included -- is no
# Informix DSN, and declines too. The form is named, never a value.
sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  return (undef, 'a DSN that is not of the form dbi:Informix:database[@server]')
    unless defined $dsn
      and $dsn =~ /\A(dbi:Informix(?:\([^)]*\))?:)([^@;=]*)(?:\@[^;=]*)?\z/is;
  my ($prefix, $database) = ($1, $2);

  return (undef, 'a view with a port; the DSN has no place for a port, it '
    . 'belongs to the server\'s entry in sqlhosts')
    if defined $port;

  return "$prefix$database\@$host";
}


__PACKAGE__->mk_group_accessors('simple' => '__last_insert_id');


sub _execute {
  my $self = shift;
  my ($rv, $sth, @rest) = $self->next::method(@_);

  $self->__last_insert_id($sth->{ix_sqlerrd}[1])
    if $self->_perform_autoinc_retrieval;

  return (wantarray ? ($rv, $sth, @rest) : $rv);
}

sub last_insert_id {
  shift->__last_insert_id;
}



sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;
  my $kind = lob_kind($data_type) or return;
  return $kind eq 'text' ? DBI::SQL_LONGVARCHAR() : DBI::SQL_LONGVARBINARY();
}


sub _gen_sql_bind {
  my ($self, $op, $ident, $args) = @_;

  my ($sql, $bind) = $self->next::method($op, $ident, $args);

  if ($op eq 'select') {
    for my $b (@$bind) {
      my ($info, $v) = @$b;
      next unless ref $info eq 'HASH' and defined $v and !ref $v;
      my $kind = lob_kind($info->{sqlt_datatype}, $info->{sqlt_size}) or next;
      my $column = $info->{dbic_colname} // '?';
      my ($alias) = $column =~ /\A(.*)\.[^.]*\z/;
      $column =~ s/\A.*\.//;
      my $table = $self->_select_table_name($ident, $alias);

      # the other TEXT / BYTE columns of the table, which cannot be compared either
      my %lob;
      for my $name ($self->schema->sources) {
        my $source = $self->schema->source($name);
        next unless !ref $source->name and $source->name eq $table;
        my $infos = $source->columns_info;
        $lob{$_} = 1 for grep { lob_kind($infos->{$_}{data_type}, $infos->{$_}{size}) } $source->columns;
      }
      my $lobs = %lob ? " ($table holds the TEXT or BYTE columns " . join(', ', sort keys %lob) . ')' : '';

      DBIO::Exception->throw(sprintf
        'refusing to compare the %s column %s.%s with a bound value: Informix allows no '
      . 'TEXT or BYTE in a comparison (-615, Blobs are not allowed in this expression; '
      . 'a cast to a character type is refused as well, -9634)%s. Compare a column that is '
      . 'not a TEXT or BYTE.',
        ($kind eq 'text' ? 'TEXT' : 'BYTE'), $table, $column, $lobs);
    }
  }

  $sql = $self->_strip_sql_comments($sql);

  if ($op eq 'insert' and Scalar::Util::blessed($ident)
      and $sql =~ /\A(INSERT INTO .+?) DEFAULT VALUES\z/s) {
    my $head = $1;
    my $infos = $ident->columns_info;
    my ($auto)     = grep { $infos->{$_}{is_auto_increment} } $ident->columns;
    my ($nullable) = grep { $infos->{$_}{is_nullable} } $ident->columns;
    if (defined $auto) {
      $sql = sprintf '%s (%s) VALUES (0)', $head, $self->sql_maker->_quote($auto);
    }
    elsif (defined $nullable) {
      $sql = sprintf '%s (%s) VALUES (NULL)', $head, $self->sql_maker->_quote($nullable);
    }
  }

  return ($sql, $bind);
}

# the table behind an alias of a SELECT's from, for a message
sub _select_table_name {
  my ($self, $ident, $alias) = @_;

  return $ident->name if Scalar::Util::blessed($ident) and $ident->can('name') and !ref $ident->name;

  my %table;
  for my $part (ref $ident eq 'ARRAY' ? @$ident : ()) {
    my $hash = ref $part eq 'ARRAY' ? $part->[0] : $part;
    next unless ref $hash eq 'HASH';
    for my $key (grep { !/\A-/ } keys %$hash) {
      $table{$key} = $hash->{$key} unless ref $hash->{$key};
    }
  }

  return $table{$alias} if defined $alias and defined $table{$alias};
  return (values %table)[0] if keys %table == 1;
  return '?';
}

# /* ... */ comments out of a statement, found by reading the SQL: one in a
# string, an identifier or another comment is not one
sub _strip_sql_comments {
  my ($self, $sql) = @_;
  return $sql unless index($sql, '/*') >= 0;

  my $out = '';
  while ($sql =~ m~\G(?: ('(?:[^']|'')*') | ("(?:[^"]|"")*") | (--[^\n]*(?:\n|\z)) | (\{[^}]*\}) | (/\*\+.*?\*/) | (/\*.*?\*/) | (.) )~gsx) {
    $out .= defined $6 ? ' ' : $&;
  }
  return $out;
}

# A value for a numeric column that is no number (karr k24). DBD::Informix
# hands the server the text of the value, and the server turns '' into NULL
# without a word (a row with a NULL where the caller wrote ''), while 'x' is
# an error (-1213). So that the answer does not depend on the text, a value
# that is no number for a numeric column is refused before the DBD sees it.
# The column is known from the bind's sqlt_datatype; a parameter without it is
# left as the caller wrote it.
sub _adjust_bind_values {
  my ($self, $sth, $bind, $bind_attrs) = @_;

  for my $b (@$bind) {
    my ($info, $v) = @$b;
    next unless ref $info eq 'HASH' and defined $v and !ref $v;
    next unless is_numeric_type($info->{sqlt_datatype});
    next if Scalar::Util::looks_like_number($v);
    DBIO::Exception->throw(sprintf
      q{refusing the value '%s' for the numeric column '%s': it is no number, and Informix would }
    . q{store NULL for '' or answer a conversion error (-1213) for other text},
      $v, $info->{dbic_colname} // '?');
  }

  return $self->next::method($sth, $bind, $bind_attrs);
}

sub _exec_svp_begin {
    my ($self, $name) = @_;

    $self->_dbh->do("SAVEPOINT $name");
}

# can't release savepoints
sub _exec_svp_release { 1 }

sub _exec_svp_rollback {
    my ($self, $name) = @_;

    $self->_dbh->do("ROLLBACK TO SAVEPOINT $name")
}

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('SET CONSTRAINTS ALL DEFERRED');

  # constraint mode ends with the transaction: IMMEDIATE after the COMMIT is
  # -255 "Not in transaction". Before it, it also runs the deferred checks.
  return preserve_context { $sub->() } after => sub {
    $self->_do_query('SET CONSTRAINTS ALL IMMEDIATE');
    $txn_scope_guard->commit;
  };
}



sub connect_call_datetime_setup {
  my $self = shift;

  delete @ENV{qw/DBDATE DBCENTURY/};

  $ENV{GL_DATE}     = "%m/%d/%Y";
  $ENV{GL_DATETIME} = "%Y-%m-%d %H:%M:%S.%F5";
}


package DBIO::Informix::Storage::DateTime::Format;

use base 'DBIO::Storage::DateTimeFormat';

# No preferred_format_class: there is no maintained DateTime::Format::Informix.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%5N'); # %F %T
__PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%5N');
__PACKAGE__->date_parse_pattern('%m/%d/%Y');
__PACKAGE__->date_format_pattern('%m/%d/%Y');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Storage - Base Storage Class for Informix Support

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Storage driver for IBM Informix databases. Implements autoincrement column
retrieval via the C<ix_sqlerrd> statement handle attribute, savepoint support,
deferred foreign key checks via C<SET CONSTRAINTS>, and datetime formatting
using L<DateTime::Format::Strptime>. Uses the C<SkipFirst> SQL limit dialect
and double-quote quoting. DDL is transactional (in a logged database), so a
failing deploy is rolled back whole.

=head1 METHODS

=head2 deploy_setup

No-op stub to satisfy the L<DBIO::Storage::DBI> interface. Informix does not
require special setup for deployments.

=head2 _connect

Sets C<DELIMIDENT=y> in the environment for the duration of the connect.
The storage quotes identifiers with C<">, and Informix reads a double-quoted
token as an identifier only when C<DELIMIDENT> is set at connect time;
without it every quoted statement is a C<-201> syntax error. The caller's
environment is left as it was.

=head2 _exists_value_sql

The statement behind C<results_exist> (ADR 0037): core's C<CASE WHEN EXISTS>
with C<FROM systables WHERE tabid = 1> appended, the one-row selection every
Informix database has. Together with the declared C<supports_exists_query>
capability.

=head2 _set_operation_keyword

C<UNION>, C<UNION ALL>, C<INTERSECT> and C<EXCEPT> are core's ANSI spelling.
C<intersect_all> and C<except_all> are refused (ADR 0039): Informix answers
C<INTERSECT ALL> and C<EXCEPT ALL> with SQL -201.

=head2 _random_function

Refuses. Informix has no random-number function (SQL -674 for C<RANDOM()>,
C<RAND()> and C<DBMS_RANDOM>), so C<< $rs->rand >> throws, saying why.

=head2 _explain_query

Refuses (ADR 0040 section 7). Informix writes a plan only to the file
F<sqexplain.out> on the server (C<SET EXPLAIN>), where no statement of the
connection can read it back, so C<< $rs->explain >> throws before any
statement is issued.

=head2 _connect_params_dsn

The DSN of connection parameters (ADR 0057): C<dbi:Informix:database> or, with
a C<host>, C<dbi:Informix:database@host>, where the host is the
C<DBSERVERNAME> of the F<sqlhosts> file. A C<port> is refused -- it belongs
to the F<sqlhosts> entry -- as is a missing C<dbname>.

=head2 _bind_host_into_dsn

The seam of a L<DBIO::AccessBroker::HostBound> view: replaces (or adds) the
server of C<dbi:Informix:database[@server]>. A view with a port and any other
form of DSN decline.

=head2 last_insert_id

Returns the last autoincrement value inserted into the database, retrieved
from the C<ix_sqlerrd> attribute of the most recently executed statement
handle.

=head2 bind_attribute_by_data_type

A TEXT or BYTE column takes a parameter only when the statement is told the
type: an C<UPDATE ... SET t = ?> with a plain parameter dies with -608
(I<Illegal attempt to convert Text/Byte blob type>). C<text> and the like are
bound as C<SQL_LONGVARCHAR>, C<blob> and the like as C<SQL_LONGVARBINARY>
(measured, Informix 15.0.1, DBD::Informix 2018.1031).

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Runs the supplied coderef with all foreign key constraints set to
C<DEFERRED>. Constraints are restored to C<IMMEDIATE> after the coderef,
before the commit (which is when the deferred checks run), and the enclosing
transaction is committed.

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set the C<DATE> and
C<DATETIME> formats.

Sets the following environment variables:

    GL_DATE="%m/%d/%Y"
    GL_DATETIME="%Y-%m-%d %H:%M:%S.%F5"

The C<DBDATE> and C<DBCENTURY> environment variables are cleared.

B<NOTE:> setting the C<GL_DATE> environment variable seems to have no effect
after the process has started, so the default format is used. The C<GL_DATETIME>
setting does take effect however.

The C<DATETIME> data type supports up to 5 digits after the decimal point for
second precision, depending on how you have declared your column. The full
possible precision is used.

The column declaration for a C<DATETIME> with maximum precision is:

  column_name DATETIME YEAR TO FRACTION(5)

The C<DATE> data type stores the date portion only, and it B<MUST> be declared
with:

  data_type => 'date'

in your Result class.

You will need the L<DateTime::Format::Strptime> module for inflation to work.

=head2 Statements rewritten or refused before the DBD

C<_gen_sql_bind> looks at the statement the SQL maker wrote:

=over 4

=item * a C</* ... */> comment is removed (a C<?> in it is counted as a
placeholder by DBD::Informix, -254; C<{ ... }> and C<--> comments and
C</*+ ... */> optimizer directives are left alone);

=item * C<INSERT INTO t DEFAULT VALUES>, which Informix does not know (-201),
becomes C<INSERT INTO t (id) VALUES (0)> for a source with an
auto-increment column (a C<SERIAL> takes the next value for 0), else
C<INSERT INTO t (c) VALUES (NULL)> for its first nullable column;

=item * a value bound against a TEXT or BYTE column of a C<SELECT> is
refused with a L<DBIO::Exception> that names table and column: Informix
allows neither in a comparison (-615, I<Blobs are not allowed in this
expression>), not even cast to a character type (-9634).

=back

=head1 SEE ALSO

=over

=item * L<DBIO::Informix> - Informix schema component

=item * L<DBIO::Storage::DBI> - Base DBI storage class

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
