use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'DBM::Any',
    'VERSION_FROM'	=> 'Any.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Any.pm', # retrieve abstract from module
       AUTHOR     => 'Tony Monroe <tmonroe+perl@nog.net>') : ()),
);
