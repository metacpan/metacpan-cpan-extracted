use strict;
use warnings;

use Test::More tests => 17;

use DBI;
use DBIx::Locker;

unlink 'test.db';

my @conn = ('dbi:SQLite:dbname=test.db', undef, undef, {});

{
  my $dbh = DBI->connect(@conn);
  $dbh->do('CREATE TABLE locks (
    id INTEGER PRIMARY KEY,
    lockstring varchar(128) UNIQUE,
    created varchar(14) NOT NULL,
    expires varchar(14) NOT NULL,
    locked_by varchar(1024)
  )');
}

my $locker = DBIx::Locker->new({
  dbi_args => \@conn,
  table    => 'locks',
});

isa_ok($locker, 'DBIx::Locker');

my $guid;

{
  my $lock = $locker->lock('Zombie Soup');
  isa_ok($lock, 'DBIx::Locker::Lock', 'obtained lock');
  is($lock->lockstring, 'Zombie Soup', 'lockstring set');

  my $id = $lock->lock_id;
  like($id, qr/\A\d+\z/, "we got a numeric lock id");

  my $expiry = $lock->expires;
  like($expiry, qr/\A\d+\z/, "expiry is an integer");
  cmp_ok($expiry, '>', time, "expiry is in the future");

  $guid = $lock->guid;

  eval { $locker->lock('Zombie Soup'); };
  ok(
    $@, 
    # (used to be isa_ok) 'X::Unavailable',
    "can't lock already-locked resources"
  );

  ok($lock->is_locked, 'lock is active');
  $lock->unlock;
  ok(!$lock->is_locked, 'lock is not active');
  ok(eval { $lock->unlock; 1}, 'unlock twice works');
}

{
  my $lock = $locker->lock('Zombie Soup');
  isa_ok($lock, 'DBIx::Locker::Lock', 'newly obtained lock');

  isnt($lock->guid, $guid, "new lock guid is not the old lock guid");

  my $lock_2 = $locker->lock('Zombie Cola');
  isa_ok($lock_2, 'DBIx::Locker::Lock', 'third lock');
  isnt($lock->lock_id, $lock_2->lock_id, 'two locks, two distinct id values');
}

{
  my $lock = $locker->lock('Zombie Time Machine');
  my $original_expiry = $lock->expires;
  my $new_expiry = time + 1000;
  $lock->expires($new_expiry);
  is($lock->expires, $new_expiry, "lock expiry updated correctly in object");
  my $dbh = $locker->dbh;
  my $sth = $dbh->prepare('SELECT expires FROM locks WHERE id = ?');
  $sth->execute($lock->lock_id);
  my ($new_expires) = $sth->fetchrow_array;
  is(
    $new_expires,
    $locker->_time_to_string([ localtime $new_expiry ]),
    "lock expiry updated correctly in DB"
  );
}

{
  my $lock = $locker->lock('a');
  eval { $locker->lock('a') };
  like(
    $@, qr/could not lock resource <a>:.*(?:not unique|unique constraint)/si,
    'underlying DB exception included'
  );
}
