# Script encoding is windows-1251. No 'use encoding'!
use strict;

BEGIN {
  use Test::More;
  use Test::Exception;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_XBASE}) {
    plan skip_all => 'TEST_XBASE not configured';
  } else {
    plan tests => 13;
  }
  use_ok('DBIx::PgLink::Adapter::XBase');
}

use Data::Dumper;

my $db = DBIx::PgLink::Adapter::XBase->new();

lives_ok { $db->install_roles('Encoding'); } 'Encoding role installed';

lives_ok { $db->remote_encoding('cp866') } 'set remote_encoding';
is( 
  $db->remote_encoding,
  'cp866',
  'get remote_encoding'
);

lives_ok { $db->local_encoding('cp1251') } 'set local_encoding';
is( 
  $db->local_encoding,
  'cp1251',
  'get local_encoding'
);

ok( 
  $db->connect('dbi:XBase:examples', undef, undef, {RaiseError=>1}),
  'adapter connected'
);

# return value encoding, prepare+execute+fetch
{
  my $sth = $db->prepare("SELECT TITLE FROM cp866 WHERE N = ?");
  $sth->execute(2);
  my $value = $sth->fetchrow_array;
  is($value, 'Рамка', 'result recode 1');
}

# return value encoding, selectall_arrayref
{
  my $data = $db->selectall_arrayref("SELECT TITLE FROM cp866 WHERE N = ?", {}, 2);
  is_deeply($data, [ [ 'Рамка' ] ], 'result recode 2');
}

# return value encoding, selectrow_array
{
  my $data = $db->selectrow_array("SELECT TITLE FROM cp866 WHERE N = ?", {}, 2);
  is_deeply($data, 'Рамка', 'result recode 3');
}

# parameter encoding, prepare+execute+fetch
{
  my $sth = $db->prepare("SELECT N FROM cp866 WHERE TITLE = ?");
  $sth->execute('Рамка');
  my $value = $sth->fetchrow_array;
  is($value, 2, 'param recode 1');
}

# parameter encoding, selectall_arrayref
{
  my $data = $db->selectall_arrayref("SELECT N FROM cp866 WHERE TITLE = ?", {}, 'Рамка');
  is_deeply($data, [ [ 2 ] ], 'param recode 2');
}

# query encoding, selectall_arrayref
{
  my $data = $db->selectall_arrayref(q/SELECT N FROM cp866 WHERE TITLE='Фон'/);
  is_deeply($data, [ [ 1 ] ], 'query recode 1');
}
