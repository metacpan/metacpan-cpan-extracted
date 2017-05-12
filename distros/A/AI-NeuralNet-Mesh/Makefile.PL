use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'AI::NeuralNet::Mesh',
    'VERSION_FROM'      => 'Mesh.pm', # finds $VERSION
    'PREREQ_PM'         => {}, 
);
