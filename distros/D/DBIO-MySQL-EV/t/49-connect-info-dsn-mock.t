use strict;
use warnings;
use Test::More;

use DBIO::MySQL::EV::ConnectInfo qw( dbi_to_conninfo );
use DBIO::MySQL::EV::Storage;

alarm 30;

# OFFLINE, karr k64, k79, k80. What a DBI-form connect info (a DSN, its
# credentials and attributes) becomes for EV::MariaDB, which parses no DSN and
# croaks on a parameter it does not know:
#
#   k64  known DBD DSN keys are translated, unknown ones refused; the
#        positional form (dbi:mysql:app:host:port) is read as both DBDs read
#        it; the explicit user/password beat the DSN's own
#   k79  the single-hash form { dsn, user, password, pool_size, <attrs> }
#        is read, and neither dsn nor async reaches EV::MariaDB->new
#   k80  a connection parameter among the attributes and a whole DSN as the
#        database name of a hash are refused, not dropped / read as a name
#
# Refusals name keys, never a value (karr k76): every connect info below
# carries a password that must not appear in any message.

my $SECRET = 'topsecret';

sub conninfo { my $r = dbi_to_conninfo([@_]); return $r->[0] }
sub refusal {
  my $got = eval { dbi_to_conninfo([@_]); 1 } ? undef : "$@";
  return $got;
}

# EV::MariaDB 0.08 %ALLOWED_ARGS minus callbacks and loop
my %EV_ARG = map { $_ => 1 } qw(
  connect_timeout read_timeout write_timeout compress multi_statements charset
  init_command ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher
  ssl_verify_server_cert utf8 found_rows host user password database db port
  unix_socket
);

# --- k64: the DBD keys, both prefixes, each to the parameter EV::MariaDB has ---

my %TRANSLATE = (
  socket                 => [ unix_socket            => '/run/mysqld.sock' ],
  connect_timeout        => [ connect_timeout        => 5 ],
  read_timeout           => [ read_timeout           => 6 ],
  write_timeout          => [ write_timeout          => 7 ],
  compression            => [ compress               => 1 ],
  init_command           => [ init_command           => 'SET x=1' ],
  multi_statements       => [ multi_statements       => 1 ],
  client_found_rows      => [ found_rows             => 1 ],
  ssl_ca_file            => [ ssl_ca                 => '/ca.pem' ],
  ssl_ca_path            => [ ssl_capath             => '/cas' ],
  ssl_client_key         => [ ssl_key                => '/k.pem' ],
  ssl_client_cert        => [ ssl_cert               => '/c.pem' ],
  ssl_cipher             => [ ssl_cipher             => 'DEFAULT' ],
  ssl_verify_server_cert => [ ssl_verify_server_cert => 1 ],
);

for my $prefix (qw( mysql mariadb )) {
  for my $key (sort keys %TRANSLATE) {
    my ($ev, $val) = @{ $TRANSLATE{$key} };
    my $h = conninfo("dbi:mysql:database=app;host=h;${prefix}_$key=$val", 'u', 'p');
    is $h->{$ev}, $val, "${prefix}_$key becomes $ev";
    ok !(grep { /^(?:mysql|mariadb)_/ } keys %$h), "... and no DBD key is left in the conninfo";
    ok !(grep { !$EV_ARG{$_} && $_ ne 'pool_size' } keys %$h), "... only EV::MariaDB parameters remain";
  }
}

is conninfo('dbi:mysql:database=app;host=h;mysql_ssl=1;mysql_ssl_ca_file=/ca.pem')->{ssl_ca},
  '/ca.pem', 'mysql_ssl beside a ca file is no parameter of its own';
ok !exists conninfo('dbi:mysql:database=app;host=h;mysql_ssl=0')->{mysql_ssl},
  'mysql_ssl=0 asks for nothing';

# EV::MariaDB's own names stay readable in a DSN (the broker refusal points there)
{
  my $h = conninfo('dbi:MariaDB:database=app;host=h;charset=utf8mb4;connect_timeout=3;ssl_cipher=DEFAULT');
  is_deeply [ @{$h}{qw( charset connect_timeout ssl_cipher )} ], [ 'utf8mb4', 3, 'DEFAULT' ],
    'EV::MariaDB parameter names in a DSN are passed on';
}
{
  my $h = conninfo('dbi:mysql:dbname=app;hostname=h;port=3307');
  is_deeply $h, { database => 'app', host => 'h', port => 3307 },
    'dbname and hostname are read as database and host';
}

