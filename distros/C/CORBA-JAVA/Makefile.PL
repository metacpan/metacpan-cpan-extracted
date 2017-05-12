use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::JAVA',
    'VERSION_FROM'  => 'lib/CORBA/JAVA.pm',
    'ABSTRACT'      => 'IDL compiler to JAVA (idlj clone)',
    'PREREQ_PM'     => {
                        'CORBA::IDL'            => 2.61,
                        'CORBA::XMLSchemas'     => 2.60,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl2java', 'bin/idl2javaxml' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
                        'TARFLAGS'      => '--create --verbose --mode=0700 --file',
    },
);
