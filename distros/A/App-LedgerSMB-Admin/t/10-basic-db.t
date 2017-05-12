use Test::More;
use Test::Exception;
use App::LedgerSMB::Admin;
use App::LedgerSMB::Admin::Database;

plan skip_all => 'DB_TESTING is not set' unless $ENV{DB_TESTING};
plan tests => 10;

ok(App::LedgerSMB::Admin->add_paths(
      '0.1' => 't/data/mock1',
      '0.2' => 't/data/mock2'
  ), 'Added paths');

my $db;

ok($db = App::LedgerSMB::Admin::Database->new(
      username => 'postgres',
      host     => 'localhost',
      dbname   => 'app_ledgersmb_test',
   ), 'New database management object created'
);

eval { $db->drop };

dies_ok { $db->major_version } "can't get major version on nonexistent db";
ok($db = $db->new($db->export), 'Copied db credentials into new object');

ok($db->create, 'Created database');
ok($db->load('0.1'), 'Loaded base schema');

lives_ok {$db->major_version} "Lived when calling major version this time.";
is($db->major_version, '0.1', 'Correct major version');

lives_ok {$db->upgrade_to('0.2'); } 'Upgraded to 0.2';
is($db->new($db->export)->major_version, 0.2, 'Correct major version after upgrade');

