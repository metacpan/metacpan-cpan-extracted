use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Schema;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Deploy;

# OFFLINE (karr k67; core k297/k304/k311). A message of this driver never
# carries a DSN or a password. The sites that could -- the refusals of the
# connection-parameter seam and of the temp-database connect info -- are
# handed a password and a DSN carrying one, and the text must not hold them.
# The remaining throw/croak/carp sites of lib/ name no connect info at all.

my $SECRET = 'S3cr3t-Pa55w0rd';

my $storage = DBIO::MSSQL::Storage->new(undef);

for my $params (
  { host => 'db.example.com', password => $SECRET, user => 'sa' },
  { port => 1433,             password => $SECRET, user => 'sa' },
) {
  throws_ok { $storage->_connect_params_dsn('MSSQL', { %$params }) }
    qr/Cannot build a DBD::Sybase DSN/,
    'a lone host/port is refused';
  unlike "$@", qr/\Q$SECRET\E/, 'the refusal does not carry the password';
}

{
  package T::Schema;
  our @ISA = ('DBIO::Schema');
  # a schema always declares its driver (core ADR 0067)
  __PACKAGE__->load_components('MSSQL');
}
my $schema = T::Schema->connect(sub { die "never connects" });
$schema->storage->connect_info([ sub { } ]);
my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
throws_ok { $deploy->_temp_connect_info('_dbio_tmp_x') }
  qr/does not support coderef DSN/,
  'a coderef DSN is refused';
unlike "$@", qr/\Q$SECRET\E/, 'the message does not carry the password';

done_testing;
