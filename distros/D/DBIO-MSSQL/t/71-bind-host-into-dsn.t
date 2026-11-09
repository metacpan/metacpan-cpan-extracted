use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;

# OFFLINE (karr k64; core karr k276, ADR 0013 addendum 2026-10-09). A
# DBIO::AccessBroker::HostBound view -- one credential, a host of its own per
# replicant -- binds its host (and port) into a DBI-form answer through the
# seam DBIO::Storage::DBI->_bind_host_into_dsn($driver, $dsn, $host, $port):
# the DSN, or (undef, $form) when the driver's DBD names its server in a way
# the seam cannot translate. Core's default knows host=/port= tokens only, and
# so declines every SQL Server DSN written for DBD::ODBC (Server=..., DSN=...).
# This file is the counterpart of core's t/access_broker/28-hostbound-dsn-
# dialects.t for this driver. It claims:
#
#   1. DBD::ODBC, Server=host[,port] (Microsoft form): host and port are
#      bound where they stand; a view without a port keeps the answer's;
#   2. DBD::ODBC, Server=host;Port=n (FreeTDS form): the same;
#   3. everything else of the ODBC DSN stays byte for byte (other keys, their
#      case, a braced Driver={...;...}, the dbi:ODBC(attr): prefix);
#   4. what cannot be bound is declined, naming the form (a key, a dialect),
#      never a value of the DSN: a data source (DSN=, FILEDSN=, a bare name),
#      Servername=, Address=, a Server with an instance or a protocol, both
#      port forms at once, no Server at all, and a view port where the DSN
#      shows no port form to put it in;
#   5. DBD::Sybase: host=/port= is core's default form and is translated;
#      server=NAME (a named server) is declined; so is anything else core's
#      default declines;
#   6. the seam stands on the base class and is the one every access path
#      reaches: DBIO::MSSQL::Storage (the declared class, asked before the
#      storage adapts), ::ODBC and ::Sybase -- and a HostBound view over a
#      storage of each gets the same answer, and a refusal that names the form
#      and neither the DSN nor a credential.
#
# No database; DBI->connect is replaced by a recorder.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::K64::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

{
  package T::K64::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::K64::Handle->new };
}

my $BASE = 'DBIO::MSSQL::Storage';

# what the seam answers: (DSN) or (undef, form)
sub seam {
  my ($driver, $dsn, $host, $port) = @_;
  return $BASE->_bind_host_into_dsn($driver, $dsn, $host, $port);
}

my ($H, $P) = ('replica.example', 6000);

# --------------------------------------------------------------- 1. Server=host[,port]
my $MS = 'dbi:ODBC:Driver={ODBC Driver 18 for SQL Server};';

is_deeply [ seam('ODBC', $MS . 'Server=master.example,1433;Database=d', $H, $P) ],
  [ $MS . 'Server=replica.example,6000;Database=d' ],
  'Server=host,port: host and port are bound where they stand';

is_deeply [ seam('ODBC', $MS . 'Server=master.example,1433;Database=d', $H, undef) ],
  [ $MS . 'Server=replica.example,1433;Database=d' ],
  '... a view without a port keeps the port of the answer';

is_deeply [ seam('ODBC', $MS . 'Server=master.example;Database=d', $H, undef) ],
  [ $MS . 'Server=replica.example;Database=d' ],
  'Server=host and no port anywhere: the host is bound, nothing is added';

# --------------------------------------------------------------- 2. Server=host;Port=n
my $FT = 'dbi:ODBC:Driver=FreeTDS;';

is_deeply [ seam('ODBC', $FT . 'Server=master.example;Port=1433;Database=d;TDS_Version=7.4', $H, $P) ],
  [ $FT . 'Server=replica.example;Port=6000;Database=d;TDS_Version=7.4' ],
  'Server=host;Port=n: host and port are bound where they stand';

