use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Crypt::Imail',
    'VERSION_FROM'	=> 'Imail.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ? 
      (ABSTRACT_FROM => 'Imail.pm', # retrieve abstract from module
       AUTHOR     => 'Stephen D. Wells <wells@cedarnet.org>') : ()),
);
