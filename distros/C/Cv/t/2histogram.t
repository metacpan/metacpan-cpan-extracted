# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 31;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }
use File::Basename;
use List::Util qw(max min);

# my $img = Cv->LoadImage(dirname($0).'/'."baboon.jpg");
my $img = Cv->LoadImage(dirname($0).'/'."lena.jpg");
my $gray = $img->CvtColor(CV_RGB2GRAY);
my $dst = Cv->CreateImage([320, 240], 8, 3)->SetZero;

my $hist = Cv->CreateHist([256], CV_HIST_ARRAY);
ok($hist, 'Cv->CreateHist');

# ------------------------------------------------------------
#  CreateHist - Creates histogram
# ------------------------------------------------------------
if (1) {
	ok(Cv->CreateHist([256], CV_HIST_ARRAY),
	   'CreateHist(Cv->CreateHist)');
	throws_ok { Cv->CreateHist } qr/Usage: [^\(]*\(sizes, type, ranges=NULL, uniform=1\) at $0/, 'CvCreateHist(usage)';
}

# ------------------------------------------------------------
#  CalcHist - Calculates histogram of image(s)
# ------------------------------------------------------------
if (1) {
	$hist->CalcHist([$gray]);
	ok($hist, 'CalcHist');
	throws_ok { $hist->CalcHist } qr/Usage: Cv::Histogram::CalcHist\(hist, image, accumulate=0, mask=NULL\) at $0/, 'CalcHist(usage)';
}

# ------------------------------------------------------------
#  GetMinMaxHistValue - Finds minimum and maximum histogram bins
# ------------------------------------------------------------
if (1) {
	$hist->GetMinMaxHistValue(my $min_value, my $max_value);
	ok(defined $min_value, 'GetMinMaxHistValue min_value');
	ok(defined $max_value, 'GetMinMaxHistValue max_value');
}

# ------------------------------------------------------------
#  QueryHistValue_*D - Queries value of histogram bin
#  GetHistValue_*D - Returns pointer to histogram bin
# ------------------------------------------------------------
if (1) {
	sub rand_int { int rand $_[0]; }
	my ($w, $h) = (320, 240);
	my @bin_size = (256, 256, 256);
	my @planes = map { Cv->CreateImage([$w, $h], 8, 1) } (0..2);
	my @values = (rand_int(255), rand_int(255), rand_int(255)); 

	$planes[0]->Fill([ $values[0] ]);
	$planes[1]->Fill([ $values[1] ]);
	$planes[2]->Fill([ $values[2] ]);

	my $h1 = Cv->CreateHist([ $bin_size[0] ], CV_HIST_ARRAY)
		->CalcHist([ $planes[0] ]);
	isa_ok($h1, "Cv::Histogram");
	is($h1->QueryHistValue([ $values[0] ]), $w * $h, 'QueryHistValue(1D)');
	is(${$h1->GetHistValue([ $values[0] ])}[0], $w * $h, 'GetHistValue(1D)');

	my $h2 = Cv->CreateHist([ @bin_size[0 .. 1] ], CV_HIST_ARRAY)
		->CalcHist([ @planes[0 .. 1] ]);
	is($h2->QueryHistValue([ @values[0 .. 1] ]), $w * $h, 'QueryHistValue(2D)');
	is(${$h2->GetHistValue([ @values[0 .. 1] ])}[0], $w * $h, 'GetHistValue(2D)');

	my $h3 = Cv->CreateHist([ @bin_size[0 .. 2] ], CV_HIST_ARRAY)
		->CalcHist([ @planes[0 .. 2] ]);
	is($h3->QueryHistValue([ @values[0 .. 2] ]), $w * $h, 'QueryHistValue(3D)');
	is(${$h3->GetHistValue([ @values[0 .. 2] ])}[0], $w * $h, 'GetHistValue(3D)');
}

# ------------------------------------------------------------
#  CopyHist - Copies histogram
# ------------------------------------------------------------
if (1) {
	my $copy = $hist->CopyHist;
	isa_ok($copy, "Cv::Histogram");
	ok($copy->CalcHist([ $gray ]), 'CopyHist');
	$copy = $hist->Copy;
	isa_ok($copy, "Cv::Histogram");
}

# ------------------------------------------------------------
#  ThreshHist - Thresholds histogram
# ------------------------------------------------------------
if (1) {
	my $copy = $hist->CopyHist->CalcHist([ $gray ]);
	isa_ok($copy, "Cv::Histogram");
	ok($copy->ThreshHist(1), 'Thresh');
	ok($copy->Thresh(0.5), 'Thresh');
}

# ------------------------------------------------------------
#  NormalizeHist - Normalizes histogram
# ------------------------------------------------------------
if (1) {
	my $copy = $hist->CopyHist->CalcHist([ $gray ]);
	isa_ok($copy, "Cv::Histogram");
	ok($copy->NormalizeHist(1), 'Normalize');
	ok($copy->Normalize(0.5), 'Normalize');
}

# ------------------------------------------------------------
#  CompareHist - Compares two dense histograms
# ------------------------------------------------------------
if (1) {
	my $copy1 = $hist->CopyHist->CalcHist([ $gray ]);
	isa_ok($copy1, "Cv::Histogram");
	my $copy2 = $hist->CopyHist->CalcHist([ $gray->PyrDown ]);
	isa_ok($copy2, "Cv::Histogram");
	my $d = $copy1->CompareHist($copy2, CV_COMP_CORREL);
	ok($d, 'CompareHist');
	ok($copy1->Compare($copy2, CV_COMP_CORREL), 'Compare');
}

# ------------------------------------------------------------
#  ClearHist - Clears histogram
# ------------------------------------------------------------
if (1) {
	my $copy = $hist->CopyHist->CalcHist([ $gray ]);
	my $b = $copy->QueryHistValue([ 100 ]);
	$copy->ClearHist;
	my $a = $copy->QueryHistValue([ 100 ]);
	ok($b > 0 && $a == 0, 'ClearHist');
	$copy->CalcHist([ $gray ]);
	$b = $copy->QueryHistValue([ 100 ]);
	$copy->Clear;
	$a = $copy->QueryHistValue([ 100 ]);
	ok($b > 0 && $a == 0, 'Clear');
}

# ------------------------------------------------------------
#  CalcBackProject - Calculates back projection
# ------------------------------------------------------------
if (1) {
	my $copy = $hist->CopyHist->CalcHist([ $gray ]);
	my $backproject = $copy->CalcBackProject([ $gray ], $gray->new);
	isa_ok($backproject, "Cv::Image");
}

my ($width, $height) = (256, 100);
my $zero = Cv->CreateImage([$width, $height], 8, 1)->Zero;
my @himages;
foreach ($img->Split) {
	my $hist = Cv->CreateHist([256], CV_HIST_ARRAY)->Calc([$_]);
	$hist->GetMinMaxHistValue(my $min, my $max);
	$hist->bins->ConvertScale($hist->bins, $height / $max) if $max;
	my $himage = $zero->Clone;
	for my $i (0 .. 255) {
		my ($x, $y) = ($i * $width / 256, $height);
		my $pt1 = [$x, $y];
		my $pt2 = [$x + $width / 256, $y - $hist->QueryHistValue([$i])];
		$himage->Rectangle($pt1, $pt2, [$i]);
	}
	push(@himages, $himage);
}

my $histogram = Cv->CreateImage([$width, 3*$height], 8, 3);
my $blue  = [ 0, 0*$height, $width, $height ];
my $green = [ 0, 1*$height, $width, $height ];
my $red   = [ 0, 2*$height, $width, $height ];
Cv->Merge([$himages[0], $zero, $zero], $histogram->SetImageROI($blue));
Cv->Merge([$zero, $himages[1], $zero], $histogram->SetImageROI($green));
Cv->Merge([$zero, $zero, $himages[2]], $histogram->SetImageROI($red));
$histogram->ResetImageROI;
my $haswin = Cv->hasGUI;
if ($haswin) {
	$img->ShowImage('Image');
	$histogram->ShowImage('Histogram');
	Cv->WaitKey(1000);
}
