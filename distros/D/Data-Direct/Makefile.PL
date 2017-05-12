use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Data::Direct',
    'VERSION_FROM' => 'Direct.pm', # finds $VERSION
    'PREREQ_PM' => {'DBI' => '1.10'},
);
