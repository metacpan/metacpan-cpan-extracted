use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use strict;

my @xrt3d = "undef"; 
my $xrt3d; 
my @xrt2d = "undef"; 
my $xrt2d ;
my @xvfb = "undef";
my $xvfb;
my @drivers = qw(gnuplot xrt3d xrt2d xmgrace);
print "Enter (space separated) graphing drivers to test: [@drivers] ";
my $drivers = <STDIN>;
chomp $drivers;
@drivers = split /\s/,$drivers if $drivers ne '';

for (@drivers) {
    if (not defined $xvfb and ($_ eq "xrt2d" or $_ eq "xrt3d" or $_ eq "xmgrace")) {
        print "Enter path to X virtual frame buffer(Xvfb): "; 
        $xvfb = <STDIN>; 
        chop $xvfb; 
        @xvfb = $xvfb; 
    }
    if($_ eq "xrt3d") {
        print "Enter path to xrt3d binary (built from xrt3d/): ";
        $xrt3d = <STDIN>;
	chop $xrt3d;
	@xrt3d = $xrt3d;
    }
    if($_ eq "xrt2d") {
        print "Enter path to xrt2d binary (built from xrt2d/): ";
        $xrt2d = <STDIN>;
	chop $xrt2d;
	@xrt2d = $xrt2d;
    }
}	

my $config = 't/Config.pm';
open(CONFIG,">$config") || die "Couldn't open config file: $config: $!";
print STDERR "Writing config file: $config\n";
print CONFIG qq{
package t::Config;
\@drivers    = qw(@drivers);
\$xrt3d      = "@xrt3d";
\$xrt2d      = "@xrt2d";
\$xvfb      = "@xvfb";

1;
};

close CONFIG;

### add extra target(s) to makefile
sub MY::postamble {
             return <<'MAKE_DOC';
docs: Graph.pm
	pod2html --infile=Graph.pm --outfile=Graph.html --title='Chart::Graph' \
	&& pod2html --infile=Graph/Gnuplot.pm --outfile=doc/graph_gnuplot.html --title='Chart::Graph::Gnuplot' \
	&& pod2html --infile=Graph/Xmgrace.pm --outfile=doc/graph_xmgrace.html --title='Chart::Graph::Xmgrace' \
	&& pod2html --infile=Graph/Xrt2d.pm   --outfile=doc/graph_xrt2d.html   --title='Chart::Graph::Xrt2d' \
	&& pod2html --infile=Graph/Xrt3d.pm   --outfile=doc/graph_xrt3d.html   --title='Chart::Graph::Xrt3d' \
MAKE_DOC
}


WriteMakefile(
	      'NAME'      => 'Chart::Graph',
	      'VERSION_FROM' => 'Graph.pm', # finds $VERSION
	      dist => {
		       TARFLAGS => 'cvf',
		       COMPRESS => 'gzip',
		       SUFFIX => 'gz',
		      }
	     );

# Assist users in completing install and more importantly, telling them
# where the test files end up.
print STDERR "To complete installation, type the following:\n\n\tmake\n",
    "\tmake test\n\tmake install\n\n",
    "The test graphs can be found in the 'test_results' directory\n";
