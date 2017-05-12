use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Android::Build',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Compile, install, start an Android App using the sdk command line build tools rather than calling them via ant or gradle.',
  license       => 'perl',
  requires      => {Carp=>0, Data::Dump=>0, Data::Table::Text=>2017.430,
                    File::Copy=>0, POSIX=>0,
                    },
  configure_requires => {'Module::Build' => 0.42},
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
