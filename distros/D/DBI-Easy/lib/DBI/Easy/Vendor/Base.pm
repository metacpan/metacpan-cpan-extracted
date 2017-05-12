package DBI::Easy::Vendor::Base;

use Class::Easy;

sub vendor_schema {
	return;
}

sub _init_vendor {

}

sub _datetime_format {
	'%Y-%m-%d %H:%M:%S';
}

sub quote_identifier {
	my $class = shift;
	
	return $class->dbh->quote_identifier (@_);
}

sub quote {
	my $class = shift;
	
	return $class->dbh->quote (@_);
}


1;

