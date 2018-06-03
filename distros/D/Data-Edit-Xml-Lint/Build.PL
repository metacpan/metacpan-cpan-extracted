use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml::Lint',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Lint xml files in parallel using xmllint and report the failure rate',
  license       => 'perl',
  perl          => '5.16.0',
  requires      =>
   {Data::Edit::Xml=>20180530,
    Data::Table::Text=>20180530,
    Carp=>0,
    Digest::SHA=>0,
    Encode=>0,
    Test::More=>0,
    Test::SharedFork=>0,
   },
  configure_requires => {'Module::Build'=>0.42},
  can_run       => 'xmllint',
 );

$b->create_build_script();
