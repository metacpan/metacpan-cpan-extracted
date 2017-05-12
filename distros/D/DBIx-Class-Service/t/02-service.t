use Test::More tests => 3;

use lib qw(./t/lib);

use DBICx::TestDatabase;
use DBIC::Test::Schema;

my $schema = DBICx::TestDatabase->new('DBIC::Test::Schema');

my $user = $schema->service('User')->add_user({
    user_id => 'zigorou',
    password => 'aaaa',
    name => 'ZIGOROu Masuda',
    nickname => 'ZIGOROu',
});

is($user->user_id, 'zigorou');
is($schema->service('User')->authenticate('zigorou', 'aaaa')->user_id, 'zigorou');

my $diary = $schema->service('User')->add_diary('zigorou', 'test', 'test content');
is($diary->title, 'test');
