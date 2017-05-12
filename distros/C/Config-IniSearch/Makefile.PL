use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::IniSearch',
    'VERSION_FROM'	=> 'IniSearch.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Config::IniHash' => '0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'IniSearch.pm', # retrieve abstract from module
       AUTHOR     => 'Brian Koontz <brian@pongonova.net>') : ()),
    'test' => { 'TESTS' => 't/test.t', },
);
