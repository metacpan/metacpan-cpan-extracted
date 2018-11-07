use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
'NAME'              => 'Captcha::Stateless',
'VERSION_FROM'      => 'Stateless.pm', # finds $VERSION
'PREREQ_PM'         => {Crypt::CBC => 2.33, Crypt::Blowfish => 2.14}, # e.g., Module::Name => 1.1
($] >= 5.005 ?    ## Add these new keywords supported since 5.005
(ABSTRACT   => 'A stateless captcha implementation that stores state in an HTTP cookie in the browser.',
AUTHOR     => 'Martin Schmitt <mas at scsy dot de>') : ()),
);
