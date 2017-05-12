use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Class::Container',
   requires => {
		'Params::Validate' => '0.23',
		'Carp' => 0,
	       },
   recommends => { 'Scalar::Util' => 0 },
   license => 'perl',
   create_readme => 1,
   sign => 1,
  );

$b->create_build_script;
