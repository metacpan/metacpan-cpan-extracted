use strict;
use warnings;
use Test::More;

use t::lib::TestApp;
use Dancer ':tests';
use Dancer::Test;

set plugins => {
	"Log::DB" => {
		database => {
			driver => 'SQLite',
			database => 'dancer-plugin-log-db-test.sqlite'
		},
		log => {},
	}
};


response_status_isnt [ GET => '/01_prepare_env/message/timestamp'], 404, 'Prepare test environment for message/timestamp database';
response_content_is '/05_add_common_log_entry/Hello/undef', 1, 'Add new log message';
response_status_isnt '/99_remove_env', 404, 'Remove database';

done_testing();

