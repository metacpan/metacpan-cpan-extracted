use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AI::NeuralNet::Hopfield',
    AUTHOR           => q{leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/AI/NeuralNet/Hopfield.pm',
    ABSTRACT_FROM    => 'lib/AI/NeuralNet/Hopfield.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moose' => 2.0604,
	    'Math::SparseMatrix' => 0.03,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'AI-NeuralNet-Hopfield-*' },
);
