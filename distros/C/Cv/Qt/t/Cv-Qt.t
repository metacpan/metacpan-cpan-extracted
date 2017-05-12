# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
use Test::Exception;
use Cv;

eval "use Cv::Qt qw(:all)";
plan skip_all => "Qt required" unless !$@ && cvHasQt();
# plan qw(no_pln);
plan tests => 47;

my $hasGUI = Cv->hasGUI;

if (Cv->GetBuildInformation) {
	like(cvHasQt(), qr/^QT \d\.\w+/);
} else {
	ok(cvHasQt());
}


# ============================================================
#  CvFont cvFontQt(
#     char* nameFont, int pointSize = -1, CvScalar color = cvScalarAll(0),
#     int weight = CV_FONT_NORMAL, int style = CV_STYLE_NORMAL,
#     int spacing = 0)
# ============================================================

can_ok('Cv', 'cvFontQt');
can_ok(__PACKAGE__, 'cvFontQt');

throws_ok { cvFontQt() }
qr/Usage: Cv::Qt::cvFontQt\(nameFont, pointSize= -1, color= cvScalarAll\(0\), weight= CV_FONT_NORMAL, style= CV_STYLE_NORMAL, spacing= 0\)/;

my $huge = cvFontQt('Helvetica', 20);
isa_ok($huge, 'Cv::Font');

my $bold = cvFontQt('Times', 10, cvScalarAll(0), eval "&CV_FONT_BOLD");
isa_ok($bold, 'Cv::Font');

my $normal = Cv->FontQt('Times', 10, cvScalarAll(0), eval "&CV_FONT_NORMAL");
isa_ok($normal, 'Cv::Font');


# ============================================================
#  void cvAddText(CvArr* img, char* text, CvPoint location, CvFont *font)
# ============================================================

can_ok('Cv::Arr', 'cvAddText');
can_ok('Cv', 'cvAddText');
can_ok(__PACKAGE__, 'cvAddText');

my $img = Cv->createImage([480, 240], 8, 3);
$img->fill(cvScalarAll(255));

SKIP: {
	skip "cvAddText() unless DISPLAY", 4 unless $hasGUI;

	Cv->namedWindow('Cv', CV_WINDOW_AUTOSIZE | CV_WINDOW_NORMAL);

	throws_ok { cvAddText() }
	qr/Usage: Cv::Qt::cvAddText\(img, text, location, font\)/;

	my $hi = "Hello, Qt";
	my $az = "The quick brown fox jumps over the lazy dog. 01234567890";

	lives_ok { cvAddText($img, $hi, [ 10, 80 ], $huge) };
	if ($normal) {
		lives_ok { cvAddText($img, $az, [ 10, 100 ], $normal) };
	}
	if ($bold) {
		lives_ok { $img->AddText($az, [ 10, 120 ], $bold) };
	}

	$img->show('Cv');
	Cv->waitKey(1000);
}

# ============================================================
#  void cvDisplayOverlay(const char* name, const char* text, int delay)
# ============================================================

can_ok('Cv', 'cvDisplayOverlay');
can_ok(__PACKAGE__, 'cvDisplayOverlay');

SKIP: {
	skip "cvDisplayOverlay() unless DISPLAY", 2 unless $hasGUI;

	throws_ok { cvDisplayOverlay() } qr/Usage: Cv::Qt::cvDisplayOverlay/;
	lives_ok { cvDisplayOverlay('Cv', 'Overlay', 1000) };

	$img->show('Cv');
	Cv->waitKey(1000);
}

# ============================================================
#  void cvDisplayStatusBar(const char* name, const char* text, int delayms)
# ============================================================

can_ok('Cv', 'cvDisplayStatusBar');
can_ok(__PACKAGE__, 'cvDisplayStatusBar');

SKIP: {
	skip "cvDisplayStatusBar() unless DISPLAY", 2 unless $hasGUI;

	throws_ok { cvDisplayStatusBar() } qr/Usage: Cv::Qt::cvDisplayStatusBar/;
	lives_ok { cvDisplayStatusBar('Cv', 'StatusBar', 1000) };

	$img->show('Cv');
	Cv->waitKey(1000);
}

