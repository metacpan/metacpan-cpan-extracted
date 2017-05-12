# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Seq::SURFPoint;

use 5.008008;
use strict;
use warnings;

use Cv::Seq::Point;

our $VERSION = '0.29';
our @ISA = qw(Cv::Seq::Point);

{ no strict 'refs'; *AUTOLOAD = \&Cv::autoload; }

sub template {
	my $self = CORE::shift;
	my ($t, $c) = ("f2i2f2", 6);
	wantarray? ($t, $c) : $t;
}


sub Pack {
	my $self = CORE::shift;
	my $t = $self->template;
	CORE::pack($t, @{$_[0]}, @_[1..$#_]);
}


sub Unpack {
	my $self = CORE::shift;
	my $t = $self->template;
	return undef unless defined $_[0];
	# no warnings 'uninitialized';
	my ($x, $y, @r) = CORE::unpack($t, $_[0]);
	my @elem = ([ $x, $y ], @r);
	wantarray? @elem : \@elem;
}


sub UnpackMulti {
	my $self = CORE::shift;
	my ($t, $c) = $self->template;
	return undef unless defined $_[1];
	# no warnings 'uninitialized';
	my @data = CORE::unpack("($t)*", $_[1]);
	while (my ($x, $y, @r) = CORE::splice(@data, 0, $c)) {
		CORE::push(@{$_[0]}, [[$x, $y], @r]);
	}
}

1;
