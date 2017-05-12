use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bio::Cellucidate',
    VERSION_FROM      => 'lib/Bio/Cellucidate.pm', # finds $VERSION
    PREREQ_PM         => { 
        XML::Simple     => 2.18,
        HTTP::Headers   => 5.827,
        REST::Client    => 134
    },
    META_MERGE        => {
        resources   => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://cellucidate.com/api',
            repository  => 'http://github.com/cellucidate/perl-Cellucidate'
        }
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bio/Cellucidate.pm', # retrieve abstract from module
       AUTHOR         => 'Brian Kaney <brian@vermonster.com>') : ()),
);
