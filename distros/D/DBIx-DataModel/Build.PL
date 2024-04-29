use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::DataModel',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami AT cpan.org>',
    dist_version_from   => 'lib/DBIx/DataModel.pm',
    requires => {
        'perl'                   => 5.010,
        'version'                => 0,
        'Carp::Object'           => 0,
        'Clone'                  => 0,
        'DBI'                    => 0,
        'SQL::Abstract::Classic' => 1.91,
        'SQL::Abstract::More'    => 1.41,
        'Module::Build'          => 0,
        'Data::Structure::Util'  => 0,
        'Hash::Util'             => 0,
        'Scalar::Util'           => 1.07,
        'Storable'               => 0,
        'namespace::clean'       => 0,
        'MRO::Compat'            => 0,
        'Module::Load'           => 0,
        'Params::Validate'       => 0,
        'Try::Tiny'              => 0,
    },
    configure_requires => {
        'Module::Build'       => 0,
     },
    build_requires => {
         # test_requires => { # not working in perl 5.10, so keep it as 'build_requires'
        'DBD::Mock'           => 1.39,
        'FindBin'             => 0,
        'DBD::SQLite'         => 1.38,
        'SQL::Abstract::Test' => 0,
    },
    recommends => {
        'Lingua::EN::Inflect::Phrase' => 0,
        'List::Categorize'            => 0.04,
        'File::Tabular'               => 0,
        'Excel::Writer::XLSX'         => 0,
        'JSON::MaybeXS'               => 0,
        'Cpanel::JSON::XS'            => 0,
        'YAML::XS'                    => 0,
    },
    add_to_cleanup      => [ 'DBIx-DataModel-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/DBIx-DataModel',
       }
     },
);

$builder->create_build_script();



