use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Binary::Heap::Search',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Create a binary search heap',
  license       => 'perl',
  requires      => {Data::Dump=>0, utf8=>0, Carp=>0, Data::Table::Text=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  1,
 );

$b->create_build_script();
