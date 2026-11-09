use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::AccessBroker;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;
use DBIO::Storage::DBI;

# OFFLINE test (karr k98, the follow-up of core karr k276). A HostBound view
# of an AccessBroker puts its host (and port) into the DSN of the answer it
# wraps, so that a replicant connects to its own server on the credentials of
# the master. How a DSN names its server is the DBD's business and core knows
# one form, host= and port=. DBD::mysql and DBD::MariaDB read another as well:
# `dbi:mysql:database:host:port`, whose parts that are not key=value fill
# database, host and port in that order. Without a seam of its own the core
# default refuses that form (the safe answer, but the replicant of such a DSN
# can never be used); with a wrong one a replicant would connect to the master.
#
# Held:
#   1. the positional form is bound: host replaced or added, port replaced or
#      added when the view has one and kept when it has not, the database and
#      the DSN prefix (with its attributes) untouched;
#   2. what is bound is what the DBD reads: DBD::mysql's own parser, where
#      installed, finds the view's host and port and the same database;
#   3. the key form still goes through core's default (host=, port=);
#   4. what cannot be bound without guessing is refused, the refusal names the
#      form and never a value of the DSN: a socket key (the host would be
#      ignored, the replicant would reach the local server), a positional part
#      next to key=value parts or semicolons, more than three positional parts;
#   5. the MariaDB storage and the DBD::MariaDB prefix take the same seam;
#   6. through a storage the view connects with the bound DSN, and the
#      refused forms never reach DBI->connect.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T111::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

{
  package T111::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T111::Handle->new };
}

my $STORAGE = 'DBIO::MySQL::Storage';

sub bind_dsn {
  my ($dsn, $host, $port, $class) = @_;
  return ($class || $STORAGE)->_bind_host_into_dsn('mysql', $dsn, $host, $port);
}

# ---------------------------------------------------------------------------
# 1. The positional form is bound.
# ---------------------------------------------------------------------------
for my $case (
  [ 'database only',            'dbi:mysql:app',               'dbi:mysql:app:replica.example:6000' ],
  [ 'database and host',        'dbi:mysql:app:master.example', 'dbi:mysql:app:replica.example:6000' ],
  [ 'database, host and port',  'dbi:mysql:app:master.example:3306', 'dbi:mysql:app:replica.example:6000' ],
  [ 'empty database',           'dbi:mysql::master.example',   'dbi:mysql::replica.example:6000' ],
  [ 'attributes in the prefix', 'dbi:mysql(RaiseError=1):app:master.example', 'dbi:mysql(RaiseError=1):app:replica.example:6000' ],
  [ 'upper-case prefix',        'DBI:mysql:app:master.example', 'DBI:mysql:app:replica.example:6000' ],
) {
  my ($label, $dsn, $expected) = @$case;
  my ($got, $form) = bind_dsn($dsn, 'replica.example', 6000);
  is $got, $expected, "$label: host and port of the view are bound";
  ok !defined $form, '... and nothing is declined';
  unlike $got // '', qr/master\.example/, "... the answer's host is gone";
}

{
  my ($got) = bind_dsn('dbi:mysql:app:master.example:3306', 'replica.example', undef);
  is $got, 'dbi:mysql:app:replica.example:3306', "a view without a port keeps the DSN's port";
  ($got) = bind_dsn('dbi:mysql:app:master.example', 'replica.example', undef);
  is $got, 'dbi:mysql:app:replica.example', '... and adds none where there is none';
  ($got) = bind_dsn('dbi:mysql:app:master.example', '::1', 3306);
  is $got, 'dbi:mysql:app:[::1]:3306', 'an IPv6 host is bracketed, as the DBD reads it';
}

# ---------------------------------------------------------------------------
# 2. What is bound is what the DBD reads.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'DBD::mysql is not installed', 8 unless eval { require DBD::mysql; 1 };

  for my $dsn ('app', 'app:master.example', 'app:master.example:3306') {
    my ($bound) = bind_dsn("dbi:mysql:$dsn", 'replica.example', 6000);
    (my $rest = $bound) =~ s/^dbi:mysql://;
    my %read;
    DBD::mysql->_OdbcParse($rest, \%read, [ qw(database host port) ]);
    is_deeply [ @read{qw(database host port)} ], [ 'app', 'replica.example', 6000 ],
      "DBD::mysql reads '$bound' as the view's host and port on the same database";
  }

  my ($bound) = bind_dsn('dbi:mysql:app:master.example', '::1', 6000);
  my %read;
  DBD::mysql->_OdbcParse('app:[::1]:6000', \%read, [ qw(database host port) ]);
  is_deeply [ @read{qw(database host port)} ], [ 'app', '::1', 6000 ],
    'DBD::mysql reads the bracketed IPv6 host as the address';
  is $bound, 'dbi:mysql:app:[::1]:6000', '... which is the form the seam writes';

  # the same holds for the key form through core's default
  my ($key) = bind_dsn('dbi:mysql:database=app;host=master.example;port=3306', 'replica.example', 6000);
  (my $krest = $key) =~ s/^dbi:mysql://;
  my %kread;
  DBD::mysql->_OdbcParse($krest, \%kread, [ qw(database host port) ]);
  is_deeply [ @kread{qw(database host port)} ], [ 'app', 'replica.example', 6000 ],
    'the key form: DBD::mysql reads core default\'s result as the view\'s host and port';
  is $key, 'dbi:mysql:database=app;host=replica.example;port=6000', '... in place';
}

