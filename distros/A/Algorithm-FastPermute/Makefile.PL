use ExtUtils::MakeMaker;
require 5.006;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'Algorithm::FastPermute',
    VERSION_FROM	=> 'FastPermute.pm', # finds $VERSION
    PREREQ_PM		=> {}, # e.g., Module::Name => 1.1
    LIBS		=> [''], # e.g., '-lm'
    DEFINE		=> '', # e.g., '-DHAVE_SOMETHING'
    INC			=> '', # e.g., '-I/usr/include/other'
    OPTIMIZE            => '-O2',
    dist => {TAR => 'gnutar'}, # Used by 'make dist'
);
