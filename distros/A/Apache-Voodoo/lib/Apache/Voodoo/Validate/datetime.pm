package Apache::Voodoo::Validate::datetime;

use strict;
use warnings;

use base("Apache::Voodoo::Validate::Plugin");

use Apache::Voodoo::Validate::date;
use Apache::Voodoo::Validate::time;

sub config {
	my ($self,$c) = @_;

	my @e;
	push(@e,Apache::Voodoo::Validate::date::config($self,@_));
	push(@e,Apache::Voodoo::Validate::time::config($self,@_));
	return @e;
}

sub valid {
	my ($self,$v) = @_;

	my ($d,$t) = split(/ /,$v);

	my ($vd,$ed) = Apache::Voodoo::Validate::date::valid($self,$d);
	my ($vt,$et) = Apache::Voodoo::Validate::time::valid($self,$t);

	my @e;
	if ($ed) {
		push(@e,$ed);
	}

	if ($et) {
		push(@e,$et);
	}

	if (scalar @e) {
		return undef,@e;
	}
	else {
		return "$vd $vt";
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