# ---------------------------------------------------------------------------
# 3. The key form is core's.
# ---------------------------------------------------------------------------
{
  my ($got) = bind_dsn('dbi:mysql:database=app;host=master.example', 'replica.example', 6000);
  is $got, 'dbi:mysql:port=6000;database=app;host=replica.example',
    'a key=value DSN without a port: core default binds host= and adds port=';
  ($got) = bind_dsn('dbi:mysql:', 'replica.example', 6000);
  is $got, 'dbi:mysql:port=6000;host=replica.example', 'a DSN without parts gets the key form';
  my ($none, $form) = bind_dsn('master.example', 'replica.example', 6000);
  ok !defined $none && $form =~ /dbi:Driver: prefix/, 'a DSN without prefix is declined by core default';
}

# ---------------------------------------------------------------------------
# 4. What cannot be bound is refused, naming the form and not the DSN.
# ---------------------------------------------------------------------------
for my $case (
  [ 'mysql_socket',             'dbi:mysql:database=app;mysql_socket=/run/mysqld/private.sock',
    qr/'mysql_socket'/ ],
  [ 'mariadb_socket',           'dbi:MariaDB:database=app;MARIADB_SOCKET=/run/mysqld/private.sock',
    qr/'MARIADB_SOCKET'/ ],
  [ 'socket beside a host',     'dbi:mysql:database=app;host=master.example;mysql_socket=/run/mysqld/private.sock',
    qr/'mysql_socket'/ ],
  [ 'positional beside keys',   'dbi:mysql:app;host=master.example',
    qr/positional part beside key=value/ ],
  [ 'positional beside colon and keys', 'dbi:mysql:app:master.example;port=3306',
    qr/positional part beside key=value/ ],
  [ 'positional with semicolon', 'dbi:mysql:app;master.example',
    qr/positional part beside a semicolon/ ],
  [ 'too many positional parts', 'dbi:mysql:app:master.example:3306:extra',
    qr/more than database, host and port/ ],
) {
  my ($label, $dsn, $form_re) = @$case;
  my ($got, $form) = bind_dsn($dsn, 'replica.example', 6000);
  ok !defined $got, "$label: no DSN is handed on";
  like $form // '', $form_re, '... and the refusal names the form';
  unlike $form // '', qr/master\.example|private\.sock|replica\.example|\bapp\b/,
    '... without a value of the DSN or the view';
}

# ---------------------------------------------------------------------------
# 5. The MariaDB storage and DBD.
# ---------------------------------------------------------------------------
{
  my ($got) = bind_dsn('dbi:MariaDB:app:master.example:3306', 'replica.example', 6000,
    'DBIO::MySQL::Storage::MariaDB');
  is $got, 'dbi:MariaDB:app:replica.example:6000', 'the MariaDB storage binds the positional form of dbi:MariaDB:';
  my ($again) = bind_dsn('dbi:MariaDB:app:master.example:3306', 'replica.example', 6000);
  is $again, $got, '... and the MySQL storage reads the same DSN the same way (DBD, not product)';
}

# ---------------------------------------------------------------------------
# 6. Through a view and a storage.
# ---------------------------------------------------------------------------
sub connect_through {
  my ($storage, $view) = @_;
  return eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";
}

for my $class ($STORAGE, 'DBIO::MySQL::Storage::MariaDB') {
  my $dbd = $class eq $STORAGE ? 'mysql' : 'MariaDB';
  my $view = T111::Broker->new([ "dbi:$dbd:app:master.example:3306", 'k98-user', 'k98-pw', {} ])
    ->for_host({ host => 'replica.example', port => 6000 });
  my $storage = $class->new(undef);
  local @CONNECTS;

  my $error = connect_through($storage, $view);

  ok !defined $error, "$class: a view over a positional DSN connects" or diag $error;
  is $CONNECTS[0][0], "dbi:$dbd:app:replica.example:6000", '... with the view\'s host and port bound';
  is_deeply [ @{ $CONNECTS[0] }[1, 2] ], [ 'k98-user', 'k98-pw' ], '... on the credentials of the answer';
}

{
  my $view = T111::Broker->new([ 'dbi:mysql:database=app;mysql_socket=/run/mysqld/private.sock', 'k98-user', 'k98-pw', {} ])
    ->for_host({ host => 'replica.example', port => 6000 });
  my $storage = $STORAGE->new(undef);
  local @CONNECTS;

  my $error = connect_through($storage, $view);

  ok defined $error, 'a view over a socket DSN: the connection is refused';
  like $error // '', qr/'mysql_socket'/, '... naming the form';
  unlike $error // '', qr/private\.sock|k98-/, '... quoting neither the DSN nor a credential';
  is scalar @CONNECTS, 0, '... and DBI->connect is never called';
}

done_testing;
