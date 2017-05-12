package Apache::Voodoo::Validate::bit;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Validate::Plugin");

sub config {
	my ($self,$conf) = @_;
	return ();
}

sub valid {
	my ($self,$v) = @_;

	if ($v =~ /^(0*[1-9]\d*|y(es)?|t(rue)?)$/i) {
		return 1;
	}
	elsif ($v =~ /^(0+|n(o)?|f(alse)?)$/i) {
		return 0;
	}
	else {
		return undef,'BAD';
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
