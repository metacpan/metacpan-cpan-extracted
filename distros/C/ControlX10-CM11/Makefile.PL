use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless ($^O eq "MSWin32") {
    WriteMakefile(
        'NAME'	=> 'ControlX10::CM11',
        'VERSION_FROM' => 'CM11.pm', # finds $VERSION
        'SKIP'	=> [qw(tool_autosplit)],
    );
    exit;
}

# On Windows, create substitute scripts for the "make deprived"

require 5.005;

use File::Copy;
use File::Path;
use Pod::Html;

my $version = simple_version("CM11.pm");
my $INST_LIBDIR = "./lib/ControlX10";
my $INST_HTMLDIR = "./html/ControlX10";
my $INST_FILES = "CM11.pm";
my $INST_NAME = "ControlX10/CM11";
my @HTML_FILES = "CM11";

print <<INTRO;
                      ControlX10::CM11 VERSION $version
                      No 'Makefile' will be created
                      Test with:    perl test.pl
                      Install with: perl install.pl

   The Test sends data to the emulator, does not require a CM11 attached

INTRO

my $dfile = "test.pl";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<"TEST4";	# double quotes - need interpolation
# Created by Makefile.PL
# $INST_NAME Version $version
TEST4

print DEFAULT <<'TEST4';	# single quotes - minimize chaacter quoting
use Test::Harness;
runtests ("t/test1.t");

print "\nTo run individual tests, type:\n";
print "    C:\\> perl t/test1.t Page_Pause_Time (0..5)\n";
print "See README and other documentation for additional information.\n\n";
TEST4

close DEFAULT;

unless (-d $INST_LIBDIR) {
    File::Path::mkpath([ "$INST_LIBDIR" ],1,0777) or
        die "ERROR creating directories: ($!)\n";
}
unless (-d $INST_HTMLDIR) {
    File::Path::mkpath([ "$INST_HTMLDIR" ],1,0777) or
        die "ERROR creating directories: ($!)\n";
}
File::Copy::copy($INST_FILES,$INST_LIBDIR) or
    die "ERROR copying files: ($!)\n";

foreach $source (@HTML_FILES) {
    pod2html(
	     "--norecurse",
	     "--infile=$source.pm",
	     "--outfile=$INST_HTMLDIR/$source.html"
	    );
}

$dfile = "install.pl";
unlink $dfile, "pod2html-itemcache","pod2html-dircache";
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<"INST5";
# Created by Makefile.PL
# $INST_NAME Version $version
INST5

my $template = <<'INST5';

BEGIN { require 5.005; }

use Config qw(%Config);
use strict;
use ExtUtils::Install qw( install );

my $FULLEXT = "%s";	# $INST_NAME
my $INST_LIB = "./lib";
my $HTML_LIB = "./html";

my $html_dest = "";	# edit real html base here if autodetect fails

if (exists $Config{installhtmldir} ) {
    $html_dest = "$Config{installhtmldir}";
}
elsif (exists $Config{installprivlib} ) {
    $html_dest = "$Config{installprivlib}";
    $html_dest =~ s%\\lib%\\html%;
}

if ( length ($html_dest) ) {
    $html_dest .= '\lib\site';
}
else {
    die "Can't find html base directory. Edit install.pl manually.\n";
}

install({
	   read => "$Config{sitearchexp}/auto/$FULLEXT/.packlist",
	   write => "$Config{installsitearch}/auto/$FULLEXT/.packlist",
	   $INST_LIB => "$Config{installsitelib}",
	   $HTML_LIB => "$html_dest"
	  },1,0);

__END__
INST5

printf DEFAULT $template, $INST_NAME;
close DEFAULT;

    # a low-fat version of parse_version from ExtUtils::MM_Unix.
sub simple_version {
    my $parsefile = shift;
    my $result;
    open(FH,$parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    while (<FH>) {
	$inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
	next if $inpod;
	chop;
	next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
	my $eval = qq{
	    package ExtUtils::MakeMaker::_version;
	    no strict;

	    local $1$2;
	    \$$2=undef; do {
		$_
	    }; \$$2
	};
	local($^W) = 0;
	$result = eval($eval);
	die "Could not eval '$eval' in $parsefile: $@" if $@;
	$result = "undef" unless defined $result;
	last;
    }
    close FH;
    return $result;
}
