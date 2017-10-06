use 5.8.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires => {'Module::Build'=>0.4224},
  create_readme      =>  0,
  dist_abstract      => 'Send a block of data from one process to another on the local machine.',
  dist_author        => 'philiprbrenan@gmail.com',
  license            => 'perl',
  module_name        => 'Data::Send::Local',
  perl               => '5.8.0',
  requires           => {
    Carp=>0,
    'Data::Dump'         =>0,
    'Data::Table::Text'  =>20170820,
    'Socket'             =>0,
    'Test2::Bundle::More'=>0,
   },
 );

$b->create_build_script();
