#!/usr/bin/perl

package Context::Handle::RV::Scalar;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $code = shift;

	my $val = $code->();
	bless \$val, $pkg;
}

sub value {
	my $self = shift;
	$$self;
}

__PACKAGE__;

__END__
