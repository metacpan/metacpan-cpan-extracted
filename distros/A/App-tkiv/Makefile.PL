use strict;
use warnings;

require 5.010;

use ExtUtils::MakeMaker;

my @exe = ("iv");

my %prereq_pm = (
    "Getopt::Long"	=> 2.27,
    "File::Copy"	=>    0,
    "File::Temp"	=>    0,

    "Tk"		=>  804.027,
    "Tk::JPEG"		=>    0,
    "Tk::PNG"		=>    0,
    "Tk::Bitmap"	=>    0,
    "Tk::Pixmap"	=>    0,
    "Tk::Photo"		=>    0,
    "Tk::Pane"		=>    0,
    "Tk::DirTree"	=>    0,
    "Tk::Dialog"	=>    0,
    "Tk::Balloon"	=>    0,
    "Tk::BrowseEntry"	=>    0,
    "Tk::Animation"	=>    0,
    "Image::ExifTool"	=>    0,
    );
unless ($^O eq "MSWin32") {
    $prereq_pm{"Tk::TIFF"}	= 0; # Only works with Tk-804.027_500 and up
#   $prereq_pm{"X11::Protocol"}	= 0; # Optional if $mw->screenwidth works reliable
    }

do {	local *STDERR;
	open STDERR, ">", \my $err;
	`convert --version` || "";
	} =~ m/ImageMagick/i or
    die "App::tkiv requires ImageMagick's 'convert' to be available\n";

my %wm = (
    NAME         => "App::tkiv",
    DISTNAME     => "App-tkiv",
    ABSTRACT     => "Image Viewer in Perl/Tk based on IrfanView",
    AUTHOR       => "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM => "iv.pod",
    EXE_FILES    => [ @exe ],
    PREREQ_FATAL => 0,
    PREREQ_PM    => \%prereq_pm,
    macro        => { TARFLAGS => "--format=ustar -c -v -f", },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

package MY;

sub postamble
{
    my $min_vsn = ($] >= 5.010 && -d "xt" && -d "tmp" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'spellcheck:',
	'	pod-spell-check --aspell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	$min_vsn;
    } # postamble

1;
