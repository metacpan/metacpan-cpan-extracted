use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Unique::Name',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Generate a unique but stable name from a string',
  perl          => '5.16.0',
  license       => 'perl',
  requires      => {Carp=>0, Test::More=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  0,
 );

$b->create_build_script();
