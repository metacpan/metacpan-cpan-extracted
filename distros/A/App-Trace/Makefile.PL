
######################################################################
## File: $Id: Makefile.PL 3400 2005-01-07 13:03:36Z spadkins $
######################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%opts = (
    'NAME'         => 'App-Trace',
    'DISTNAME'     => 'App-Trace',
    'VERSION_FROM' => 'lib/App/Trace.pm',
    'PREREQ_PM'    => {
        "App::Options"   => "0.01",  # used for setting trace options
    },
    'dist'         => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                       'ZIP'=>'/usr/bin/zip', 'ZIPFLAGS'=>'-rl'},
);

WriteMakefile(%opts);

