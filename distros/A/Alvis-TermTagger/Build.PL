use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Alvis::TermTagger',
     dist_version_from => 'lib/Alvis/TermTagger.pm',
     license => 'gpl',
     requires => {'perl' => '5.005',
		  Getopt::Long => 0,
		  Pod::Usage => 0,
  		  Test::More => 0.62,
  		  File::Touch => 0,
		  Test::Pod::Coverage => 0,
		  Test::Pod => 0,
		  },
      build_requires => {
         "Module::Build"     => 0.28,
     },
      configure_requires => { 'Module::Build' => 0.38 },
     );

$build->create_build_script;
