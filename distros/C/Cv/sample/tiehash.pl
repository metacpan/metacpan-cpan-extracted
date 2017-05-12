#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

package Cv::TieHash;

use Tie::Hash;

our @ISA = qw(Tie::Hash);

sub Cv::Arr::THIS { $_[0] }

sub TIEHASH {
	bless [ $_[1] ], $_[0];
}

sub FETCH {
	my ($self, $key) = @_;
	my $arr = $self->[0];
	if (ref $key eq 'ARRAY') {
		$arr->get($key);
	} else {
		$arr->$key();
	}
}

sub STORE {
	my ($self, $key, $value) = @_;
	my $arr = $self->[0];
	if (ref $key eq 'ARRAY') {
		# $arr->set($key, $value);
		$arr->SetND($key, $value);
	} else {
		$arr->$key($value);
	}
}	


package main;

use Time::HiRes qw(gettimeofday);
use Data::Dumper;

tie my %image, 'Cv::TieHash', Cv::Image->new([ 240, 320 ], CV_8UC3);

$image{fill} = cvScalarAll(127);

foreach (qw(type depth channels origin sizes avg)) {
	print Data::Dumper->Dump([$image{$_}], ["\$image{$_}"]);
}

my $t0 = gettimeofday;

$image{origin} = 1;
foreach my $row (0 .. $image{rows} - 1) {
	foreach my $col (0 .. $image{cols} - 1) {
		$image{[$row, $col]} = [ map { ($col & $_) && 0xff } 1, 2, 4 ];
	}
	$image{THIS}->show($0);
	my $c = Cv->waitKey(33);
	last if ($c >= 0 && ($c & 0x7f) == 27);
}

my $t1 = gettimeofday;
print $t1 - $t0, "\n";

$image{origin} = 0;
foreach my $row (0 .. $image{rows} - 1) {
	foreach my $col (0 .. $image{cols} - 1) {
		$image{[$row, $col]} = [ map { $_ ^ 0xff } @{$image{[$row, $col]}} ];
	}
	$image{THIS}->show($0);
	my $c = Cv->waitKey(33);
	last if ($c >= 0 && ($c & 0x7f) == 27);
}

my $t2 = gettimeofday;
print $t2 - $t1, "\n";

Cv->waitKey(1000);
