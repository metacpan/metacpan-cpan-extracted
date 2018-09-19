use strictures 2;

use Log::Any::Adapter ('TAP');
use Test::More;
use Test::MockObject;
use Test::Differences;

use App::BorgRestore;
use App::BorgRestore::DB;

my $db = App::BorgRestore::DB->new(":memory:", 0);
my $app = App::BorgRestore->new_no_defaults({db => $db});

$db->add_archive_name("test1");
my $archive_id1 = $db->get_archive_id("test1");
$db->add_archive_name("test2");
my $archive_id2 = $db->get_archive_id("test2");
$db->add_archive_name("test3");
my $archive_id3 = $db->get_archive_id("test3");
$db->add_archive_name("test4");
my $archive_id4 = $db->get_archive_id("test4");

$db->add_path($archive_id1, "test/path", 5);
$db->add_path($archive_id1, "test/foo", 4);
$db->add_path($archive_id1, "test", 5);

$db->add_path($archive_id2, "test/path", 5);
$db->add_path($archive_id2, "test", 5);

$db->add_path($archive_id3, "test/path", 10);
$db->add_path($archive_id3, "test/foo", 4);
$db->add_path($archive_id3, "test", 10);

eq_or_diff($app->search_path("test"), ['test', 'test/foo', 'test/path']);
eq_or_diff($app->search_path("test%"), ['test', 'test/foo', 'test/path']);
eq_or_diff($app->search_path("%foo"), ['test/foo']);

done_testing;
