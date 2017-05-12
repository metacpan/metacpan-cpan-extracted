use Module::Build;
my $build = new Module::Build
(
  module_name    => 'Acme::VerySign',
  license        => 'perl',
  requires       => { "Symbol::Approx::Sub" => "2.00"
                    },
  recommends     => {
		      "Text::Metaphone" => "0",
                    },
  build_requires => { "Test::More" => "0"
                    },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
