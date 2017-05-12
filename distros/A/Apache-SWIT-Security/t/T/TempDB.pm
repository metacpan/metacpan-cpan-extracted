use strict;
use warnings FATAL => 'all';

package T::TempDB;
use Apache::SWIT::Test::DB;
Apache::SWIT::Test::DB->setup('assec_test_db'
		, 'Apache::SWIT::Security::DB::Schema');

1;
