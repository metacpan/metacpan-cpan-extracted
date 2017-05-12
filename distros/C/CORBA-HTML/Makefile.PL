use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::HTML',
    'VERSION_FROM'  => 'lib/CORBA/HTML.pm',
    'ABSTRACT'      => 'HTML generator from IDL file',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.60,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl2html' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

