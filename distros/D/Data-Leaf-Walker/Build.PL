use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Leaf::Walker',
    license             => 'perl',
    dist_author         => q{Dan Boorstein <danboo@cpan.org>},
    dist_version_from   => 'lib/Data/Leaf/Walker.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Data-Leaf-Walker-*' ],
    create_makefile_pl => 'traditional',
    meta_merge          =>
       {
       resources =>
          {
          repository  => 'http://github.com/danboo/perl-data-leaf-walker/',
          }
       },
);

$builder->create_build_script();
