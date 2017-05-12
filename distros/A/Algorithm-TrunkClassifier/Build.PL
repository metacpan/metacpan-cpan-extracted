use Module::Build;
my $build = Module::Build->new(
	module_name        => 'Algorithm::TrunkClassifier',
	dist_abstract      => "Implementation of the Decision Trunk Classifier algorithm",
	license            => 'unrestricted',
	needs_compiler     => 1,
	build_requires     => {
		'Module::Build'       => '0.19',
    	'ExtUtils::CBuilder'  => '0.21',
    	'XSLoader'            => '0',
    	'Exporter'            => '0',
    	'POSIX'               => '0',
	},
	c_source           => 'Algorithm/TrunkClassifier/src',
	xs_files           => {
		'Algorithm/TrunkClassifier/FeatureSelection.xs' => 'Algorithm/TrunkClassifier/FeatureSelection.xs'
	},
	pod_files          => {
		'pod/TrunkClassifier.pod' => 'pod/TrunkClassifier.pod'
	}
);
$build->create_build_script();
