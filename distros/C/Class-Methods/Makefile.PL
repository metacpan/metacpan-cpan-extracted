use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Methods',
    'VERSION_FROM'	=> 'lib/Class/Methods.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'warnings'          => 0,
        'Devel::Pointer'    => 0,
    },
);
