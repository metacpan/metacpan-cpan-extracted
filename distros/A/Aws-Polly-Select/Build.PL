use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Aws::Polly::Select',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Select AWS Polly speakers with specified characteristics',
  license       => 'perl',
  requires      => {Carp=>0, Data::Dump=>0, Data::Table::Text=>0, JSON=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
