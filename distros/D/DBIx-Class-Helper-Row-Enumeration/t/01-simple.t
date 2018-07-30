use Test::Most;

use lib 't/lib';

use_ok 'Test::Schema';

my $dsn    = "dbi:SQLite::memory:";
my $schema = Test::Schema->deploy_or_connect($dsn);

ok my $rs = $schema->resultset('A'), 'resultset';

ok my $row =
  $rs->create( { id => 1, foo => 'good', bar => 'ugly', baz => 'bad' } ),
  'create';

can_ok $row, qw/ is_good is_bad is_ugly good_bar coyote
   baz_est_bien baz_est_mal /;

ok $row->$_, $_ for (qw/ is_good coyote baz_est_mal /);
ok !$row->$_, $_ for (qw/ is_bad is_ugly good_bar baz_est_bien /);

done_testing;
