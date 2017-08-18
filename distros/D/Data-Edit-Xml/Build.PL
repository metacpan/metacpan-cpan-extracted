use 5.16.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires => {'Module::Build'=>0.42},
  create_readme      =>  0,
  dist_abstract      => 'Edit data in xml format',
  dist_author        => 'philiprbrenan@gmail.com',
  license            => 'perl',
  module_name        => 'Data::Edit::Xml',
  perl               => '5.16.0',
  requires           => {
    Carp=>0,
    'Data::Table::Text'=>20170808,
    perl=>'5.16.0',
    Storable=>0,
    'Test::More'=>0,
    'XML::Parser'=>0,
   },
 );

$b->create_build_script();
