use strictures 2;

use Log::Any::Adapter ('TAP');
use POSIX qw(tzset);
use Test::Differences;
use Test::MockObject;
use Test::More;

use App::BorgRestore;
use App::BorgRestore::Settings;

for my $in_memory (0,1) {
	my $db = App::BorgRestore::DB->new(":memory:", 0);

	$ENV{TZ} = 'UTC';
	tzset;

	my $borg = Test::MockObject->new();
	$borg->set_list('borg_list', ['archive-1']);
	$borg->mock('list_archive', sub {
			my ($self, $archive, $cb) = @_;
			$cb->("XXX, 1970-01-01 00:00:05 .");
			$cb->("XXX, 1970-01-01 00:00:10 boot");
			$cb->("XXX, 1970-01-01 00:00:20 boot/grub");
			$cb->("XXX, 1970-01-01 00:00:08 boot/grub/grub.cfg");
			$cb->("XXX, 1970-01-01 00:00:13 boot/foo");
			$cb->("XXX, 1970-01-01 00:00:13 boot/foo/blub");
			$cb->("XXX, 1970-01-01 00:00:19 boot/foo/bar");
			$cb->("XXX, 1970-01-01 00:00:02 boot/test1");
			$cb->("XXX, 1970-01-01 00:00:03 boot/test1/f1");
			$cb->("XXX, 1970-01-01 00:00:04 boot/test1/f2");
			$cb->("XXX, 1970-01-01 00:00:03 boot/test1/f3");
			$cb->("XXX, 1970-01-01 00:00:02 boot/test1/f4");
			$cb->("XXX, 1970-01-01 00:00:03 etc");
			$cb->("XXX, 1970-01-01 00:00:02 etc/foo");
			$cb->("XXX, 1970-01-01 00:00:01 etc/foo/bar");
			$cb->("XXX, 1970-01-01 00:00:01 etc/foo/blub");
		} );

	# Call the actual function we want to test
	my $app = App::BorgRestore->new_no_defaults({borg => $borg, db => $db}, {cache => {prepare_data_in_memory => $in_memory}});
	$app->_handle_added_archives(['archive-1']);

	# check database content
	eq_or_diff($db->get_archives_for_path('.'), [{archive => 'archive-1', modification_time => undef},]);
	eq_or_diff($db->get_archives_for_path('boot'), [{archive => 'archive-1', modification_time => 20},]);
	eq_or_diff($db->get_archives_for_path('boot/foo'), [{archive => 'archive-1', modification_time => 19},]);
	eq_or_diff($db->get_archives_for_path('boot/foo/bar'), [{archive => 'archive-1', modification_time => 19},]);
	eq_or_diff($db->get_archives_for_path('boot/foo/blub'), [{archive => 'archive-1', modification_time => 13},]);
	eq_or_diff($db->get_archives_for_path('boot/grub'), [{archive => 'archive-1', modification_time => 20},]);
	eq_or_diff($db->get_archives_for_path('boot/grub/grub.cfg'), [{archive => 'archive-1', modification_time => 8},]);
	eq_or_diff($db->get_archives_for_path('boot/test1'), [{archive => 'archive-1', modification_time => 4},]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f1'), [{archive => 'archive-1', modification_time => 3},]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f2'), [{archive => 'archive-1', modification_time => 4},]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f3'), [{archive => 'archive-1', modification_time => 3},]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f4'), [{archive => 'archive-1', modification_time => 2},]);
	eq_or_diff($db->get_archives_for_path('etc'), [{archive => 'archive-1', modification_time => 3},]);
	eq_or_diff($db->get_archives_for_path('etc/foo'), [{archive => 'archive-1', modification_time => 2},]);
	eq_or_diff($db->get_archives_for_path('etc/foo/bar'), [{archive => 'archive-1', modification_time => 1},]);
	eq_or_diff($db->get_archives_for_path('etc/foo/blub'), [{archive => 'archive-1', modification_time => 1},]);
	eq_or_diff($db->get_archives_for_path('lulz'), [{archive => 'archive-1', modification_time => undef},]);


	# add second archive
	$borg->set_list('borg_list', ['archive-1', 'archive-2']);
	$borg->mock('list_archive', sub {
			my ($self, $archive, $cb) = @_;
			$cb->("XXX, 1970-01-01 00:00:05 .");
			$cb->("XXX, 1970-01-01 00:00:10 boot");
			$cb->("XXX, 1970-01-01 00:00:20 boot/grub");
			$cb->("XXX, 1970-01-01 00:00:08 boot/grub/grub.cfg");
			$cb->("XXX, 1970-01-01 00:00:13 boot/foo");
			$cb->("XXX, 1970-01-01 00:00:13 boot/foo/blub");
			$cb->("XXX, 1970-01-01 00:00:19 boot/foo/bar");
			$cb->("XXX, 1970-01-01 00:00:02 boot/test1");
			$cb->("XXX, 1970-01-01 00:00:03 boot/test1/f1");
			$cb->("XXX, 1970-01-01 00:00:05 boot/test1/f2");
			$cb->("XXX, 1970-01-01 00:00:03 boot/test1/f3");
			$cb->("XXX, 1970-01-01 00:00:02 boot/test1/f4");
			$cb->("XXX, 1970-01-01 00:00:07 boot/test1/f5");
			$cb->("XXX, 1970-01-01 00:00:03 etc");
			$cb->("XXX, 1970-01-01 00:00:02 etc/foo");
			$cb->("XXX, 1970-01-01 00:00:01 etc/foo/bar");
		} );
	$app->_handle_added_archives(['archive-2']);

	# check database content
	eq_or_diff($db->get_archives_for_path('.'), [
		{archive => 'archive-1', modification_time => undef},
		{archive => 'archive-2', modification_time => undef},
	]);
	eq_or_diff($db->get_archives_for_path('boot'), [
		{archive => 'archive-1', modification_time => 20},
		{archive => 'archive-2', modification_time => 20},
	]);
	eq_or_diff($db->get_archives_for_path('boot/foo'), [
		{archive => 'archive-1', modification_time => 19},
		{archive => 'archive-2', modification_time => 19},
	]);
	eq_or_diff($db->get_archives_for_path('boot/foo/bar'), [
		{archive => 'archive-1', modification_time => 19},
		{archive => 'archive-2', modification_time => 19},
	]);
	eq_or_diff($db->get_archives_for_path('boot/foo/blub'), [
		{archive => 'archive-1', modification_time => 13},
		{archive => 'archive-2', modification_time => 13},
	]);
	eq_or_diff($db->get_archives_for_path('boot/grub'), [
		{archive => 'archive-1', modification_time => 20},
		{archive => 'archive-2', modification_time => 20},
	]);
	eq_or_diff($db->get_archives_for_path('boot/grub/grub.cfg'), [
		{archive => 'archive-1', modification_time => 8},
		{archive => 'archive-2', modification_time => 8},
	]);
	eq_or_diff($db->get_archives_for_path('boot/test1'), [
		{archive => 'archive-1', modification_time => 4},
		{archive => 'archive-2', modification_time => 7},
	]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f1'), [
		{archive => 'archive-1', modification_time => 3},
		{archive => 'archive-2', modification_time => 3},
	]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f2'), [
		{archive => 'archive-1', modification_time => 4},
		{archive => 'archive-2', modification_time => 5},
	]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f3'), [
		{archive => 'archive-1', modification_time => 3},
		{archive => 'archive-2', modification_time => 3},
	]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f4'), [
		{archive => 'archive-1', modification_time => 2},
		{archive => 'archive-2', modification_time => 2},
	]);
	eq_or_diff($db->get_archives_for_path('boot/test1/f5'), [
		{archive => 'archive-1', modification_time => undef},
		{archive => 'archive-2', modification_time => 7},
	]);
	eq_or_diff($db->get_archives_for_path('etc'), [
		{archive => 'archive-1', modification_time => 3},
		{archive => 'archive-2', modification_time => 3},
	]);
	eq_or_diff($db->get_archives_for_path('etc/foo'), [
		{archive => 'archive-1', modification_time => 2},
		{archive => 'archive-2', modification_time => 2},
	]);
	eq_or_diff($db->get_archives_for_path('etc/foo/bar'), [
		{archive => 'archive-1', modification_time => 1},
		{archive => 'archive-2', modification_time => 1},
	]);
	eq_or_diff($db->get_archives_for_path('etc/foo/blub'), [
		{archive => 'archive-1', modification_time => 1},
		{archive => 'archive-2', modification_time => undef},
	]);
	eq_or_diff($db->get_archives_for_path('lulz'), [
		{archive => 'archive-1', modification_time => undef},
		{archive => 'archive-2', modification_time => undef},
	]);
}


done_testing;
