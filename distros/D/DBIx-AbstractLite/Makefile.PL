use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	        => 'DBIx::AbstractLite',
    'VERSION_FROM'      => 'AbstractLite.pm', # finds $VERSION
    'ABSTRACT_FROM'     => 'AbstractLite.pm',
    'PREREQ_PM'         => { 'CGI::LogCarp' => 0, 'Error::Dumb' => 0, 'DBI' => 0 },
);
