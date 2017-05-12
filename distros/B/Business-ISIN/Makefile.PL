use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    ABSTRACT	 => 'validate International Securities Identification Numbers',
    AUTHOR	 => 'David Chan (david@sheetmusic.org.uk)',
    NAME	 => 'Business::ISIN',
    VERSION_FROM => 'ISIN.pm', # finds $VERSION
);
