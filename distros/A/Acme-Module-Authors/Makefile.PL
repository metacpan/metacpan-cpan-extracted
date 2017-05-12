use ExtUtils::MakeMaker;
require 5.006;
WriteMakefile(
    'NAME'      => 'Acme::Module::Authors',
    'VERSION_FROM' => 'lib/Acme/Module/Authors.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
