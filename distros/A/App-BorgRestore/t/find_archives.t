use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Test::Differences;
use Test::Exception;

use App::BorgRestore;
use App::BorgRestore::DB;
use Log::Any::Adapter ('TAP');

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

eq_or_diff($app->find_archives('test/path'), [
		{
			archive => 'test1',
			modification_time => 5
		},
		{
			archive => 'test3',
			modification_time => 10
		},
	]);

dies_ok {$app->find_archives('test/nope')};
is ($@, "Path 'test/nope' not found in any archive.\n");

done_testing;
