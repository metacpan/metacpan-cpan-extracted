use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Date::Holidays::DE',
    'VERSION_FROM'	=> 'DE.pm', # finds $VERSION
    'PREREQ_PM'		=> {Date::Calc => 5.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT   => 'Determine German Holiday dates',
       AUTHOR     => 'Martin Schmitt <mas at scsy dot de>') : ()),
);
