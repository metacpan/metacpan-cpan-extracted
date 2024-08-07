use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Layout::BuddySystem',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Layout data in memory allocated via a buddy system',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Data::Dump=>0, utf8=>0, Carp=>0, Data::Table::Text=>20170808,
                    Test::More=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  0,
 );

$b->create_build_script();
