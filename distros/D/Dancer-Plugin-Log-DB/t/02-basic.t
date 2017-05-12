use strict;
use warnings;
use Test::More tests => 8;

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

response_content_is '/02_add_common_log_entry/Hello/undef', 1, 'Add new log message';
response_content_is '/02_check_common_log_entry/Hello/undef', 1, 'Check message';
response_content_is '/02_check_common_log_entry/He33o/undef', 0, 'Check message that is not exist';

response_content_is '/02_add_common_log_entry/Hello/123456789', 1, 'Add new log message with explicit timestamp';
response_content_is '/02_check_common_log_entry/Hello/123456789', 1, 'Check message with explicit timestamp';
response_content_is '/02_check_common_log_entry/Hello/000123456', 0, 'Check message with explicit but wrong timestamp';

response_status_isnt '/99_remove_env', 404, 'Remove database';

TODO: {
	local $TODO = "Not implemented in TestApp yet";	
};

