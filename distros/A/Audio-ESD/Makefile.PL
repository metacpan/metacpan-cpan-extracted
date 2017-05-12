use ExtUtils::MakeMaker;
use Getopt::Long;

my $esdconfig;
GetOptions("esd-config=s" => \$esdconfig);
$esdconfig ||= "esd-config";

my ($esdlibs, $esdflags);
unless(defined($esdlibs = `$esdconfig --libs`)) {
    die <<"EOE";
Unable to run the 'esd-config' program to get compilation flags.
Make sure that you have esound installed, and that esd-config is
in your \$PATH.  You can also specify an alternate esd-config to
use with the --esd-config option, like this:

  perl Makefile.PL --esd-config=/path/to/somewhere/esd-config
EOE
}
$esdflags = `$esdconfig --cflags`;
chomp($esdlibs, $esdflags);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Audio::ESD',
    'VERSION_FROM' => 'ESD.pm', # finds $VERSION
    'LIBS'	=> [$esdlibs],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $esdflags,     # e.g., '-I/usr/include/other' 
);
