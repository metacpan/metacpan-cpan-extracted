use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AI::NeuralNet::Kohonen',
    VERSION_FROM      => 'lib/AI/NeuralNet/Kohonen.pm', # finds $VERSION
    PREREQ_PM         => {
		version	=> 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AI/NeuralNet/Kohonen.pm', # retrieve abstract from module
       AUTHOR         => 'lee goddard at cpan org') : ()),
);
