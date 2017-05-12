use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Pensieve',
    VERSION_FROM      => 'lib/Data/Pensieve.pm', # finds $VERSION
    PREREQ_PM         => { 
        Carp                      => 0,
        DateTime                  => 0,
        'DateTime::Format::MySQL' => 0,
        DBI                       => 0,
        'List::Util'              => 0,
        'List::MoreUtils'         => 0,
        'Storable'                => 0,
        'Text::Diff'              => 0,
        Moose                     => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Pensieve.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Aquilina <aquilina@cpan.org>') : ()),
);

