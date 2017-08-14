use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml::SDL',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Create SDL file map from a set of linted xml files',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Data::Table::Text=>0, Data::Edit::Xml::Lint=>0, Test::More=>0,
                    Carp=>0, Digest::SHA=>0, Encode=>0},
  configure_requires => {'Module::Build'=>0.42},
 );

$b->create_build_script();
