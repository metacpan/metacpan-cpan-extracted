use Module::Build;

unlink $_ for
 qw(
/home/phil/z/perl/cpan/DataTableText/zzz.html
/home/phil/z/perl/cpan/DataTableText/pod2htmd.tmp
/home/phil/z/perl/cpan/DataTableText/lib/Data/Edit/doc.data
/home/phil/z/perl/cpan/DataTableText/lib/Data/Edit/methods.data
);

my $b = Module::Build->new
 (module_name   => 'Data::Table::Text',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Write data in tabular text format',
  license       => 'perl',
  requires      => {Data::Dump=>0,
                    utf8=>0, Carp=>0, File::Path=>0, Test::More=>0,
                    File::Glob=>1.24, POSIX=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
