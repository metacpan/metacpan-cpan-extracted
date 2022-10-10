use ExtUtils::MakeMaker;
WriteMakefile(
    NAME			=> 'AI::ParticleSwarmOptimization::Pmap',
    AUTHOR			=> 'Lukasz Strzelecki <lukasz@strzeleccy.eu>',
    VERSION_FROM	=> 'lib/AI/ParticleSwarmOptimization/Pmap.pm',
    ABSTRACT_FROM	=> 'lib/AI/ParticleSwarmOptimization/Pmap.pm',
    PL_FILES		=> {},
    PREREQ_PM		=> {
		'AI::ParticleSwarmOptimization'	=> '1.006',
		'Parallel::parallel_map'		=> '0.02',
		'List::Util'					=> 0,
    },
);
