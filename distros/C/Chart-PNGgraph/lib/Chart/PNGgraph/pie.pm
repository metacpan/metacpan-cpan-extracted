#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph::pie.pm
#
# $Id: pie.pm,v 1.1.1.1.2.3.2.1 2000/04/05 02:45:37 sbonds Exp $
#
#==========================================================================

package Chart::PNGgraph::pie;
use strict;
use Chart::PNGgraph;
use GD::Graph::pie;
@Chart::PNGgraph::pie::ISA = qw(GD::Graph::pie Chart::PNGgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
