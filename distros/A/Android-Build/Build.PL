use v5.16;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Android::Build',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Command line build of an Android apk without resorting to ant or gradle.',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Dump'       =>0,
    'Data::Table::Text'              => 20201029,
    'File::Copy'       =>0,
    'POSIX'            =>0,
    'Test2::API'       =>0,
    'Test::More'       =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.16.0',
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/AndroidBuild',
      bugtracker => 'https://github.com/philiprbrenan/AndroidBuild/issues'
     }
   },
 );

$b->create_build_script();
