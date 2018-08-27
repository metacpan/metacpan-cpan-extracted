use 5.018004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::Heapify::XS',
    VERSION_FROM      => 'lib/Algorithm/Heapify/XS.pm', # finds $VERSION
    OPTIMIZE          => '-O3',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/Heapify/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Yves Orton <yorton@(none)>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    META_MERGE => {
        resources => {
            repository => {
              url => 'git://github.com/demerphq/Algorithm-Heapify-XS.git',
            },
            bugtracker => {
              web => 'https://github.com/demerphq/Algorithm-Heapify-XS/issues',
            },
        },
        'meta-spec' => { version => 2 },
    },
);
