use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Algorithm::NaiveBayes',
   license => 'perl',
   create_makefile_pl => 'traditional',
   requires => {
		'List::Util' => 0,
	       },
  );

$build->create_build_script;
