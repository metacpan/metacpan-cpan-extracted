use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'AI::NNFlex',
    'VERSION_FROM'      => 'lib/AI/NNFlex.pm', # finds $VERSION
    'PREREQ_PM'         => {'Math::Matrix'=>0}, 
	'MAN3PODS'	=> { },
);
