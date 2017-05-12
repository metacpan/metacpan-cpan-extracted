use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::XMLSchemas',
    'VERSION_FROM'  => 'lib/CORBA/XMLSchemas.pm',
    'ABSTRACT'      => 'IDL compiler to WSDL/SOAP and W3C Schema',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.60,
                        'XML::DOM'      => 0,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl2xsd', 'bin/idl2wsdl', 'bin/idl2soap', 'bin/idl2rng' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

