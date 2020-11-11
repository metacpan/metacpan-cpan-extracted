use v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::DFA',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Deterministic finite state parser from regular expression.',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Dump'       =>0,
    'Data::Table::Text'              => 20201029,
    'Data::NFA'                      => 20201030,
    'Test2::API'       =>0,
    'Test::More'       =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.26.0',
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/DataDFA',
      bugtracker => 'https://github.com/philiprbrenan/DataDFA/issues'
     }
   },
 );

$b->create_build_script();