is_deeply [ seam('ODBC', $FT . 'Server=master.example;Port=1433;Database=d', $H, undef) ],
  [ $FT . 'Server=replica.example;Port=1433;Database=d' ],
  '... a view without a port keeps the Port of the answer';

# --------------------------------------------------------------- 3. the rest stays
is_deeply [ seam('ODBC', 'dbi:ODBC:driver=FreeTDS;SERVER=master.example;port=1433;UID=u', $H, $P) ],
  [ 'dbi:ODBC:driver=FreeTDS;SERVER=replica.example;port=6000;UID=u' ],
  'keys are found whatever their case, and keep the spelling they have';

is_deeply [ seam('ODBC', 'dbi:ODBC(RaiseError=1):Driver=FreeTDS;Server=master.example', $H, undef) ],
  [ 'dbi:ODBC(RaiseError=1):Driver=FreeTDS;Server=replica.example' ],
  'attributes in the dbi:ODBC(...): prefix stay';

is_deeply [ seam('ODBC', 'DBI:ODBC:Driver={a;b};Server=master.example,1;', $H, $P) ],
  [ 'DBI:ODBC:Driver={a;b};Server=replica.example,6000;' ],
  'a ; inside braces does not split a part; the empty part behind the last ; stays';

# --------------------------------------------------------------- 4. declined, naming the form
my @DECLINED = (
  [ 'DSN=<name> (a data source: no host in it)',
    'dbi:ODBC:DSN=MASTERDSN;UID=u', qr/'DSN'/ ],
  [ 'dsn= in lower case',
    'dbi:ODBC:dsn=MASTERDSN', qr/'dsn'/ ],
  [ 'FILEDSN=',
    'dbi:ODBC:FILEDSN=/etc/master.dsn', qr/'FILEDSN'/ ],
  [ 'a bare data source name',
    'dbi:ODBC:MASTERDSN', qr/without key=value form/ ],
  [ 'Servername= (a freetds.conf entry)',
    'dbi:ODBC:Driver=FreeTDS;Servername=MASTER', qr/'Servername'/ ],
  [ 'Address=',
    'dbi:ODBC:Driver=FreeTDS;Address=master.example;Server=x', qr/'Address'/ ],
  [ 'a Server with an instance name',
    $MS . 'Server=master.example\\SQLEXPRESS', qr/'Server'.*instance/ ],
  [ 'a Server with a protocol prefix',
    $MS . 'Server=tcp:master.example,1433', qr/'Server'.*(?:protocol|colon|:)/ ],
  [ 'a Server with a braced value',
    $MS . 'Server={master.example}', qr/'Server'.*brace/ ],
  [ 'a port after the comma and a Port key',
    $FT . 'Server=master.example,1433;Port=1433', qr/both.*Port/ ],
  [ 'Server given twice',
    $FT . 'Server=a.example;Server=b.example', qr/'Server'.*more than once/ ],
  [ 'no Server at all',
    'dbi:ODBC:Driver=FreeTDS;Database=d', qr/without a Server key/ ],
  [ 'an unbalanced brace',
    'dbi:ODBC:Driver={FreeTDS;Server=master.example', qr/unbalanced/ ],
  [ 'a DSN without dbi:ODBC: prefix',
    'Server=master.example', qr/without a dbi:ODBC: prefix/ ],
);

for my $case (@DECLINED) {
  my ($label, $dsn, $form) = @$case;
  my @r = seam('ODBC', $dsn, $H, $P);

  ok !defined $r[0], "$label: no DSN is answered";
  like $r[1] // '', $form, '... the form is named';
  unlike $r[1] // '', qr/master|MASTER|replica|\.dsn/i,
    '... and neither a value of the DSN nor the view\'s host';
}

{
  my @r = seam('ODBC', $FT . 'Server=master.example;Database=d', $H, $P);
  ok !defined $r[0], 'a view port and a DSN with no port form to put it in: declined, '
    . 'not guessed (Server=host,port or Port=n?)';
  like $r[1] // '', qr/'Server'.*port/, '... naming the form';
  unlike $r[1] // '', qr/master|replica/, '... without a value';
}

