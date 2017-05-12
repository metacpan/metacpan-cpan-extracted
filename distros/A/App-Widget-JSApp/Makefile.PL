
######################################################################
## File: $Id: Makefile.PL 6707 2006-07-25 02:21:19Z spadkins $
######################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%opts = (
    'NAME'        => 'App-Widget-JSApp',
    'DISTNAME'    => 'App-Widget-JSApp',
    'VERSION'     => '0.60',
    'PREREQ_PM'   => {
                       'App::Widget'              => 0,
                     },
    'dist'        => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                      'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
);

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::postamble {
    return <<EOF;

install ::
	@\$(MOD_INSTALL) htdocs  "\$(PREFIX)/htdocs/App"

EOF
}

