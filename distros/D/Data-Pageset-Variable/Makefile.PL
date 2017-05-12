use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Pageset::Variable',
    'VERSION_FROM'	=> 'Variable.pm',
    'PREREQ_PM'		=> { 'Data::Pageset' => 0.03 }, 
);
