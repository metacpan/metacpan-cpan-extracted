use Module::Build;

my $b = Module::Build->new(
  configure_requires  => {'Module::Build'=>0.4224},
  create_readme       =>  0,
  dist_abstract       => 'Write data in tabular text format',
  license             => 'perl',
  module_name         => 'Data::Table::Text',
  requires            => {
     B                => 0,
     Carp             => 0,
     Cwd              => 0,
    'Data::Dump'      => 0,
    'Digest::MD5'     => 0,
    'Exporter'        => 0,
    'File::Glob'      => 1.17,
    'File::Path'      => 0,
    'File::Temp'      => 0,
    'IO::Socket::UNIX'=> 0,
     JSON             => 0,
     perl             => '5.26.1',
     POSIX            => 0,
    'Scalar::Util'    => 0,
     Storable         => 0,
    'Time::HiRes'     => 0,
    'Test::More'      => 0,
    'Test2::API'      => 0,
     utf8             => 0,
   },
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/DataTableText',
      bugtracker => 'https://github.com/philiprbrenan/DataTableText/issues'
     }
   },
 );

$b->create_build_script();
