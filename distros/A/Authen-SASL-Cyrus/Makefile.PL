use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Authen::SASL::Cyrus',
    'VERSION_FROM' => 'Cyrus.pm',
    'LIBS'         => ['-lsasl2'],
    'DEFINE'       => '-DSASL2 -g',
    'PREREQ_PM'    => { Authen::SASL => 0 },
    'INC'          => '-I/usr/local/include/sasl',
);
