use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Class::Structured',
    'VERSION_FROM'	=> 'Structured.pm', # finds $VERSION
    'PREREQ_PM'		=> { Set::Scalar => 1.06 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Structured.pm', # retrieve abstract from module
       AUTHOR     => 'Robby Walker <robwalker@cpan.org>') : ()),
);
