use strict;
use warnings;
use Test::More;

use DBIO::MySQL::EV::ConnectInfo qw( dbi_to_conninfo );
use DBIO::MySQL::EV::Pool;

alarm 30;

# OFFLINE, karr k80 (maintainer's decision 2026-10-22). What the DBD-only
# settings become for EV::MariaDB:
#
#   a) mysql_enable_utf8mb4 / mysql_enable_utf8 (DBD::mysql only: DBD::MariaDB has no
#      such attribute, measured 1.24 "Unknown attribute"), in the
#      DSN or among the attributes, are charset => utf8mb4 / utf8 plus
#      utf8 => 1 (the strings come back as characters, as with the DBDs) --
#      not refused, not dropped
#   b) any other mysql_* / mariadb_* attribute (mariadb_enable_utf8* included) EV::MariaDB has no parameter
#      for is refused, naming the attribute; the ones it has a parameter for
#      are translated like the same key in a DSN
#   c) CLIENT_FOUND_ROWS is on for every handle of the transport unless the
#      connect info says found_rows => 0
#
# Messages name keys, never a value (karr k76).

my $SECRET = 'topsecret';
my $DSN    = 'dbi:mysql:database=app;host=h';

sub conninfo { return dbi_to_conninfo([@_])->[0] }
sub refusal  { return eval { dbi_to_conninfo([@_]); 1 } ? undef : "$@" }

# --- a) utf8 ---------------------------------------------------------------------

for my $prefix (qw( mysql )) {
  my $h = conninfo("$DSN;${prefix}_enable_utf8mb4=1", 'u', 'p');
  is_deeply [ @{$h}{qw( charset utf8 )} ], [ 'utf8mb4', 1 ], "${prefix}_enable_utf8mb4=1 in the DSN";
  $h = conninfo("$DSN;${prefix}_enable_utf8=1", 'u', 'p');
  is_deeply [ @{$h}{qw( charset utf8 )} ], [ 'utf8', 1 ], "${prefix}_enable_utf8=1 in the DSN";
  $h = conninfo($DSN, 'u', 'p', { "${prefix}_enable_utf8mb4" => 1 });
  is_deeply [ @{$h}{qw( charset utf8 )} ], [ 'utf8mb4', 1 ], "${prefix}_enable_utf8mb4 => 1 among the attributes";
  $h = conninfo($DSN, 'u', 'p', undef, { "${prefix}_enable_utf8" => 1 });
  is_deeply [ @{$h}{qw( charset utf8 )} ], [ 'utf8', 1 ], "${prefix}_enable_utf8 => 1 in the extra attributes";
}
{
  my $h = conninfo("$DSN;mysql_enable_utf8=1;mysql_enable_utf8mb4=1", 'u', 'p');
  is $h->{charset}, 'utf8mb4', 'utf8mb4 wins over utf8, as in DBD::mysql';
  $h = conninfo("$DSN;mysql_enable_utf8mb4=0;mysql_enable_utf8=1", 'u', 'p');
  is $h->{charset}, 'utf8', '... and a false utf8mb4 asks for nothing';
  $h = conninfo("$DSN;mysql_enable_utf8mb4=0", 'u', 'p');
  ok !exists $h->{charset} && !exists $h->{utf8}, 'a false switch changes nothing';
  $h = conninfo("$DSN;mysql_enable_utf8mb4=1;charset=utf8mb4", 'u', 'p');
  is $h->{charset}, 'utf8mb4', 'a charset that says the same stands';
  like refusal("$DSN;mysql_enable_utf8mb4=1;charset=latin1", 'u', $SECRET),
    qr/charset.*more than once/s, 'a charset that says something else is refused';
  $h = conninfo("$DSN;mysql_enable_utf8mb4=1;utf8=0", 'u', 'p');
  is $h->{utf8}, 0, 'an explicit utf8 stays';
}

# --- b) attributes ---------------------------------------------------------------

for my $case (
  [ mysql_auto_reconnect    => 1 ],
  [ mariadb_auto_reconnect  => 1 ],
  [ mysql_server_prepare    => 1 ],
  [ mysql_ssl_optional      => 1 ],
  [ mysql_read_default_file => '/etc/my.cnf' ],
  [ mysql_bogus             => 'x' ],
  [ mariadb_enable_utf8mb4  => 1 ],
  [ mariadb_enable_utf8     => 1 ],
) {
  my ($name, $val) = @$case;
  for my $slot (3, 4) {
    my @info = ($DSN, 'u', $SECRET, undef, undef);
    $info[$slot] = { pool_size => 2, $name => $val };
    my $err = refusal(@info);
    like $err, qr/refuses the connect info.*\Q$name\E/s, "$name in attribute slot $slot is refused, named";
    unlike $err, qr/\Q$SECRET\E|\/etc\/my|=\s*x\b/, '... quoting no value';
  }
}
{
  my $err = refusal($DSN, 'u', 'p', { mysql_auto_reconnect => 1, mariadb_server_prepare => 1 });
  like $err, qr/\(mariadb_server_prepare, mysql_auto_reconnect\)/, 'all refused attributes are listed once, sorted';
}
ok !defined refusal($DSN, 'u', 'p', { mysql_auto_reconnect => undef }), 'an attribute set to undef names nothing';

