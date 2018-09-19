use strictures 2;

use Log::Any::Adapter ('TAP');
use Test::More;
use Test::MockObject;
use Test::Differences;

use App::BorgRestore;

my $db = Test::MockObject->new();
my $app = App::BorgRestore->new_no_defaults({db => $db});

$db->mock('get_archive_names', sub {return [qw(a b c)];});
is($app->cache_contains_data(), 1);

$db->mock('get_archive_names', sub {return [];});
is($app->cache_contains_data(), 0);

$db->mock('get_archive_names', sub {return [qw(a)];});
is($app->cache_contains_data(), 1);

done_testing;
