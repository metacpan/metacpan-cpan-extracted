package Apache::Voodoo::Validate::time;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Validate::Plugin");

sub config {
	my ($self,$c) = @_;

	my @e;
	if (defined($c->{min})) {
		my $t = _valid_time($c->{min});
		if ($t) {
			$self->{'min'} = $t;
		}
		else {
			push(@e,"'min' must be a valid time in either civillian or military form.");
		}
	}

	if (defined($c->{max})) {
		my $t = _valid_time($c->{max});
		if ($t) {
			$self->{'max'} = $t;
		}
		else {
			push(@e,"'max' must be a valid time in either civillian or military form.");
		}
	}

	return @e;
}

sub valid {
	my ($self,$v) = @_;

	$v = _valid_time($v);
	unless ($v) {
		return undef,'BAD';
	}

	if (defined($self->{min}) && $v lt $self->{min}) {
		return undef,'MIN';
	}

	if (defined($self->{max}) && $v gt $self->{max}) {
		return undef,'MAX';
	}

	return $v;
}


sub _valid_time {
	my $time = shift;

	$time =~ s/\s*//go;
	$time =~ s/\.//go;

	unless ($time =~ /^\d?\d:[0-5]?\d(:[0-5]?\d)?(am|pm)?$/i) {
		return undef;
	}

	my ($h,$m,$s);
	if ($time =~ s/([ap])m$//igo) {
		my $pm = (lc($1) eq "p")?1:0;

		($h,$m,$s) = split(/:/,$time);

		# 12 am is midnight and 12 pm is noon...I've always hated that.
		if ($pm eq '1') {
			if ($h < 12) {
				$h += 12;
			}
			elsif ($h > 12) {
				return undef;
			}
		}
		elsif ($pm eq '0' && $h == 12) {
			$h = 0;
		}
	}
	else {
		($h,$m,$s) = split(/:/,$time);
	}

	# our regexp above validated the minutes and seconds, so
	# all we need to check that the hours are valid.
	if ($h < 0 || $h > 23) { return undef; }

	$s = 0 unless (defined($s));
	return sprintf("%02d:%02d:%02d",$h,$m,$s);
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
