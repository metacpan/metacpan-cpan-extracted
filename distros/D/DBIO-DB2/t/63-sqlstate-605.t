use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::DB2::Storage;

# OFFLINE (karr k47, ADR 0010). CREATE INDEX over columns an index already
# covers is answered with SQL0605W, err 605, SQLSTATE 42S11 and an undef return
# value; nothing is created. 42S11 is no class 01, so ADR 0007's rule does not
# take it, and core's _execute_ddl died on it. The storage's HandleError wrapper
# now handles it -- no exception -- and warns, naming index and table from the
# statement. Any other 42xxx, or err 605 under another state, still throws.
# A real DBI handle (DBD::NullP) with set_err standing in for the DBD, as in
# t/55-sqlstate-warning.t.

{
  package T::K47W::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
}

my $dbi_connect = \&DBI::connect;
my $storage = do {
  my $s = T::K47W::Schema->connect('dbi:DB2:SAMPLE', 'db2inst1', 'x')->storage;
  no warnings qw(redefine once);
  local *DBI::connect = sub {
    my ($class, undef, @rest) = @_;
    return $dbi_connect->($class, 'dbi:NullP:', @rest);
  };
  $s->ensure_connected;
  $s;
};
my $dbh = $storage->dbh;

my $W605 = '[IBM][CLI Driver][DB2/LINUXX8664] SQL0605W  The index was not created '
         . 'because an index "SYSIBM.SQL1" with a matching definition already exists.';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

$dbh->{Statement} = 'CREATE UNIQUE INDEX "u_pk" ON "my ""t""" ("id")';
my $rv = 'unset';
lives_ok { $rv = $dbh->set_err(605, $W605, '42S11', 'do', undef) }
  'err 605 / 42S11 is not an exception';
is scalar @warnings, 1, '... it is one warning';
like $warnings[0], qr/index "u_pk" on table "my ""t"""/, '... naming index and table';
like $warnings[0], qr/SQL0605W/, '... and carrying the server message';
like $warnings[0], qr/ at \S+ line \d+/, '... as a carp, with a location';

@warnings = ();
$dbh->{Statement} = 'CREATE INDEX i2 ON t2 (c)';
lives_ok { $dbh->set_err(605, $W605, '42S11', 'do', undef) } 'unquoted names';
like $warnings[0], qr/index i2 on table t2/, '... are named as written';

@warnings = ();
throws_ok { $dbh->set_err(204, 'SQL0204N "X" is an undefined name.', '42704', 'do', undef) }
  'DBIO::Exception', 'another 42xxx still throws';
throws_ok { $dbh->set_err(605, $W605, '42000', 'do', undef) }
  'DBIO::Exception', 'err 605 under another state still throws';
is scalar @warnings, 0, '... and warns nothing';

done_testing;
