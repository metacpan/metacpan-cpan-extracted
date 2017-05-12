package Apache::Voodoo::Loader::Static;

$VERSION = "3.0200";

use strict;
use base("Apache::Voodoo::Loader");

sub new {
	my $class = shift;
	my $self = {};
	bless $self,$class;

	# bingo...this is a factory
	return $self->load_module(shift);
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
