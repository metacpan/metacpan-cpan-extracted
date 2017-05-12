use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::CSV',
    'VERSION_FROM'	=> 'CSV.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Text::CSV_XS => 0.23,
        Class::Accessor => 0.18
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'David Radunz <dj@office.netspace.net.au>') : ()),
);
