use 5.008003;
use ExtUtils::MakeMaker;
use File::Copy;
use File::Spec;
use Config;

my $g_use_bundled_cscan;

BEGIN {
    # Initialize global variables
    $g_use_bundled_cscan = 0;

    eval 'require ModPerl::CScan';

    if ($@) {
        print STDERR "ModPerl::CScan not installed, using bundled copy.\n";
        $g_use_bundled_cscan = 1;
    } elsif ($ModPerl::CScan::VERSION < 0.75) {
        print STDERR "ModPerl::CScan too old ($ModPerl::CScan::VERSION < 0.75),  using bundled copy.\n";
        $g_use_bundled_cscan = 1;
    }


    my $libmodp_dir = File::Spec->catfile('lib', 'ModPerl');
    if ($g_use_bundled_cscan) {
        if ( ! -d $libmodp_dir ) {
            mkdir($libmodp_dir) or
                die "Could not create $libmodp_dir to relocate bundled CScan.pm: $!"
        }
        copy(File::Spec->catfile('contrib',$libmodp_dir,'CScan.pm'),
	     File::Spec->catfile($libmodp_dir,'CScan.pm')) or
            die "Could not copy bundled ModPerl::CScan to lib directory: $!";
    }
}

# Bail out now if we can't find gcc in the build config.  Note that this
# may not be enough to assure later use of the C preprocessor will
# actually be successful, so we should also probably test gcc now for
# completeness.
if ($^O =~ /mswin/i) {
    if ($Config{cc} !~ /gcc/i) {
        my $warn_msg = <<END_WARN_MSG;

On Windows platforms we require gcc to assure proper C preprocessor behavior.
Please assure that MinGW, gcc, or similar package is installed.
END_WARN_MSG
        warn $warn_msg;
	exit 0;
    }
}

# Create platform-independent versions of needed paths.
my $main_module = File::Spec->catfile( qw/lib C Scan Constants.pm/ );
my @tests;
opendir(my $test_dh, "t") or die "Could not open test directory: $!";
while (my $test = readdir $test_dh) {
    next unless $test =~ /[.]t$/;
    push @tests, File::Spec->catfile( 't', $test );
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %parms = (
    NAME              => 'C::Scan::Constants',
    VERSION_FROM      => $main_module, # finds $VERSION
    PREREQ_PM         => { 'Data::Flow'          => 0,
                           'File::Temp'          => 0,
                           'File::Copy'          => 0,
                           'File::Path'          => 0,
                           'Scalar::Util'        => 0,
                           'List::MoreUtils'     => 0 },
    LICENSE           => 'perl',    # LICENSE supported since E::M 6.31
    ABSTRACT          => 'Slurp constants from specified C header files',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Philip Monsen <philip.monsen@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I.", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    test              => {TESTS => join(" ", @tests)},
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=C-Scan-Constants',
            repository => 'git://github.com/icerider70/c-scan-constants.git',
        },
    };
}

WriteMakefile( %parms );

# clean up appropriately on "make clean"
sub MY::postamble {
	if ($g_use_bundled_cscan and $^O =~ /mswin/i) {
	'
clean :: myclean
myclean:
	del /f/q Makefile.old
	del /f/q const-c.inc const-xs.inc
	del /f/q tmp*
	rmdir /s/q lib\ModPerl
	del /f/q *.gz
	del /f/q *_CPANTS.txt
';
	} elsif ($g_use_bundled_cscan) {
	'
clean :: myclean
myclean:
	$(RM) Makefile.old
	$(RM) const-c.inc const-xs.inc
	$(RM) tmp*
	$(RM) -r lib/ModPerl
	$(RM) *.gz
	$(RM) *_CPANTS.txt
';
	} else {
'
clean :: myclean
myclean:
	$(RM) Makefile.old
	$(RM) const-c.inc const-xs.inc
	$(RM) tmp*
	$(RM) *.gz
	$(RM) *_CPANTS.txt
';
	}
}
