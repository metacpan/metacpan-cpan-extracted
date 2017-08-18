use Module::Build;

my $b = Module::Build->new(
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme      =>  0,
  dist_abstract      => 'Write data in tabular text format',
  dist_author        => 'philiprbrenan@gmail.com',
  license            => 'perl',
  module_name        => 'Data::Table::Text',
  perl               => '5.16.0',
  requires           => {Carp=>0,
                         Cwd=>0,
                         Data::Dump=>0,
                         File::Glob=>1.17, File::Path=>0, File::Temp=>0,
                         Test::More=>0,
                         POSIX=>0,
                         utf8=>0},
 );

$b->create_build_script();
