use ExtUtils::MakeMaker;
use constant { MIN_PERL_VERSION => 5.008001 };
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
unless   ($] >= MIN_PERL_VERSION ){
    warn " this perl version not supported $] ";
    exit;
}

WriteMakefile(
    NAME              => 'AI::Pathfinding::AStar::Rectangle',
    VERSION_FROM      => 'lib/AI/Pathfinding/AStar/Rectangle.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/AI/Pathfinding/AStar/Rectangle.pm', # retrieve abstract from module
    AUTHOR         => 'A.G. Grishaev <gtoly@cpan.org>' ,
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	$ExtUtils::MakeMaker::VERSION >= 6.48 ?  (MIN_PERL_VERSION => MIN_PERL_VERSION) : (),
	$ExtUtils::MakeMaker::VERSION >= 6.31 ?  ( LICENSE => 'perl') : (),

	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
