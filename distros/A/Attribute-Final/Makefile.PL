use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Attribute::Final',
    'VERSION_FROM'	=> 'Final.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Attribute::Handlers => 0,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Final.pm', # retrieve abstract from module
       AUTHOR     => 'Simon Cozens <simon@cpan.org>') : ()),
);
