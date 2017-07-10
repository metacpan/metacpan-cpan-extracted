use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Edit data in xml format',
  license       => 'perl',
  requires      => {Carp=>0, POSIX=>0, Data::Table::Text=>0, Carp=>0, XML::Parser=>0},
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
