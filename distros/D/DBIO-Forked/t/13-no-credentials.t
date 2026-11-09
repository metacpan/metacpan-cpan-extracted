use strict;
use warnings;

use Test::More;
use Data::Dumper ();
use Scalar::Util ();

use DBIO::Forked::Storage;
use DBIO::AccessBroker::Static;

# The backend holds no access data. connect_info takes the connect info the
# core resolver hands over and keeps its shape only: broker or not, and the
# number of elements. The child's connection is the owner storage's own.

my $DSN  = 'dbi:Pg:dbname=zq_secret_db;host=zq-secret-host';
my $USER = 'zq_secret_user';
my $PASS = 'zq_secret_pass';
my $ATTR = 'zq_secret_attr';

sub dump_of {
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Maxdepth = 0;
  return Data::Dumper::Dumper($_[0]);
}

sub leaks {
  my ($storage) = @_;
  my $dump = dump_of($storage);
  return grep { index($dump, $_) >= 0 } 'zq_secret';
}

# 1. DBI form
{
  my $storage = DBIO::Forked::Storage->new(undef);
  my $conninfo = [ $DSN, $USER, $PASS, { LongReadLen => 1, $ATTR => 1 }, { on_connect_do => [ 'SELECT 1' ] } ];
  my $shape = $storage->connect_info($conninfo);

  is_deeply $shape, { broker => 0, elements => 5 },
    'DBI form: the form is kept, broker no, five elements';
  is_deeply $storage->connect_info, { broker => 0, elements => 5 },
    '... and the getter answers the same';
  is_deeply [ leaks($storage) ], [], 'a dump of the backend holds no DSN, user, password or attribute';
  is_deeply [ leaks($shape) ], [], '... nor does the returned form';
}

# 2. broker alone, and broker plus options
{
  my $broker = DBIO::AccessBroker::Static->new(
    host => 'zq-secret-host', dbname => 'zq_secret_db',
    username => $USER, password => $PASS,
  );

  my $storage = DBIO::Forked::Storage->new(undef);
  is_deeply $storage->connect_info([ $broker ]), { broker => 1, elements => 1 },
    'broker alone: broker yes, one element';
  is_deeply [ leaks($storage) ], [], '... a dump holds nothing of the broker';
  ok !(grep { Scalar::Util::blessed($_) } values %$storage),
    '... and no broker object is held';

  is_deeply $storage->connect_info([ $broker, { AutoCommit => 1, $ATTR => 1 } ]),
    { broker => 1, elements => 2 }, 'broker with options: broker yes, two elements';
  is_deeply [ leaks($storage) ], [], '... a dump holds neither broker nor options';
}

# 3. no setter call: nothing held
{
  my $storage = DBIO::Forked::Storage->new(undef);
  is $storage->connect_info, undef, 'before any connect_info there is no form';
}

done_testing;
