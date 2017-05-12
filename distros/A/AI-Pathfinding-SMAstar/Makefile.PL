use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AI::Pathfinding::SMAstar',
    VERSION_FROM      => 'lib/AI/Pathfinding/SMAstar.pm', # finds $VERSION
    PREREQ_PM         => {Test::More => 0,
			  Tree::AVL =>  0,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AI/Pathfinding/SMAstar.pm', # retrieve abstract from module
       AUTHOR         => 'Matthias Beebe <mbeebe@cpan.org>') : ()),
);
