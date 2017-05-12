# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 1;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

my ($cx, $cy) = (100, 100);
my $src = Cv->CreateImage([320, 240], 8, 3)->Zero;
my $fn = Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 0.4, 0.4, 0, 1, CV_AA);

$src->Rectangle([$cx-50, $cy-50], [$cx+50, $cy+50], [ 255, 255, 255 ], -1);

# linear
my $sz = $src->GetSize;
my $pi = atan2(1, 1)*4;
foreach my $i (0..10) {
	my $angle = $i/10 * $pi;
	my $affine = $src->Affine([ [ 1, 0, $cx+$i*5 ],
								[ 0, 1, $cy+$i*5 ], ]);
	&print_moment($affine);
	if ($verbose) {
		$affine->ShowImage;
		Cv->WaitKey(50);
	}
}

# rotate
foreach my $i (0..10) {
	my $angle = $i/10 * $pi;
	my $affine = $src->Affine( [ [ +cos($angle), -sin($angle), $cx ],
								 [ +sin($angle), +cos($angle), $cy ], ]);
	&print_moment($affine);
	if ($verbose) {
		$affine->ShowImage;
		Cv->WaitKey(50);
	}
}


# scaling
foreach my $i (0..10) {
	my $affine = $src->Affine( [ [ ($i+1), 0, $cx ],
								 [ 0, ($i+1), $cy ], ]);
	&print_moment($affine);
	if ($verbose) {
		$affine->ShowImage;
		Cv->WaitKey(50);
	}
}


sub print_moment {
	my $img = shift;
	my $m = $img->Moments(1);
	my $spatial = $m->GetSpatialMoment(0, 0);
	my $central = $m->GetCentralMoment(0, 0);
	my $norm = $m->GetNormalizedCentralMoment(0, 0);

	my $hu = $m->GetHuMoments;
	my $hu1 = $hu->hu1;
	my $hu2 = $hu->hu2;
	my $hu3 = $hu->hu3;
	my $hu4 = $hu->hu4;
	my $hu5 = $hu->hu5;
	my $hu6 = $hu->hu6;
	my $hu7 = $hu->hu7;

	my $m00 = $m->m00;
	my $m10 = $m->m10;
	my $m01 = $m->m01;
	my $m20 = $m->m20;
	my $m11 = $m->m11;
	my $m02 = $m->m02;
	my $m30 = $m->m30;
	my $m21 = $m->m21;
	my $m12 = $m->m12;
	my $m03 = $m->m03;
	my $inv_sqrt_m00 = $m->inv_sqrt_m00;

	my ($gx, $gy) = ($m10 / $m00, $m01 / $m00);

	my ($x, $y, $d) = (20, 20, 13);

	foreach (
		"spatial: $spatial", "central: $central", "norm: $norm",
		"hu1: $hu1", "hu2: $hu2", "hu3: $hu3", "hu4: $hu4",
		"hu5: $hu5", "hu6: $hu6", "hu7: $hu7", "gxy: ($gx, $gy)",
		) {
		$img->PutText($_, [$x, $y], $fn, [ 0, 0, 255]);
		$y += $d;
	}
}
