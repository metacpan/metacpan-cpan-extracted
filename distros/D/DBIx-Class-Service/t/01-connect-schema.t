use Test::More tests => 3;

use lib qw(./t/lib);

use DBICx::TestDatabase;
use DBIC::Test::Schema;

my $schema;

eval {
    $schema = DBICx::TestDatabase->new('DBIC::Test::Schema');
};

ok(!$@);
ok(ref $schema);
ok($schema->can("service"));
