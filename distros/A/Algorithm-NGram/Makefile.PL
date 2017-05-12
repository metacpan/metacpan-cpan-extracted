use 5.6.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::NGram',
    VERSION_FROM      => 'lib/Algorithm/NGram.pm', # finds $VERSION
    PREREQ_PM         => {
        'Class::Accessor::Fast' => 0,
    },
    META_ADD => { resources => { repository => 'git://github.com/revmischa/algorithm-ngram.git' } },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Mischa Spiegelmock <mspiegelmock@gmail.com>') : ()),
);
