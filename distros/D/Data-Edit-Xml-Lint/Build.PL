#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/

use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Xml::Lint',
  create_readme =>  0,
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Lint xml files in parallel using xmllint and report the failure rate',
  license       => 'perl',
  requires      =>
   {Data::Dump       =>0,
    'Data::Table::Text'              => 20200101,
    'Data::Edit::Xml'                => 20191231,
    Carp             =>0,
    Digest::SHA      =>0,
    Encode           =>0,
    perl             => '5.26.1',
    Test::More       =>0,
    Test::SharedFork =>0,
   },
  configure_requires => {'Module::Build'=>0.4224},
  can_run            => 'xmllint',
 );

$b->create_build_script();
