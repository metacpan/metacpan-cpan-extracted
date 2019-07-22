use Module::Build;

my $b = Module::Build->new(
  configure_requires   => {'Module::Build'=>0.4224},
  create_readme        =>  0,
  dist_abstract        => 'Edit data held in the XML format.',
  dist_author          => 'philiprbrenan@gmail.com',
  license              => 'perl',
  module_name          => 'Data::Edit::Xml',
  perl                 => '5.20',
  requires             => {
     Carp              => 0,
    'Data::Dump'       => 0,
    'Data::Table::Text'=> q(20190721),
     Storable          => 0,
    'Test::More'       => 0,
    'Test2::API'       => 0,
    'XML::Parser'      => 0,
     utf8              => 0,
   },
 );

$b->create_build_script();
