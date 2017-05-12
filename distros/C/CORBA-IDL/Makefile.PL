use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::IDL',
    'VERSION_FROM'  => 'lib/CORBA/IDL.pm',
    'ABSTRACT'      => 'CORBA-IDL 3.0 parser',
    'PREREQ_PM'     => {
                        'Digest::SHA1'  => 0,
                        'Math::BigInt'  => 1.66,
                        'Parse::Yapp'   => 0,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

