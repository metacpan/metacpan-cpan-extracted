use 5.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Biblio::Citation::Compare',
    VERSION_FROM      => 'lib/Biblio/Citation/Compare.pm', # finds $VERSION
    PREREQ_PM         => {
        'Text::Names' => 0.19,
        'Text::LevenshteinXS' => 0.03,
        'HTML::Parser' => 2.25, 
        'Test::More' => 0.96
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Biblio/Citation/Compare.pm', # retrieve abstract from module
       AUTHOR         => 'David Bourget') : ()),
);
