#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyApp::Controller::FF;

use Moose;
extends 'Catalyst::Controller';
with 'Catalyst::Component::InstancePerContext';
sub build_per_context_instance {
#	use Devel::Dwarn;
#	DwarnN(\@_);
	shift
}
1;