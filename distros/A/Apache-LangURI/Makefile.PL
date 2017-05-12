use 5.006;
BEGIN { eval "require Apache2"; }
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::LangURI',
    'VERSION_FROM'	=> 'LangURI.pm', # finds $VERSION
    'PREREQ_PM'		=> { mod_perl          => '1.24_01',
                      'Locale::Language' => '2.02',
                      'Locale::Country'  => '2.06' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LangURI.pm', # retrieve abstract from module
       AUTHOR     => 'dorian <dorian@foobarsystems.com>') : ()),
);
