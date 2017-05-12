use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::DataModel',
    license             => 'perl',
    dist_author         => 'Laurent Dami <laurent.dami AT etat.ge.ch>',
    dist_version_from   => 'lib/DBIx/DataModel.pm',
    requires => {
        'perl'                 => 5.008,
        'Test::More'           => 0,
	'Carp'                 => 0,
	'DBI'                  => 0,
	'SQL::Abstract::More'  => 1.21,
	'Module::Build'        => 0,
        'Acme::Damn'           => 0,
        'Scalar::Util'         => 0,
	'Storable'             => 0,

        # new dependencies in 2.0 
        'namespace::clean'     => 0,
        'MRO::Compat'          => 0,
        'Module::Load'         => 0,
        'Params::Validate'     => 0,
        'Scalar::Does'         => 0,
	'Try::Tiny'            => 0,
    },
    build_requires => {
        'Task::Weaken'  => 0,
    },
    recommends => {
        'DBD::Mock'                   => 0,
        'Lingua::EN::Inflect::Phrase' => 0,
    },
    add_to_cleanup      => [ 'DBIx-DataModel-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/DBIx-DataModel',
       }
     },
);

$builder->create_build_script();



