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
			message_field_name => 'message_field',
			timestamp_field_name => 'timestamp_field',
		},
	}
};


response_status_isnt [ GET => '/01_prepare_env/message_field/timestamp_field'], 404, 'Prepare test environment for message_field/timestamp_field database';

response_content_is '/03_add_common_log_entry/Hello/undef', 1, 'Add new log message';
response_content_is '/03_check_common_log_entry/Hello/undef', 1, 'Check message';
response_content_is '/03_check_common_log_entry/He33o/undef', 0, 'Check message that is not exist';

response_content_is '/03_add_common_log_entry/Hello/123456789', 1, 'Add new log message with explicit timestamp';
response_content_is '/03_check_common_log_entry/Hello/123456789', 1, 'Check message with explicit timestamp';
response_content_is '/03_check_common_log_entry/Hello/000123456', 0, 'Check message with explicit but wrong timestamp';

response_status_isnt '/99_remove_env', 404, 'Remove database';	


TODO: {
	local $TODO = "Not implemented in TestApp yet";
};

