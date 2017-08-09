use Module::Build;

unlink $_ for
 qw(
/home/phil/z/perl/cpan/DataEditXml/zzz.html
/home/phil/z/perl/cpan/DataEditXml/pod2htmd.tmp
/home/phil/z/perl/cpan/DataEditXml/lib/Data/Edit/doc.data
/home/phil/z/perl/cpan/DataEditXml/lib/Data/Edit/methods.data
);

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Edit data in xml format',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Carp=>0, Data::Table::Text=>0, Test::More=>0,
                    XML::Parser=>0, Storable=>0},
  configure_requires => {'Module::Build'=>0.42},
 );

$b->create_build_script();
