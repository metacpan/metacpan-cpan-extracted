#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/

use Module::Build;

my $b = Module::Build->new(
  configure_requires   => {'Module::Build'=>0.4224},
  create_readme        =>  0,
  dist_abstract        => 'Edit data held in the XML format.',
  dist_author          => 'philiprbrenan@gmail.com',
  license              => 'perl',
  module_name          => 'Data::Edit::Xml',
  perl                 => '5.26',
  requires             => {
     Carp              => 0,
    'Data::Dump'       => 0,
    'Data::Table::Text'              => 20201029,
     Storable          => 0,
    'Test::More'       => 0,
    'Test2::API'       => 0,
    'XML::Parser'      => 0,
     utf8              => 0,
   },
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/DataEditXml',
      bugtracker => 'https://github.com/philiprbrenan/DataEditXml/issues'
     }
   },
 );

$b->create_build_script();
