package DBI::Easy::Vendor::mysql;

use Class::Easy;

use base qw(DBI::Easy::Vendor::Base);

sub _convertable_fields {
	return {
		DATETIME  => "%Y-%m-%d %H:%M:%S", # 1000-01-01 to 9999-12-31
		DATE      => "%Y-%m-%d", # 1000-01-01 to 9999-12-31
		TIMESTAMP => "%Y-%m-%d %H:%M:%S", # 1970-01-01 to 2038-01-19 03:14:07
	}
}

1;