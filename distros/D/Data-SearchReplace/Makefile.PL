use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Data::SearchReplace',
    'VERSION_FROM'	=> 'SearchReplace.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SearchReplace.pm', # retrieve abstract from module
       AUTHOR     => 'Stephen D. Wells <wells@cedarnet.org>') : ()),
);
