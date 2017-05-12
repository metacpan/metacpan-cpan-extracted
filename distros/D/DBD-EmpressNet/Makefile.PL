#
# $Id: Makefile.PL, v0.51
#
#
use 5.004;
use ExtUtils::MakeMaker;
use Config;
#use strict;
use DBI 0.87;
use DBI::DBD;

# Proprietary EmpressNet Object Libraries (supplied in lib sub-directory)
print "Using EmpressNet ODBC Interface\n";
my $LIBS = "-L./lib -lsse";

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
my $OBJECT = 'EmpressNet.o dbdimp.o';

# --- Include Files
my $INC="-I\$(INSTALLSITEARCH)/auto/DBI -I\$(INSTALLSITEARCH)/DBI"; 

my %opts = (
    'NAME'	=> 'DBD::EmpressNet',
    'VERSION_FROM'	=> 'EmpressNet.pm',
    clean	=> {FILES=> 'EmpressNet.xsi'},
    dist	=> { 
		DIST_DEFAULT=>'clean distcheck disttest ci tardist',
		PREOP	=> '$(MAKE) -f Makefile.old distdir',
		COMPRESS => 'gzip', SUFFIX => 'gz'
	},
    'INC'	=> $INC,
    'LIBS'	=> $LIBS,
    'OBJECT'	=> $OBJECT,
    'DEFINE'	=> $DEFINE,
    'PM'        => { "EmpressNet.pm" => "\$(INST_LIBDIR)/EmpressNet.pm" },
);

WriteMakefile(%opts);

exit (0);

sub MY::postamble {
	return dbd_postamble ();
}

#End of Makefile.PL

