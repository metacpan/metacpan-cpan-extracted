use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Queue::Persistent',
    VERSION_FROM      => 'lib/Data/Queue/Persistent.pm', # finds $VERSION
    PREREQ_PM         => {
        'DBI' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Mischa Spiegelmock <mspiegelmock@gmail.com>') : ()),
);
