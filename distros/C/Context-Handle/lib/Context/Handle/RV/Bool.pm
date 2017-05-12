#!/usr/bin/perl

package Context::Handle::RV::Bool;
use base qw/Context::Handle::RV::Scalar/;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $code = shift;

	# although this does enforce boolean context,
	# it doesn't return the actual value.
	# this probably doesn't matter, since you can't
	# get anything back from a boolean context'd expr.
	$pkg->SUPER::new( sub { $code->() ? 1 : "" } )
}

__PACKAGE__;

__END__
