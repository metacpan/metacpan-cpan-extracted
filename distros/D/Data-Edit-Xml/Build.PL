use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Edit data in xml format',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Carp=>0, Data::Table::Text=>20170808, Test::More=>0,
                    XML::Parser=>0, Storable=>0},
  configure_requires => {'Module::Build'=>0.42},
 );

$b->create_build_script();
