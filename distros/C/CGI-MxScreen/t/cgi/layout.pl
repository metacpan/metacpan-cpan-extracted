#
# $Id: layout.pl,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: layout.pl,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

package Test_Layout;

use base qw(CGI::MxScreen::Layout);

use CGI qw/:standard/;

sub make {
	return bless {}, shift;
}

sub init {
	my $self = shift;
	my ($screen) = @_;
	$self->{screen} = $screen;
}

sub preamble {
	my $self = shift;
	my $screen = $self->{screen};
	my $name;
	$name = $screen->name if defined $screen;
	print p("PREAMBLE for screen '$name'"), hr;
}

sub postamble {
	my $self = shift;
	my $screen = $self->{screen};
	my $name;
	$name = $screen->name if defined $screen;
	print p("POSTAMBLE for screen '$name'"), hr;
}

1;

