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
		log => {
			additional_fields => ['field1', 'field2']
		},
	}
};


response_status_isnt [ GET => '/01_prepare_env_a/field1/field2'], 404, 'Prepare test environment with additional fields';

response_content_is '/04_add_common_log_entry/Hello/undef/Hello_there/Hello_again', 1, 'Add new log message';
response_content_is '/04_check_common_log_entry/Hello/undef/Hello_there/Hello_again', 1, 'Check message';

response_content_is '/04_check_common_log_entry/He33o/undef/Hello_there/Hello_again', 0, 'Check message that is not exist';

response_content_is '/04_add_common_log_entry/Hello/123456789/Hey/Hi', 1, 'Add new log message with explicit timestamp';
response_content_is '/04_check_common_log_entry/Hello/123456789/Hey/Hi', 1, 'Check message with explicit timestamp';
response_content_is '/04_check_common_log_entry/Hello/000123456/Hey/Hi', 0, 'Check message with explicit but wrong timestamp';

response_status_isnt '/99_remove_env', 404, 'Remove database';

TODO: {
	local $TODO = "Not implemented in TestApp yet";
};

