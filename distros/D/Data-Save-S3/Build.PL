use Module::Build;

unlink $_ for
 qw(
/home/phil/z/perl/cpan/DataSaveS3/zzz.html
/home/phil/z/perl/cpan/DataSaveS3/pod2htmd.tmp
/home/phil/z/perl/cpan/DataSaveS3/lib/Data/Edit/doc.data
/home/phil/z/perl/cpan/DataSaveS3/lib/Data/Edit/methods.data
);

my $b = Module::Build->new
 (module_name   => 'Data::Save::S3',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Zip some files to Amazon S3',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Carp=>0, Data::Table::Text=>0,
                    Test::More=>0, File::Copy=>0},
  configure_requires => {'Module::Build'=>0.42},
 );

$b->create_build_script();
