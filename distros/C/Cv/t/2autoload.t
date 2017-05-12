# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 60;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore, -seq, -bg, -subdiv) }

if (1) {
	throws_ok { Cv->NotDefined() } qr/can't call Cv::NotDefined at $0/;
}

if (2) {
	{ package Cv; sub Foo { } }
	throws_ok { Cv->FOO() } qr/can't call Cv::FOO at $0/;
	lives_ok  { Cv->Foo() };
	lives_ok  { Cv->foo() };
	throws_ok { Cv->fOO() } qr/can't call Cv::fOO at $0/;
}

if (3) {
	{ package Cv; sub BAR { } }
	lives_ok  { Cv->BAR() };
	throws_ok { Cv->Bar() } qr/can't call Cv::Bar at $0/;
	lives_ok  { Cv->bar() };
	lives_ok  { Cv->bAR() };
}

if (4) {
	throws_ok { Cv->cvmGet() } qr/can't call Cv::cvmGet at $0/;
}

if (5) {
	my $cv = bless [], 'Cv';
	throws_ok { $cv->alloc() } qr/class name needed at $0/;
}

ok(!defined $Cv::Constant::{AUTOLOAD});
ok(!defined $Cv::Image::Ghost::{AUTOLOAD});
ok(!defined $Cv::Mat::Ghost::{AUTOLOAD});
ok(!defined $Cv::MatND::Ghost::{AUTOLOAD});
ok(!defined $Cv::More::{AUTOLOAD});
ok(!defined $Cv::SparseMat::Ghost::{AUTOLOAD});

for (&classes('Cv')) {
	next if /^Cv::.*::Ghost$/;
	next if /^Cv::(Constant|More)$/;
	my $AUTOLOAD = "${_}::AUTOLOAD";
	is(\&{$AUTOLOAD}, \&Cv::autoload, $_);
}

sub classes {
	my @list = ();
	my $name = shift;
	my $class = eval "\\%${name}::";
	if (ref $class eq 'HASH') {
		for (keys %$class) {
			if (/^(\w+)::$/) {
				push(@list, &classes("${name}::$1"));
			}
		}
		push(@list, $name);
	}
	@list;
}
