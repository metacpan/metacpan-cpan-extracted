use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'CGI::kSession',
    'VERSION_FROM'	=> 'kSession.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Marcin Krzyzanowski <krzak@cpan.org>') : ()),
);
