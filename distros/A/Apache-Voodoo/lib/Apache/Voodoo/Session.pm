################################################################################
#
# Factory that creates either a file based or mysql based session storage object.
#
################################################################################
package Apache::Voodoo::Session;

$VERSION = "3.0200";

use strict;
use warnings;

sub new {
	my $class = shift;
	my $conf  = shift;

	if (defined($conf->{'session_table'})) {
		unless (defined($conf->{'database'})) {
			die "You have sessions configured to be stored in the database but no database configuration.";
		}

		require Apache::Voodoo::Session::MySQL;
		return Apache::Voodoo::Session::MySQL->new($conf);
	}
	elsif (defined($conf->{'session_dir'})) {
		require Apache::Voodoo::Session::File;
		return Apache::Voodoo::Session::File->new($conf);
	}
	else {
		die "You do not have a session storage mechanism defined.";
	}
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
