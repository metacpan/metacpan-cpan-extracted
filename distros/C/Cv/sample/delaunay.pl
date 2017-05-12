#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv -subdiv;

{
	package Cv::SeqReader::Edge;
	our @ISA = qw(Cv::SeqReader);
	sub ptr { ${ $_[0]->SUPER::ptr } }
}

# the script demostrates iterative construction of delaunay
# triangulation and voronoi tesselation

sub draw_subdiv_point {
	my ($img, $fp, $color) = @_;
	$img->Circle($fp, 3, $color, CV_FILLED, 8, 0);
}

sub draw_subdiv_edge {
	my ($img, $edge, $color) = @_;
	my $org_pt = Cv->Subdiv2DEdgeOrg($edge);
	my $dst_pt = Cv->Subdiv2DEdgeDst($edge);
	if ($org_pt && $dst_pt) {
		my $org = cvPoint(map { cvRound($_) } @{$org_pt->[2]});
		my $dst = cvPoint(map { cvRound($_) } @{$dst_pt->[2]});
		$img->Line($org, $dst, $color, 1, CV_AA, 0);
	}
}

sub draw_subdiv {
	my ($img, $subdiv, $delaunay_color, $voronoi_color) = @_;
	my $total = $subdiv->edges->total;
	$subdiv->edges->StartReadSeq(my $reader);
	bless $reader, 'Cv::SeqReader::Edge';
	for (1 .. $total) {
		my $edge = $reader->ptr;
		if (CV_IS_SET_ELEM($edge)) {
			draw_subdiv_edge($img, $edge + 1, $voronoi_color);
			draw_subdiv_edge($img, $edge, $delaunay_color);
		}
        $reader->NextSeqElem;
    }
}

sub locate_point {
	my ($subdiv, $fp, $img, $active_color) = @_;
	$subdiv->Locate($fp, my $e0, my $p);
	if ($e0) {
		my $e = $e0;
		do {
			draw_subdiv_edge($img, $e, $active_color);
			$e = Cv->Subdiv2DGetEdge($e, CV_NEXT_AROUND_LEFT);
		} while ($e != $e0);
	}
	draw_subdiv_point($img, $fp, $active_color);
}

sub draw_subdiv_facet {
	my ($img, $edge) = @_;
	my $t = $edge;
	my $i; my $count = 0;

    # count number of edges in facet
	do {
		$count++;
		$t = Cv->Subdiv2DGetEdge($t, CV_NEXT_AROUND_LEFT);
	} while ($t != $edge);

	my @buf = ();

	# gather points
	$t = $edge;
	for ($i = 0; $i < $count; $i++) {
		my $pt = Cv->Subdiv2DEdgeOrg($t);
		last unless $pt;
		push(@buf, cvPoint(map { cvRound($_) } @{$pt->[2]}));
		$t = Cv->Subdiv2DGetEdge($t, CV_NEXT_AROUND_LEFT);
	}
	
	if ($i == $count) {
		my $random_color = CV_RGB(rand(255), rand(255), rand(255));
		$img->FillConvexPoly(\@buf, $random_color, CV_AA, 0);
		$img->PolyLine([ \@buf ], 1, CV_RGB(0, 0, 0), 1, CV_AA, 0);
		my $pt = Cv->Subdiv2DEdgeDst(Cv->Subdiv2DRotateEdge($edge, 1));
		draw_subdiv_point($img, [@{$pt->[2]}], &CV_RGB(0, 0, 0));
	}
}

sub paint_voronoi {
	my ($subdiv, $img) = @_;
    my $total = $subdiv->edges->total;
    $subdiv->CalcVoronoi;
	$subdiv->edges->StartReadSeq(my $reader, 0);
	bless $reader, 'Cv::SeqReader::Edge';
	for (1 .. $total) {
		my $edge = $reader->ptr;
        if (CV_IS_SET_ELEM($edge)) {
            draw_subdiv_facet($img, Cv->Subdiv2DRotateEdge($edge, 1)); # left
            draw_subdiv_facet($img, Cv->Subdiv2DRotateEdge($edge, 3)); # right
		}
        $reader->NextSeqElem;
    }
}

sub run {
	my $win = "source";
    my $rect = cvRect(0, 0, 600, 600);

    my $active_facet_color = CV_RGB(255,   0,   0);
    my $delaunay_color     = CV_RGB(  0,   0,   0);
    my $voronoi_color      = CV_RGB(  0, 180,   0);
    my $bkgnd_color        = CV_RGB(255, 255, 255);

    my $img = Cv::Image->new([600, 600], CV_8UC3)->fill($bkgnd_color);
	Cv->NamedWindow($win, 1);

	my $storage = Cv::MemStorage->new(0);
    my $subdiv = Cv::Subdiv2D->createDelaunay([0, 0, 600, 600], $storage);

    print
		"Delaunay triangulation will be build now interactively.\n",
		"To stop the process, press any key\n\n";

    for (1 .. 200) {
        my $fp = cvPoint2D32f(
			map { rand($_ - 10) + 5 } ($img->width, $img->height)
			);

        locate_point($subdiv, $fp, $img, $active_facet_color);

        $img->ShowImage($win);
        last if (Cv->WaitKey(100) >= 0);

        $subdiv->DelaunayInsert($fp);
        $subdiv->CalcVoronoi;
		$img->fill($bkgnd_color);
        draw_subdiv($img, $subdiv, $delaunay_color, $voronoi_color);
        $img->ShowImage($win);
        last if (Cv->WaitKey(100) >= 0);
    }

	$img->fill($bkgnd_color);
    paint_voronoi($subdiv, $img);
    $img->ShowImage($win);
    Cv->WaitKey(0);
}

&run;
exit 0;
