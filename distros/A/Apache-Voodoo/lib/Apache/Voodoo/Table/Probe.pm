package Apache::Voodoo::Table::Probe;

$VERSION = "3.0200";

use strict;
use warnings;

use DBI;

sub new {
	my $class = shift;
	my $dbh   = shift;

	# From the DBI docs.  This will give use the database server name
	my $db_type = $dbh->get_info(17);

	my $obj  = "Apache::Voodoo::Table::Probe::$db_type";
	my $file = "Apache/Voodoo/Table/Probe/$db_type.pm";

	eval {
		require $file;
	};
	if ($@) {
		die "$db_type isn't supported\n$@\n";
	}

	return $obj->new($dbh);
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
