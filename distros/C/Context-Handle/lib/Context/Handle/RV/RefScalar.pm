#!/usr/bin/perl

package Context::Handle::RV::RefScalar;
use base qw/Context::Handle::RV::Scalar/;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $code = shift;

	$class->SUPER::new( sub { \${ $code->() } } );
}

__PACKAGE__;

__END__
