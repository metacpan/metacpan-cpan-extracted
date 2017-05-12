# Script encoding is windows-1251. No 'use encoding'!
use strict;

use Test::More tests=>16;
use Test::Exception;
use DBIx::PgLink::Adapter;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $db = DBIx::PgLink::Adapter->new();

lives_ok { $db->install_roles('Encoding'); } 'install Encoding role';

lives_ok { $db->remote_encoding('utf8') } 'set remote_encoding';
is( 
  $db->remote_encoding,
  'utf8',
  'get remote_encoding'
);

lives_ok { $db->local_encoding('cp1251') } 'set local_encoding';
is( 
  $db->local_encoding,
  'cp1251',
  'get local_encoding'
);

ok( 
  $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {RaiseError=>1}),
  'adapter connected'
);

# sanity check (double encoding)
ok( $db->do('SET client_encoding=WIN1251'), 'set Pg client_encoding WIN1251');
{
  my $sth = $db->prepare("SELECT t FROM source.enc WHERE id = ?");
  $sth->execute(3);
  my $value = $sth->fetchrow_array;
  isnt($value, 'смотри', 'result recode, wrong client_encoding');
}


# now client_encoding corresponds $db->remote_encoding
ok( $db->do('SET client_encoding=utf8'), 'set Pg client_encoding utf8');

# return value encoding, prepare+execute+fetch
{
  my $sth = $db->prepare("SELECT t FROM source.enc WHERE id = ?");
  $sth->execute(3);
  my $value = $sth->fetchrow_array;
  is($value, 'смотри', 'result recode 1');
}


# return value encoding, selectall_arrayref
{
  my $data = $db->selectall_arrayref("SELECT t FROM source.enc WHERE id = ?", {}, 3);
  is_deeply($data, [ [ 'смотри' ] ], 'result recode 2');
}

# return value encoding, selectrow_array
{
  my $data = $db->selectrow_array("SELECT t FROM source.enc WHERE id = ?", {}, 3);
  is_deeply($data, 'смотри', 'result recode 3');
}

# parameter encoding, prepare+execute+fetch
{
  my $sth = $db->prepare("SELECT id FROM source.enc WHERE t = ?");
  $sth->execute('смотри');
  my $value = $sth->fetchrow_array;
  is($value, 3, 'param recode 1');
}

# parameter encoding, selectall_arrayref
{
  my $data = $db->selectall_arrayref("SELECT id FROM source.enc WHERE t = ?", {}, 'смотри');
  is_deeply($data, [ [ 3 ] ], 'param recode 2');
}

# query encoding, selectall_arrayref
{
  my $data = $db->selectall_arrayref("SELECT id FROM source.enc WHERE t = 'смотри'");
  is_deeply($data, [ [ 3 ] ], 'query recode 1');
}
