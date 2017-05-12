package Bio::ConnectDots::Config;
# Database connection file. These values will be the default connection settings 
# used in all scripts provided with the package. Simply change the fields to match your
# database connection parameters

sub db {
	my ($db) = @_;
	my $info;

	if($db =~ /production/i) {
		$info = {
			host=>'yuki',
			user=>'dburdick',
			password=>'password',
			dbname=>'ctd_db2'
		};
	}
	
	if($db =~ /test/i) {
		$info = {
			host=>'yuki',
			user=>'dburdick',
			password=>'password',
			dbname=>'ctd_unittest'
		};
	}
	return $info;
}

1;