# ============================================================
#  void cvGetWindowProperty(const char* name, int prop_id)
#  void cvSetWindowProperty(const char* name, int prop_id, double prop_value)
# ============================================================

can_ok('Cv', 'cvGetWindowProperty');
can_ok(__PACKAGE__, 'cvGetWindowProperty');

can_ok('Cv', 'cvSetWindowProperty');
can_ok(__PACKAGE__, 'cvSetWindowProperty');

SKIP: {
	skip "cv(Get|Set)WindowProperty() unless DISPLAY", 9 unless $hasGUI;

	throws_ok { cvGetWindowProperty() } qr/Usage: Cv::Qt::cvGetWindowProperty/;
	lives_ok { cvGetWindowProperty('Cv', CV_WND_PROP_FULLSCREEN) };

	my $auto;

	throws_ok { cvSetWindowProperty() } qr/Usage: Cv::Qt::cvSetWindowProperty/;
	lives_ok { cvSetWindowProperty('Cv', CV_WND_PROP_AUTOSIZE, 1) };
	lives_ok { $auto = cvGetWindowProperty('Cv', CV_WND_PROP_AUTOSIZE) };
	ok($auto, 'cvGetWindowProperty');

	$img->show('Cv');
	Cv->waitKey(1000);

	lives_ok { cvSetWindowProperty('Cv', CV_WND_PROP_AUTOSIZE, 0) };
	lives_ok { $auto = cvGetWindowProperty('Cv', CV_WND_PROP_AUTOSIZE) };
	ok(!$auto, 'cvGetWindowProperty');

	$img->show('Cv');
	Cv->waitKey(1000);
}

# ============================================================
#  void cvLoadWindowParameters(const char* name)
#  void cvSaveWindowParameters(const char* name)
# ============================================================

can_ok('Cv', 'cvLoadWindowParameters');
can_ok(__PACKAGE__, 'cvLoadWindowParameters');

can_ok('Cv', 'cvSaveWindowParameters');
can_ok(__PACKAGE__, 'cvSaveWindowParameters');

SKIP: {
	skip "cvLoad/SaveWindowParameters() unless DISPLAY", 4 unless $hasGUI;

	throws_ok { cvLoadWindowParameters() } qr/Usage: Cv::Qt::cvLoadWindowParameters/;
	lives_ok { cvLoadWindowParameters('Cv') };

	throws_ok { cvSaveWindowParameters() } qr/Usage: Cv::Qt::cvSaveWindowParameters/;
	lives_ok { cvSaveWindowParameters('Cv') };

	Cv->moveWindow('Cv', 100, 100);
	Cv->saveWindowParameters('Cv');

	my ($x, $y) = (0, 0);
	for (1 .. 10) {
		Cv->moveWindow('Cv', $x, $y);
		Cv->waitKey(100);
		$x += 10;
	}
	for (1 .. 10) {
		Cv->moveWindow('Cv', $x, $y);
		Cv->waitKey(100);
		$y += 10;
	}

	Cv->loadWindowParameters('Cv');

	$img->show;
	Cv->waitKey(1000);

}

# ============================================================
#  int cvCreateButton(
#    const char* button_name=NULL,
#    CvButtonCallback on_change = NULL,
#    VOID* userdata = NULL,
#    int button_type = CV_PUSH_BUTTON,
#    int initial_button_state = 0)
# ============================================================

can_ok('Cv', 'cvCreateButton');
can_ok(__PACKAGE__, 'cvCreateButton');

SKIP: {
	skip "cvCreateButton() unless DISPLAY", 2 unless $hasGUI;

	my $state;
	lives_ok { Cv->createButton(\0, sub { $state = shift }) };
	lives_ok { Cv->createButton("button", sub { $state = shift }) };

	$img->show;
	Cv->waitKey(1000);

}

# ============================================================
#  void cvCreateOpenGLCallback(
#    const char* window_name,
#    CvOpenGLCallback callbackOpenGL,
#    VOID* userdata = NULL,
#    double angle = -1,
#    double zmin = -1,
#    double zmax = -1)
# ============================================================
