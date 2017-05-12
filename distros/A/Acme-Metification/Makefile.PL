use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Metification',
    'VERSION_FROM'	=> 'lib/Acme/Metification.pm', # finds $VERSION
    'LICENSE' => 'perl',
    'PREREQ_PM'		=> {
                             Filter::Simple => 0.78,
                             Test::More => 0.44,
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/Metification.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <metification-module@steffen-mueller.net>') : ()),
);
