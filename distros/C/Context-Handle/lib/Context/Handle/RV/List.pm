#!/usr/bin/perl

package Context::Handle::RV::List;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $code = shift;
	bless [ $code->() ], $pkg;
}

sub value {
	my $self = shift;
	@$self;
}

__PACKAGE__;

__END__
