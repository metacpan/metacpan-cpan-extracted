use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Convert::yEnc',
    'VERSION_FROM'	=> 'yEnc.pm', # finds $VERSION
    'PREREQ_PM'		=> { Set::IntSpan => 1.07 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'yEnc.pm', # retrieve abstract from module
       AUTHOR     => 'Steven W McDougall <swmcd@world.std.com>') : ()),
);
