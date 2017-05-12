#
# $Id: Makefile.PL, v0.52
#
#
use 5.004;
use ExtUtils::MakeMaker;
use Config;
use strict;
use DBI 0.89;
use DBI::DBD;

# Proprietary Empress Object Libraries (supplied in lib sub-directory)
print "Using Empress Local Interface\n";
# For SCO, it should be:
# my $LIBS = "-L./lib -ldse -lms -lc";
# Otherwise:
# my $LIBS = "-L./lib -ldse -lms";

my $LIBS = "-L./lib -ldse -lms";
$LIBS = "-L./lib -ldse -lms -lc" if $Config{osname} eq 'sco_sv';

# --- Compiler Define's.
my $DEFINE = '';

# Gnu CC
$DEFINE .= '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
            . ' -Wconversion -Wtraditional -Wpointer-arith'
            . ' -Wbad-function-cast -Wcast-qual'
        if $Config{cc} eq 'gcc';

# Centerline CC
$DEFINE .= ' -Xa' if $Config{cc} eq 'clcc';

# --- Objects.
my $OBJECT = 'Empress.o dbdimp.o';

# --- Include Files
my $INC="-I\$(INSTALLSITEARCH)/auto/DBI -I\$(INSTALLSITEARCH)/DBI"; 

my %opts = (
    'NAME'	=> 'DBD::Empress',
    'VERSION_FROM'	=> 'Empress.pm',
    clean	=> {FILES=> 'Empress.xsi'},
    dist	=> { 
		DIST_DEFAULT=>'clean distcheck disttest ci tardist',
		PREOP	=> '$(MAKE) -f Makefile.old distdir',
		COMPRESS => 'gzip', SUFFIX => 'gz'
	},
    'INC'	=> $INC,
    'LIBS'	=> $LIBS,
    'OBJECT'	=> $OBJECT,
    'DEFINE'	=> $DEFINE,
    'PM'        => { "Empress.pm" => "\$(INST_LIBDIR)/Empress.pm" },
);

WriteMakefile(%opts);

exit (0);

sub MY::postamble {
	return dbd_postamble ();
}

#End of Makefile.PL

