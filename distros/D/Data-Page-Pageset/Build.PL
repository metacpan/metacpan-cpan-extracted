use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Page::Pageset',
    license             => 'perl',
    dist_author         => 'Chunzi <me@chunzi.org>',
    dist_version_from   => 'lib/Data/Page/Pageset.pm',
    requires => { 'Test::More' => 0,
                  'Test::Exception' => 0,
                  'Data::Page' => 2,
                  'Class::Accessor' => 0,
                  Carp => 0,
                  },
    add_to_cleanup      => [ 'Data-Page-Pageset-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script;
