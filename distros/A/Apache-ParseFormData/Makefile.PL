use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::ParseFormData',
    'VERSION_FROM'	=> 'ParseFormData.pm', # finds $VERSION
    'PREREQ_PM'		=> { mod_perl => 1.9908 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ParseFormData.pm', # retrieve abstract from module
       AUTHOR     => 'Henrique Dias <hdias@aesbuc.pt>') : ()),
);
