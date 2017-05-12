use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Session::Serialize::Dumper',
    'VERSION_FROM'	=> 'Dumper.pm',
    'PREREQ_PM'		=> { Apache::Session=>1.54, Data::Dumper=>2.101 },
);
