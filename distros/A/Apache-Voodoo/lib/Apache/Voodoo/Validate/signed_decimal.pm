package Apache::Voodoo::Validate::signed_decimal;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Validate::Plugin");

sub config {
	my ($self,$c) = @_;
	my @e;
	if (defined($c->{left})) {
		if ($c->{left} =~ /^\d+$/) {
			$self->{left} = $c->{left};
		}
		else {
			push(@e,"'left' must be positive integer");
		}
	}
	else {
		push(@e,"'left' must be positive integer");
	}

	if (defined($c->{right})) {
		if ($c->{right} =~ /^\d+$/) {
			$self->{right} = $c->{right};
		}
		else {
			push(@e,"'right' must be positive integer");
		}
	}
	else {
		push(@e,"'right' must be positive integer");
	}

	return @e;
}

sub valid {
	my ($self,$v) = @_;

	my $e;
	if ($v =~ /^(\+|-)?(\d*)(?:\.(\d+))?$/) {
		my $l = $2 || 0;
		my $r = $3 || 0;
		$l *= 1;
		$r *= 1;

		if (length($l) > $self->{'left'} ||
			length($r) > $self->{'right'} ) {
			$e='BIG';
		}
	}
	else {
		$e='BAD';
	}
	return $v,$e;
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
