use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'DBD::Log',
    VERSION_FROM => 'lib/DBD/Log.pm', # finds $VERSION
    AUTHOR       => 'Hartog C. de Mik <hartog@2organize.com>',
    ABSTRACT     => 'Logging for the DBI interface',
    PREREQ_PM    => { 'DBD::Mock'            => 1,
                      'Class::AccessorMaker' => 1,
		      'DBI'                  => 1,
		      'IO::File'             => 1,
		    },
);
