use Module::Build;

my $b = Module::Build->new
 (module_name              => 'Data::Edit::Xml::SDL',
  configure_requires       => {'Module::Build'=>0.4224},
  create_readme            =>  0,
  dist_author              => 'philiprbrenan@gmail.com',
  dist_abstract            => 'Create SDL file map from a set of linted xml files',
  license                  => 'perl',
  perl                     => '5.16.0',
  requires                 => {
     Carp                  => 0,
    'Data::Dump'           => 0,
    'Data::Edit::Xml::Lint'=> '20180629',
    'Data::Table::Text'    => '20180610',
    'Digest::SHA'          => 0,
     Encode                => 0,
     Storable              => 0,
    'Test::More'           => 0,
    'Test2::API'           => 0,
    'XML::Parser'          => 0,
     utf8                  => 0,
   },
 );

$b->create_build_script();
