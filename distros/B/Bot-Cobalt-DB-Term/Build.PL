#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Bot::Cobalt::DB::Term',
  dist_abstract => 'Terminal frontend to Bot::Cobalt::DB',
  dist_author   => 'Jon Portnoy <avenj@cobaltirc.org>',
  license => 'perl',
  create_makefile_pl => 'small',
  requires => {
    'perl' => '5.12.1',
    'Carp'           => 0,
    'Data::Dumper'   => 0,
    'Text::ParseWords' => 0,
    
    'Bot::Cobalt'  => '0.003',
    
    'Term::UI'       => 0,
    'Term::ReadLine' => 0,
  },
  
  recommends => {
    'Term::ReadLine::Perl' => 0,
  }
);
$build->create_build_script;
