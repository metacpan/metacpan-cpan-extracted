#!/usr/bin/perl

package Context::Handle::RV::RefObject;
use base qw/Context::Handle::RV::Scalar/;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $code = shift;

	my $nop = sub { $_[0] };
	$class->SUPER::new( sub { $code->()->$nop } );
}

__PACKAGE__;

__END__
