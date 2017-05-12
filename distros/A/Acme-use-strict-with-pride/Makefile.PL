use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'Acme::use::strict::with::pride',
    VERSION_FROM	=> 'pride.pm', # finds $VERSION
    PREREQ_PM           => { 'Test::More' => '0.41' },
    ABSTRACT_FROM	=> 'pride.pm', # retrieve abstract from module
    AUTHOR		=> 'Nicholas Clark <nick@unfortu.net>',
);
