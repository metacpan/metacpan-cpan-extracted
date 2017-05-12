use Module::Build;
my $build = new Module::Build
(
  module_name    => 'Attempt',
  license        => 'perl',
  requires       => {
		     "Sub::Uplevel" => "0.07",
                    },
  recommends     => {
                     "Attribute::Handlers" => "0",
                    },
  build_requires => {
		     "Test::More"      => "0",
		     "Test::Exception" => "0",
                    },
  create_makefile_pl => "traditional",
);
$build->create_build_script;
