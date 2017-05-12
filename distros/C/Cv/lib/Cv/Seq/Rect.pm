# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Seq::Rect;

use 5.008008;
use strict;
use warnings;

use Cv::Seq::Point;

our $VERSION = '0.29';
our @ISA = qw(Cv::Seq::Point);

{ no strict 'refs'; *AUTOLOAD = \&Cv::autoload; }

sub template {
	my $self = CORE::shift;
	my ($t, $c) = ("i4", 4);
	wantarray? ($t, $c) : $t;
}

1;
