use 5.008008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::TraitFor::Controller::jQuery::jqGrid::Search',
    license             => 'perl',
    dist_abstract       => 'Catalyst helper function for translating jqGrid search parameters',
    dist_author         => q{Scott R. Keszler <keszler@srkconsulting.com>},
    dist_version_from   => 'lib/Catalyst/TraitFor/Controller/jQuery/jqGrid/Search.pm',
    perl_version        => '5.008008',
    release_status      => 'stable',
    configure_requires  => {
        'Module::Build'     => 0,
    },
    build_requires      => {
        'Test::More'        => 0,
    },
    requires            => {
        'perl'              => 5.008008,
        'Moose::Role'       => 0,
        'JSON'              => 0,
    },
    add_to_cleanup      => [ 'Catalyst-TraitFor-Controller-jQuery-jqGrid-Search-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge => {
      resources => {
        repository => 'http://app.srkconsulting.com/repos/jqGridSearch/',
      }
    },
  );

$builder->create_build_script();
