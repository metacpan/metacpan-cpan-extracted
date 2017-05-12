use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Acme::Pod::MathJax',
  dist_author => 'Joel Berger',
  license => 'perl',
  
  requires => {
    'perl' => '5.8.0',
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },

  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Acme-Pod-MathJax",
      bugtracker => "http://github.com/jberger/Acme-Pod-MathJax/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
    },
  }
);

$builder->create_build_script;

