use 5.012002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BSD::Socket::Splice',
    VERSION_FROM      => 'lib/BSD/Socket/Splice.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/BSD/Socket/Splice.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Bluhm <bluhm@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    LICENSE           => 'perl',
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    SIGN              => 1,
    META_MERGE => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url  => 'git://github.com/bluhm/p5-bsd-socket-splice.git',
		web  => 'https://github.com/bluhm/p5-bsd-socket-splice',
	    },
	},
    },
);
