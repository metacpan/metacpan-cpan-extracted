# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 17;
use Test::Exception;
BEGIN { use_ok('Cv', -subdiv) }

# ============================================================
#  CvSubdiv2D*
#  cvCreateSubdivDelaunay2D(CvRect rect, CvMemStorage* storage)
# ============================================================

can_ok('Cv::Subdiv2D', 'cvCreateSubdivDelaunay2D');
if (1) {
	local $Cv::STORAGE = undef;
	my $rect = [ 0, 0, 100, 100 ];
	my $subdiv = Cv::Subdiv2D::cvCreateSubdivDelaunay2D($rect, &Cv::STORAGE);
	isa_ok($subdiv, 'Cv::Subdiv2D');
	ok(scalar grep /cvCreateSubdivDelaunay2D/, @Cv::Subdiv2D::EXPORT_OK);
}

can_ok('Cv', 'cvCreateSubdivDelaunay2D');
if (1) {
	local $Cv::STORAGE = undef;
	my $rect = [ 0, 0, 100, 100 ];
	my $subdiv = Cv::cvCreateSubdivDelaunay2D($rect, &Cv::STORAGE);
	isa_ok($subdiv, 'Cv::Subdiv2D');
	ok(scalar grep /cvCreateSubdivDelaunay2D/, @Cv::EXPORT_OK);
}

can_ok('Cv', 'CreateSubdivDelaunay2D');
if (1) {
	local $Cv::STORAGE = undef;
	my $rect = [ 0, 0, 100, 100 ];
	my $subdiv = Cv->CreateSubdivDelaunay2D($rect, &Cv::STORAGE);
	isa_ok($subdiv, 'Cv::Subdiv2D');
}

can_ok(__PACKAGE__, 'cvCreateSubdivDelaunay2D');


# ============================================================
#  cvCalcSubdivVoronoi2D cvClearSubdivVoronoi2D
# ============================================================

if (1) {
	for (qw( cvCalcSubdivVoronoi2D cvClearSubdivVoronoi2D )) {
		package Cv::Subdiv2D;
		no strict 'refs';
		no warnings 'redefine';
		my $pass = 0;
		local *$_ = sub { $pass++ };
		(my $short1 = $_) =~ s/^cv//;
		(my $short2 = $_) =~ s/^cv|Subdiv|2D$//g;
		&$short1;
		&$short2;
		package Cv;
		&$short1;
		main::is($pass, 3, "alias of $_");
	}
}


# ============================================================
#  cvSubdiv2DEdgeOrg cvSubdiv2DEdgeDst cvSubdiv2DGetEdge
#  cvSubdiv2DNextEdge cvSubdiv2DRotateEdge
# ============================================================

if (1) {
	for (qw(cvSubdiv2DEdgeOrg cvSubdiv2DEdgeDst cvSubdiv2DGetEdge cvSubdiv2DNextEdge cvSubdiv2DRotateEdge)) {
		package Cv::Subdiv2D;
		no strict 'refs';
		no warnings 'redefine';
		my $pass = 0;
		local *$_ = sub { $pass++ };
		(my $short = $_) =~ s/^cv//;
		package Cv;
		&$short;
		main::is($pass, 1, "alias of $_");
	}
}
