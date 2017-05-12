use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::PhraseBook',
    VERSION_FROM      => 'lib/DBIx/PhraseBook.pm', # finds $VERSION
    PREREQ_PM         => {Config::PropertiesSequence => 1.0, 
                            Class::Phrasebook=> 0.88, 
                            DBI=> 1.30,
                            Carp::Assert => 0.17,
                            Benchmark::Timer => 0.5,
                            Log::Log4perl => 0.4,
                            XML::XPath => 1,
                            }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/PhraseBook.pm', # retrieve abstract from module
       AUTHOR         => 'Mark Clements <mark.clements@kcl.ac.uk>') : ()),
       dist => { compress => "gzip" } ,
    XS => {} ,
     'linkext'   => { LINKTYPE=>'' },
);
