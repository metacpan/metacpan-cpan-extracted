package Apache::Voodoo::View;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo");

#
# Gets or sets the returned content type
#
sub content_type {
	my $self = shift;

	if (defined($_[0])) {
		$self->{content_type} = shift;
	}

	return $self->{content_type};
}

#
# Called at the begining of each request
#
sub begin { }

#
# Called multiple times as each handler / controller produces data.
#
sub params { }

#
# Called whenver an exception is thrown by the handler / controller.
#
sub exception { }

#
# Whatever this method returns is passed to the browser.
#
sub output { }

#
# Called at the end of each request.  Here is where any cleanup happens.
#
sub finish { }

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
