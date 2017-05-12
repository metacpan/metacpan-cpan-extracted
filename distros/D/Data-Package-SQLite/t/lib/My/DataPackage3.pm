package My::DataPackage3;

# Default implementation, use all defaults

use strict;
use base 'Data::Package::SQLite';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub sqlite_location {
	dist_file => 'My-DataPackage3', 'data3.sqlite'
}

1;
