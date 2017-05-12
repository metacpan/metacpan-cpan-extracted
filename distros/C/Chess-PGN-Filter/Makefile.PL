use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Chess::PGN::Filter',
    'VERSION_FROM'	=> 'Filter.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Chess::PGN::EPD => 0.08,
        Text::DelimMatch => 1.01,
        Chess::PGN::Parse => 0.01,
        Test => 1.15,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Filter.pm', # retrieve abstract from module
       AUTHOR     => 'Hugh S. Myers <hsmyers@sdragons.com>') : ()),
);
