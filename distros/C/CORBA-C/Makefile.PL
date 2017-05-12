use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::C',
    'VERSION_FROM'  => 'lib/CORBA/C.pm',
    'ABSTRACT'      => 'IDL compiler to C include file',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.60,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl2c' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

