use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DNS::Bananafonana',
    'AUTHOR' => 'Michiel Fokke <michiel@fokke.org>',
    'LICENSE' => 'perl',
    'SIGN' => 1,
    'ABSTRACT_FROM' => 'Bananafonana.pm',
    'VERSION_FROM' => 'Bananafonana.pm', # finds $VERSION
    'PREREQ_PM' => { 'Math::BigInt' => 0 },
);
