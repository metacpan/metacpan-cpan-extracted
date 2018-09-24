use 5.8.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires   => {'Module::Build'=>0.4224},
  create_readme        =>  0,
  dist_abstract        => 'Exchange files and update issues from your colleagues via an S3 bucket.',
  dist_author          => 'philiprbrenan@gmail.com',
  license              => 'perl',
  module_name          => 'Data::Exchange',
  perl                 => '5.8.0',
  requires             => {
     Carp              => 0,
    'Data::Dump'       => 0,
    'Data::Table::Text'=> '20180817',
     Storable          => 0,
    'Test::More'       => 0,
    'Test2::API'       => 0,
    'XML::Parser'      => 0,
     utf8              => 0,
   },
 );

$b->create_build_script();
