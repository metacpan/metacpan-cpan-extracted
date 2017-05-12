use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::Perl',
    'VERSION_FROM'  => 'lib/CORBA/Perl.pm',
    'ABSTRACT'      => 'IDL compiler to Perl mapping',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.60,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl2pm', 'bin/idl2pmrpc' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
