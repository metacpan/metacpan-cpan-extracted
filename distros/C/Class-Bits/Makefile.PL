use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Bits',
    'VERSION_FROM'	=> 'Bits.pm', # finds $VERSION
    'PREREQ_PM'		=> { Test::More },
    'ABSTRACT_FROM'     => 'Bits.pm', # retrieve abstract from module
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>'
);
