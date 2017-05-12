use strict;
use warnings FATAL => 'all';

package Apache::SWIT::DB::Base;
use base 'Class::DBI::Pg::More';
use Apache::SWIT::DB::Connection;

sub db_Main {
	return Apache::SWIT::DB::Connection->instance->db_handle;
}

1;
