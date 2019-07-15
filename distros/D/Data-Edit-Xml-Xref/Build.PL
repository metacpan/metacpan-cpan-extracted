use 5.8.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires    => {'Module::Build'=>0.4224},
  create_readme         =>  0,
  dist_abstract         => 'Cross reference Dita XML, match topics and ameliorate missing references.',
  dist_author           => 'philiprbrenan@gmail.com',
  license               => 'perl',
  module_name           => 'Data::Edit::Xml::Xref',
  perl                  => '5.8.0',
  requires              => {
     Carp               => 0,
    'Data::Dump'        => 0,
    'Data::Edit::Xml'   => '20190714',
    'Data::Table::Text' => '20190714',
    'Dita::GB::Standard'=> '20190708',
    'Test::More'        => 0,
    'Test2::API'        => 0,
     utf8               => 0,
   },
 );

$b->create_build_script();
