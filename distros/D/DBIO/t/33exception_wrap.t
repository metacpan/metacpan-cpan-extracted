use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
my $schema = DBIO::Test->init_schema(no_deploy => 1);

throws_ok (sub {
  $schema->txn_do (sub { die 'lol' } );
}, 'DBIO::Exception', 'a DBIO::Exception object thrown');

throws_ok (sub {
  $schema->txn_do (sub { die [qw/lol wut/] });
}, qr/ARRAY\(0x/, 'An arrayref thrown');

is_deeply (
  $@,
  [qw/ lol wut /],
  'Exception-arrayref contents preserved',
);

done_testing;