# unknown keys: refused, naming the key and no value
for my $case (
  [ 'mariadb_auto_reconnect'  => 'mariadb_auto_reconnect=1' ],
  [ 'mysql_ssl_optional'      => 'mysql_ssl_optional=1' ],
  [ 'mysql_read_default_file' => "mysql_read_default_file=/etc/my.cnf" ],
  [ 'bogus'                   => 'bogus=1' ],
) {
  my ($name, $part) = @$case;
  my $err = refusal("dbi:mysql:database=app;host=h;password=$SECRET;$part", 'u', $SECRET);
  like $err, qr/refuses the connect info.*\Q$name\E/s, "$name in a DSN is refused, named";
  unlike $err, qr/\Q$SECRET\E|=1/, '... quoting no value';
}
{
  my $err = refusal('dbi:mysql:database=app;host=h;zz=1;aa=2;zz=3', 'u', 'p');
  like $err, qr/\(aa, zz\)/, 'several unknown keys are listed once, sorted';
}

# mysql_ssl alone would open the connection without SSL
{
  my $err = refusal("dbi:mysql:database=app;host=h;mysql_ssl=1", 'u', $SECRET);
  like $err, qr/mysql_ssl.*without any of/s, 'mysql_ssl without a ca/cert/key/cipher is refused';
  unlike $err, qr/\Q$SECRET\E/, '... without a password';
}

# the same parameter under two names
{
  my $err = refusal('dbi:mysql:database=app;host=h;mysql_connect_timeout=3;connect_timeout=4', 'u', 'p');
  like $err, qr/connect_timeout.*more than once/s, 'one parameter under two names is refused';
}

# --- k64: the positional form ---------------------------------------------------

is_deeply conninfo('dbi:mysql:appdb', 'u', 'p'),
  { database => 'appdb', user => 'u', password => 'p' },
  'dbi:mysql:appdb is the database, not a key appdb';
is_deeply conninfo('dbi:MariaDB:appdb:db1', 'u', 'p'),
  { database => 'appdb', host => 'db1', user => 'u', password => 'p' }, 'database:host';
is_deeply conninfo('dbi:mysql:appdb:db1:3307', 'u', 'p'),
  { database => 'appdb', host => 'db1', port => 3307, user => 'u', password => 'p' }, 'database:host:port';
is_deeply conninfo('dbi:mysql:appdb::3307', 'u', 'p'),
  { database => 'appdb', port => 3307, user => 'u', password => 'p' }, 'an empty host part names no host';
is_deeply conninfo('dbi:mysql:appdb:[::1]:3307', 'u', 'p'),
  { database => 'appdb', host => '::1', port => 3307, user => 'u', password => 'p' },
  'a bracketed IPv6 host is read as the DBDs read it';
like refusal('dbi:mysql:a:b:3306:d', 'u', 'p'), qr/more than database, host and port/,
  'more than three positional parts is refused';
like refusal('dbi:mysql:a;b', 'u', 'p'), qr/positional part beside a semicolon/,
  'a positional part beside a semicolon is refused';
like refusal('dbi:mysql:appdb;host=h', 'u', 'p'), qr/positional part beside key=value/,
  'a positional part beside key=value parts is refused';

# --- k64: the explicit credentials win ------------------------------------------

{
  my $h = conninfo("dbi:mysql:database=app;host=h;user=old;password=oldpass", 'new', 'newpass');
  is_deeply [ @{$h}{qw( user password )} ], [ 'new', 'newpass' ],
    'user and password arguments beat those of the DSN';
  $h = conninfo("dbi:mysql:database=app;host=h;user=fromdsn;password=pw", undef, undef);
  is_deeply [ @{$h}{qw( user password )} ], [ 'fromdsn', 'pw' ],
    'the DSN\'s own stand when no argument is given';
  $h = conninfo("dbi:mysql:database=app;host=h;password=pw", 'u', '');
  is $h->{password}, '', 'an empty password argument is an argument';
}

# --- k80 (1): connection parameters among the attributes -------------------------

