use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Config;

# On some versions of Solaris, under some circumstances, 
# can get the wrong version of md5 unless we do this:
# Will also get lots of complaints about undefined symbols
if ($Config{osname} eq 'solaris') {
#        $ex_cc_flags='-symbolic';
}

WriteMakefile(
    'NAME'	=> 'Authen::TacacsPlus',
    'VERSION_FROM' => 'TacacsPlus.pm', # finds $VERSION
    'MYEXTLIB'  => "$ex_cc_flags tacpluslib/libtacplus\$(LIB_EXT)",
    'dist'                  => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
sub MY::postamble {         
'                           
$(MYEXTLIB): tacpluslib/Makefile 
	cd tacpluslib && $(MAKE) -e
';                          
}                           
