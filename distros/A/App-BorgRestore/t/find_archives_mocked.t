use strictures 2;

use Log::Any::Adapter ('TAP');
use Test::More;
use Test::MockObject;
use Test::Differences;

use App::BorgRestore;

my $db = Test::MockObject->new();
$db->mock('get_archives_for_path', sub {return [
			{ modification_time => 5, archive => "test2"},
			{ modification_time => 2, archive => "test1"},
			{ modification_time => 10, archive => "test3"},
			{ modification_time => 10, archive => "test4"},
			{ modification_time => 2, archive => "test1-1"},
			{ modification_time => 15, archive => "test5"},
		];});

my $app = App::BorgRestore->new_no_defaults({db => $db});

eq_or_diff($app->find_archives('test/path'), [
  {archive => 'test1', modification_time => 2},
  {archive => 'test2', modification_time => 5},
  {archive => 'test3', modification_time => 10},
  {archive => 'test5', modification_time => 15},
]);

done_testing;
