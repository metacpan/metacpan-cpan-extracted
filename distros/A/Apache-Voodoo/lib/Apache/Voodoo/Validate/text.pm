package Apache::Voodoo::Validate::text;

use strict;
use warnings;

use base("Apache::Voodoo::Validate::varchar");

sub config {
	my ($self,$c) = @_;

	$c->{length} = 0;

	return $self->SUPER::config($c);
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