for my $attrs (
  { charset => 'utf8mb4' },
  { connect_timeout => 5, pool_size => 2 },
) {
  for my $slot (3, 4) {
    my @info = ('dbi:mysql:database=app;host=h', 'u', $SECRET, undef, undef);
    $info[$slot] = { %$attrs };
    my $err = refusal(@info);
    my ($name) = grep { $_ ne 'pool_size' } keys %$attrs;
    like $err, qr/connect attributes.*\Q$name\E/s, "$name in attribute slot $slot is refused";
    unlike $err, qr/\Q$SECRET\E|utf8mb4|=\s*5/, '... quoting no value';
  }
}
{
  my $h = conninfo('dbi:mysql:database=app;host=h', 'u', 'p', {
    pool_size => 3, AutoCommit => 1, RaiseError => 1, mysql_ssl => 0,
    private_x => 1, dbi_foo => 1,
    async => 'ev', on_connect_do => ['SET x=1'], quote_names => 1, cursor_class => 'X',
    ignore_version => 1, charset => undef, empty => '',
  });
  is $h->{pool_size}, 3, 'pool_size is read';
  ok !(grep { !$EV_ARG{$_} && $_ ne 'pool_size' } keys %$h),
    'DBI attributes, the DBD\'s and the DBIO storage options are dropped, not refused';
}

# --- k79: the single-hash form ---------------------------------------------------

sub storage_for {
  my ($info) = @_;
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info($info);
  return $storage;
}

{
  my $storage = storage_for([ {
    dsn => 'dbi:mysql:database=app;host=h;mysql_connect_timeout=4', user => 'u', password => 'p',
    pool_size => 3, async => 'ev', on_connect_do => ['SET x=1'], AutoCommit => 1,
  } ]);
  is_deeply $storage->_conninfo_hash,
    { database => 'app', host => 'h', connect_timeout => 4, user => 'u', password => 'p' },
    'the single-hash form is read: dsn translated, user and password taken';
  ok !(grep { /^(?:dsn|async)$/ } keys %{ $storage->_conninfo_hash }), 'neither dsn nor async is left';
  is $storage->{_pool_size}, 3, '... pool_size sizes the pool';
}
{
  my $storage = storage_for([ { dsn => 'dbi:mysql:appdb:db1', user => 'u', password => 'p',
    attrs => { pool_size => 2 } } ]);
  is_deeply $storage->_conninfo_hash,
    { database => 'appdb', host => 'db1', user => 'u', password => 'p' },
    'the positional DSN of a hash is read';
  is $storage->{_pool_size}, 2, '... a nested attrs hash is read';
}
{
  my $err = eval { storage_for([ { dsn => 'dbi:mysql:database=app;host=h', user => 'u',
    password => $SECRET, charset => 'utf8mb4' } ]); 1 } ? '' : "$@";
  like $err, qr/charset/, 'a connection parameter beside dsn in the hash is refused';
  unlike $err, qr/\Q$SECRET\E|utf8mb4/, '... without a value';
}
{
  my $err = eval { storage_for([ { dsn => 'dbi:Pg:dbname=x', user => 'u', password => $SECRET } ]); 1 } ? '' : "$@";
  like $err, qr/expected dbi:mysql/, 'a DSN for another driver is refused';
  unlike $err, qr/\Q$SECRET\E/, '... the password masked';
}
{
  # the transport's own pair keeps being read as it was
  my $storage = storage_for([ { host => 'h', user => 'u', dbname => 'app' }, {} ]);
  is_deeply $storage->_conninfo_hash, { host => 'h', user => 'u', database => 'app' },
    'the transport\'s [ \\%conninfo, \\%opts ] pair is unchanged';
}

# --- k80 (2): a DSN as the database name of a hash -------------------------------

for my $key (qw( dbname database db )) {
  my $err = eval { storage_for([ { host => 'h', user => 'u', password => $SECRET,
    $key => "dbi:mysql:database=app;host=other;password=$SECRET" } ]); 1 } ? '' : "$@";
  like $err, qr/database name is a whole DBI DSN/, "a DSN in $key of a hash is refused";
  unlike $err, qr/\Q$SECRET\E|other/, '... quoting nothing of it';
}

# --- the broker path states a refusal as it is -----------------------------------

{
  require DBIO::AccessBroker::Static;
  my $broker = DBIO::AccessBroker::Static->new(host => 'h', dbname => 'app', username => 'u', password => $SECRET);
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  no warnings qw( redefine once );
  local *DBIO::AccessBroker::Static::connect_info_for = sub {
    [ "dbi:mysql:database=app;host=h;mysql_auto_reconnect=1", 'u', $SECRET ];
  };
  my $err = eval { $storage->connect_info([ $broker ]); 1 } ? '' : "$@";
  like $err, qr/cannot connect from what the AccessBroker returned.*mysql_auto_reconnect/s,
    'a DSN key refused in a broker\'s DBI-form answer is named';
  unlike $err, qr/\Q$SECRET\E/, '... without the password';
}

done_testing;
