use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml::Lint',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Lint an xml file using xmllint',
  license       => 'perl',
  perl          => '5.16.0',
  requires      => {Carp=>0, POSIX=>0, Data::Table::Text=>0, Carp=>0, XML::Parser=>0},
  can_run       => 'xmllint',
 );

$b->create_build_script();

unlink $_ for
 qw(
/home/phil/z/perl/cpan/DataEditXmlLint/zzz.html
/home/phil/z/perl/cpan/DataEditXmlLint/pod2html.data
/home/phil/z/perl/cpan/DataEditXmlLint/lib/Data/Edit/Xml/doc.data
/home/phil/z/perl/cpan/DataEditXmlLint/lib/Data/Edit/Xml/methods.data
);
