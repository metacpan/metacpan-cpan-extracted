use ExtUtils::MakeMaker;
WriteMakefile(
    NAME			=> 'AI::ParticleSwarmOptimization::MCE',
    AUTHOR			=> 'Lukasz Strzelecki <lukasz@strzeleccy.eu>',
    VERSION_FROM	=> 'lib/AI/ParticleSwarmOptimization/MCE.pm',
    ABSTRACT_FROM	=> 'lib/AI/ParticleSwarmOptimization/MCE.pm',
    PL_FILES		=> {},
    PREREQ_PM		=> {
		'AI::ParticleSwarmOptimization'	=> '1.006',
		'MCE'							=> '1.874',
		'MCE::Map'						=> '1.874',
		'MCE::Util'						=> '1.874',
		'Clone'							=> 0,
		'List::Util'					=> 0,
		'Storable'						=> 0,
		'Class::Accessor::Fast'			=> 0,
    },
);
