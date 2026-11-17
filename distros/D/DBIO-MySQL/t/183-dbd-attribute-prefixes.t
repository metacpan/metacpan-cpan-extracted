use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# The storage class names the attribute prefixes of its own DBDs.
#
# WHY IT MATTERS. Core asks DBI->driver_prefix for the prefix of a DBD, to tell
# a DBD-private connect attribute from a parameter of the database client
# (mysql_auto_reconnect against a stray lowercase key). DBI's registry knows
# mariadb_ only from 1.640; the cpanfile allows older DBI. On such a DBI a
# dbi:MariaDB: connect with mariadb_auto_reconnect died with "Unknown connect
# attribute(s)", although it is the attribute this dist itself sets. The
# storage class does not depend on the DBI version: it answers for mysql and
# MariaDB itself, one prefix per DBD, and hands every other DBD to core.
#
# FULLY OFFLINE. DBI->driver_prefix is replaced so that it knows no
# DBD::MariaDB (as DBI 1.634 does), and DBI->connect hands out a plain hash.

{
  no warnings 'redefine';
  my $orig = \&DBI::driver_prefix;
  *DBI::driver_prefix = sub {
    return () if defined $_[1] && $_[1] eq 'DBD::MariaDB';
    goto &$orig;
  };
}

is_deeply [ DBI->driver_prefix('DBD::MariaDB') ], [],
  'premise: the DBI registry knows no prefix for DBD::MariaDB';

my @connects;
{
  no warnings 'redefine';
  *DBI::connect = sub {
    push @connects, $_[4];
    tie my %h, 'FakeTie';
    return bless \%h, 'FakeDBH';
  };
  package FakeTie;
  sub TIEHASH { bless { Driver => { Name => 'MariaDB' }, Active => 1, CachedKids => {} }, shift }
  sub FETCH { $_[0]{ $_[1] } }
  sub STORE { $_[0]{ $_[1] } = $_[2] }
  sub EXISTS { exists $_[0]{ $_[1] } }
  package FakeDBH;
  sub FETCH { $_[0]->{ $_[1] } }
  sub STORE { $_[0]->{ $_[1] } = $_[2] }
  sub ping { 1 } sub do { 1 } sub disconnect { 1 }
}

{
  package T183::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

my $class = 'DBIO::MySQL::Storage::MariaDB';

is_deeply [ $class->_dbd_attribute_prefixes('MariaDB') ], ['mariadb_'],
  'DBD::MariaDB: mariadb_';
is_deeply [ $class->_dbd_attribute_prefixes('mysql') ], ['mysql_'],
  'DBD::mysql: mysql_';
is_deeply [ DBIO::MySQL::Storage->_dbd_attribute_prefixes('MariaDB') ], ['mariadb_'],
  '... the same on the parent class';
is_deeply [ $class->_dbd_attribute_prefixes('Pg') ], ['pg_'],
  'another DBD goes to the core method (DBI registry)';
is_deeply [ $class->_dbd_attribute_prefixes(undef) ], [],
  'no DBD named: nothing';

# The connect path of core, with the attribute that was refused.
{
  @connects = ();
  eval {
    T183::Schema->connect(
      'dbi:MariaDB:database=t', 'u', 'p', { mariadb_auto_reconnect => 1 },
    )->storage->ensure_connected;
  };
  is $@, '', 'mariadb_auto_reconnect passes without DBI knowing the prefix';
  is $connects[0]{mariadb_auto_reconnect}, 1, '... and reaches DBI->connect';
}

# One prefix per DBD: the other DBD's name stays refused.
{
  @connects = ();
  eval {
    T183::Schema->connect(
      'dbi:MariaDB:database=t', 'u', 'p', { mysql_auto_reconnect => 1 },
    )->storage->ensure_connected;
  };
  like $@, qr/Unknown connect attribute\(s\) 'mysql_auto_reconnect'/,
    'mysql_auto_reconnect on a dbi:MariaDB: DSN is still refused';
  is scalar(@connects), 0, '... before DBI->connect';
}

done_testing;
