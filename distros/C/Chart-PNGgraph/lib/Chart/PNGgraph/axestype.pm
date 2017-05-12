#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph::axestype.pm
#
#	This package is not in use for Chart::PNGgraph itself anymore, but it's
#	here in case anyone subclasses this. Hopefully it will still work.
#
# $Id: axestype.pm,v 1.1.1.1.2.5.2.5 2000/04/05 02:45:37 sbonds Exp $
#
#==========================================================================

package Chart::PNGgraph::axestype;
use strict;
use Chart::PNGgraph;
use GD::Graph::axestype;
@Chart::PNGgraph::axestype::ISA = qw(GD::Graph::axestype Chart::PNGgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
