use 5.024001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $cflags = $ExtUtils::MakeMaker::Config{ccflags};
WriteMakefile(
    NAME              => 'DR::R',
    VERSION_FROM      => 'lib/DR/R.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/DR/R.pm', # retrieve abstract from module
    AUTHOR            => 'Dmitry E. Oboukhov <unera@>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Irtree -Irtree/salad -Irtree/small',
    OBJECT            => '$(O_FILES)', # link all the C files too

    CCFLAGS             => "$cflags -std=gnu99 -Wunused-variable",
);
