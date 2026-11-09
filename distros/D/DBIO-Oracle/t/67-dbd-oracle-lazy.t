use strict;
use warnings;
use Test::More;

# karr k39, ADR 0008 -- DBD::Oracle is loaded lazily: the storage, its LOB
# support and the column introspection must load on a box without it (the
# offline suite), and the code that really needs it must say so loudly.

BEGIN {
  # Make DBD::Oracle unloadable, whether or not it is installed.
  unshift @INC, sub {
    die "Can't locate DBD/Oracle.pm (blocked by t/67)\n"
      if $_[1] eq 'DBD/Oracle.pm';
    return;
  };
}

use DBIO::Test::Schema;

ok !$INC{'DBD/Oracle.pm'}, 'DBD::Oracle not loaded to begin with';

for my $class (qw(
  DBIO::Oracle::Storage
  DBIO::Oracle::Storage::LOBSupport
  DBIO::Oracle::Introspect::Columns
  DBIO::Oracle::Type
)) {
  ok eval "require $class; 1", "$class loads without DBD::Oracle"
    or diag $@;
}
ok !$INC{'DBD/Oracle.pm'}, 'loading them did not pull DBD::Oracle in';

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::Oracle::Storage');
$schema = $schema->connect('dbi:Oracle:never', 'u', 'p');
my $storage = $schema->storage;

is $storage->bind_attribute_by_data_type('varchar'), undef,
  'a non-LOB bind needs no DBD::Oracle';

# a LOB bind needs the driver: it must fail loudly, not bind without ora_type
my $bind = eval { $storage->bind_attribute_by_data_type('blob') };
like $@, qr/Can't locate DBD\/Oracle\.pm/,
  'a LOB bind without DBD::Oracle dies loudly';
is $bind, undef, '... and returns no attributes';

# the introspection reads the driver version only when it fetches
eval { DBIO::Oracle::Introspect::Columns->fetch(
  bless({}, 'T67::Dbh'), 'S', { T => 1 }) };
like $@, qr/Can't locate DBD\/Oracle\.pm/,
  'Columns->fetch without DBD::Oracle dies loudly';

# the 1.23 guard still holds once the driver is there (faked)
{
  local $INC{'DBD/Oracle.pm'} = 'faked';
  local $DBD::Oracle::VERSION = '1.23';
  local $DBD::Oracle::__DBIO_DBD_VERSION_CHECK_OK__;
  no warnings "once";
  *DBD::Oracle::ORA_BLOB = sub { 113 };
  *DBD::Oracle::ORA_CLOB = sub { 112 };
  eval { $storage->bind_attribute_by_data_type('blob') };
  like $@, qr/DBD::Oracle == 1\.23 is broken/, 'DBD::Oracle 1.23 is refused';

  $DBD::Oracle::VERSION = '1.95';
  is_deeply $storage->bind_attribute_by_data_type('blob'),
    { ora_type => 113 }, 'a good version binds a BLOB with ora_type';
  is_deeply $storage->bind_attribute_by_data_type('clob'),
    { ora_type => 112 }, '... and a CLOB';
  $DBD::Oracle::VERSION = '1.23';
  is_deeply $storage->bind_attribute_by_data_type('blob'),
    { ora_type => 113 }, 'the guard runs once per process';
}

done_testing;
