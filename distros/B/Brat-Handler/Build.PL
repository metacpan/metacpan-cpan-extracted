use Module::Build;

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    );

my $build = $class->new
    (
     module_name => 'Brat::Handler',
     dist_version_from => 'lib/Brat/Handler.pm',
     license => 'perl',
     configure_requires => { 
	 'Module::Build' => 0.38,
	 "Getopt::Long" => 0,
	 Test::Pod::Coverage => 0,
	 Test::Pod => 0,
	 "Pod::Usage" => 0,
     },
     requires => {'perl' => '5.10.0',
	      },
     build_requires => {
	 "Module::Build"     => 0.28,
     },
    );

$build->create_build_script;