# --------------------------------------------------------------- 5. DBD::Sybase and the rest
is_deeply [ seam('Sybase', 'dbi:Sybase:database=d;host=master.example;port=1433', $H, $P) ],
  [ 'dbi:Sybase:database=d;host=replica.example;port=6000' ],
  'DBD::Sybase host=/port=: bound, as core\'s default does';

is_deeply [ seam('Sybase', 'dbi:Sybase:database=d', $H, $P) ],
  [ 'dbi:Sybase:port=6000;host=replica.example;database=d' ],
  'DBD::Sybase without them: put in front';

{
  my @r = seam('Sybase', 'dbi:Sybase:server=MASTER;database=d', $H, $P);
  ok !defined $r[0], 'DBD::Sybase server=NAME (a named server): declined';
  like $r[1] // '', qr/'server'/, '... naming the key';
  unlike $r[1] // '', qr/MASTER/, '... and not its value';
}

{
  my @r = seam('ADO', 'dbi:ADO:Data Source=master.example', $H, $P);
  ok !defined $r[0], 'a DBD this driver has no form for (ADO) gets core\'s answer: declined';
  unlike $r[1] // '', qr/master/, '... without a value';
}

# --------------------------------------------------------------- 6. every access path, through a view
sub view_over { T::K64::Broker->new($_[0])->for_host($_[1] || { host => $H, port => $P }) }

my @STORAGES = ($BASE, 'DBIO::MSSQL::Storage::ODBC');
push @STORAGES, 'DBIO::MSSQL::Storage::Sybase'
  if eval { require DBIO::MSSQL::Storage::Sybase; 1 };

for my $class (@STORAGES) {
  my $storage = $class->new(undef);

  my $view = view_over([ $FT . 'Server=master.example;Port=1433;Database=d', 'k64-user', 'k64-pw', {} ]);
  my $info = $view->connect_info_for_storage($storage);
  is $info->[0], $FT . 'Server=replica.example;Port=6000;Database=d',
    "$class: a HostBound view binds the host into an ODBC DSN";
  is_deeply [ @$info[1, 2] ], [ 'k64-user', 'k64-pw' ],
    '... the credentials are the answer\'s';

  my $refused = view_over([ 'dbi:ODBC:DSN=MASTERDSN', 'k64-user', 'k64-pw', {} ]);
  throws_ok { $refused->connect_info_for_storage($storage) }
    qr/cannot bind its host into the answer: .*'DSN'/s,
    "$class: a view over DSN=<name> is refused, naming the form";
  unlike "$@", qr/MASTERDSN|k64-/, '... quoting neither the DSN nor a credential';
}

{
  # the whole way: connect a declared storage through a view
  my $storage = $BASE->new(undef);
  local @CONNECTS;
  my $view = view_over([ $MS . 'Server=master.example,1433;Database=d', 'u', 'p', {} ]);

  ok eval { $storage->connect_info([ $view ]); $storage->_connect; 1 },
    'the declared storage connects through a view over an ODBC answer' or diag $@;
  is $CONNECTS[0][0], $MS . 'Server=replica.example,6000;Database=d',
    '... DBI->connect sees the DSN with the view\'s host, not the master\'s';
}

{
  local @CONNECTS;
  my $storage = $BASE->new(undef);
  my $view = view_over([ 'dbi:ODBC:Driver=FreeTDS;Servername=MASTER', 'k64-user', 'k64-pw', {} ]);

  ok !eval { $storage->connect_info([ $view ]); $storage->_connect; 1 },
    'a view over a Servername= answer: the connection is refused';
  like "$@", qr/'Servername'/, '... naming the form';
  unlike "$@", qr/MASTER\b|k64-/, '... quoting neither the DSN nor a credential';
  is scalar @CONNECTS, 0, '... and DBI->connect never sees the master\'s server';
}

done_testing;
