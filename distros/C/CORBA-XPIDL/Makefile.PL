use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::XPIDL',
    'VERSION_FROM'  => 'lib/CORBA/XPIDL.pm',
    'ABSTRACT'      => 'XPIDL compiler (for Mozilla)',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.61,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/xpidl', 'bin/xpt_dump', 'bin/xpt_link' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

