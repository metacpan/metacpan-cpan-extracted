use Module::Build;

my $b = Module::Build->new(
  configure_requires        => {'Module::Build'=>0.4224},
  create_readme             =>  0,
  dist_abstract             => 'Convert multiple Xml documents in parallel to Dita.',
  license                   => 'perl',
  module_name               => 'Data::Edit::Xml::To::Dita',
  perl                      => '5.20',
  requires                  => {
     Carp                   => 0,
    'Data::Dump'            => 0,
    'Data::Edit::Xml'       => q(20190708),
    'Data::Edit::Xml::Lint' => q(20190708),
    'Data::Edit::Xml::Xref' => q(20190708),
    'Data::Table::Text'     => q(20190708),
    'Exporter'              => 0,
    'Flip::Flop'            => 0,
    'Scalar::Util'          => 0,
     Storable               => 0,
    'Test::More'            => 0,
    'Test2::API'            => 0,
     utf8                   => 0,
   },
 );

$b->create_build_script();