# auto_reconnect is the one DBD attribute without a twin whose false value asks
# for nothing (karr k80, maintainer's decision): 0 is how a DBD connect is told
# to keep it off, which is all this transport does anyway. A true one asks for a
# reconnect the transport does not do, and is refused above.
for my $name (qw( mysql_auto_reconnect mariadb_auto_reconnect )) {
  for my $false (0, '') {
    my $h = conninfo($DSN, 'u', 'p', { $name => $false });
    ok !grep({ /reconnect/ } keys %$h), "$name => '$false' among the attributes is let through, no key left";
    $h = conninfo($DSN, 'u', 'p', undef, { $name => $false });
    ok !grep({ /reconnect/ } keys %$h), '... also in the extra attributes';
  }
  my $h = conninfo("$DSN;$name=0", 'u', 'p');
  ok !grep({ /reconnect/ } keys %$h), "$name=0 in the DSN is let through alike";
  like refusal("$DSN;$name=1", 'u', 'p'), qr/\Q$name\E/, "$name=1 in the DSN is still refused, named";
}
like refusal($DSN, 'u', 'p', { mysql_auto_reconnect => 0, mysql_server_prepare => 0 }),
  qr/\(mysql_server_prepare\)/, 'only auto_reconnect is let through at 0: every other unmappable attribute is refused at 0 too';

{
  my $h = conninfo($DSN, 'u', 'p', {
    mysql_connect_timeout => 5, mariadb_ssl_ca_file => '/ca.pem', mysql_ssl => 1,
    mysql_client_found_rows => 0, mysql_compression => 1,
  });
  is_deeply [ @{$h}{qw( connect_timeout ssl_ca found_rows compress )} ], [ 5, '/ca.pem', 0, 1 ],
    'attributes EV::MariaDB has a parameter for are translated like the DSN keys';
  ok !(grep { /^(?:mysql|mariadb)_/ } keys %$h), '... and no DBD key is left';
  like refusal($DSN, 'u', 'p', { mysql_ssl => 1 }), qr/mysql_ssl.*without any of/s,
    'mysql_ssl among the attributes needs a ca/cert/key/cipher, as in the DSN';
  like refusal("$DSN;connect_timeout=3", 'u', 'p', { mysql_connect_timeout => 3 }),
    qr/connect_timeout.*more than once/s, 'one parameter in DSN and attributes under two names is refused';
  like refusal("$DSN;mysql_connect_timeout=3", 'u', 'p', { mysql_connect_timeout => 4 }),
    qr/connect_timeout.*more than once/s, '... and under one name with two values';
  $h = conninfo("$DSN;mysql_connect_timeout=3", 'u', 'p', { mysql_connect_timeout => 3 });
  is $h->{connect_timeout}, 3, '... but the same value twice is fine';
  $h = conninfo($DSN, 'u', 'p', { mysql_connect_timeout => 3 }, { mysql_connect_timeout => 4 });
  is $h->{connect_timeout}, 4, 'the later attribute hash wins, as for pool_size';
}

# --- c) CLIENT_FOUND_ROWS --------------------------------------------------------

SKIP: {
  skip 'EV::MariaDB is not installed', 1 unless eval { require EV::MariaDB; 1 };
  my @got;
  no warnings qw( redefine once );
  local *EV::MariaDB::new = sub { shift; push @got, { @_ }; return bless {}, 'FakeMdb' };
  DBIO::MySQL::EV::Pool->_mysql_new_handle(host => 'h', user => 'u');
  DBIO::MySQL::EV::Pool->_mysql_new_handle(host => 'h', user => 'u', found_rows => 0);
  DBIO::MySQL::EV::Pool->_mysql_new_handle(host => 'h', user => 'u', found_rows => 1);
  is_deeply [ map { $_->{found_rows} } @got ], [ 1, 0, 1 ],
    'a handle is made with found_rows on unless the connect info turned it off';
}

done_testing;
