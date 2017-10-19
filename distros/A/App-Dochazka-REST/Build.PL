use 5.012000;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'App::Dochazka::REST',
    license              => 'bsd',
    dist_author          => q{Nathan Cutler <ncutler@suse.com>},
    dist_version_from    => 'lib/App/Dochazka/REST.pm',
    create_license       => 0,
    create_readme        => 0,
    release_status       => 'stable',
    share_dir            => {
        dist => [ 'config' ],
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/smithfarm/dochazka-rest',
            bugtracker => 'https://github.com/smithfarm/dochazka-rest/issues',
        },
        no_index => {
            directory => [
                "config"
            ]
        }
    },
    script_files         => [
        'bin/dochazka-dbinit',
        'bin/dochazka-ldap-batch-create',
        'bin/dochazka-ldap-sync-all',
        'bin/dochazka-resetdb',
        'bin/dochazka-rest',
    ],
    configure_requires => {
        'Module::Build'  => 0,
    },
    build_requires => {
        'App::CELL'      => 0.215,
        'App::Dochazka::Common'  => 0.205,
        'Authen::Passphrase::SaltedDigest' => 0.008,
        'Date::Holidays::CZ' => 0.12,
        'DBIx::Connector' => 0.47,
        'File::ShareDir::Install' => 0.11,
        'File::Slurp'    => 0,
        'HTTP::Request'  => 0,
        'Mason'          => 0,
        'Plack::Test'    => 0,
        'Test::Fatal'    => 0,
        'Test::JSON'     => 0,
        'Test::Warnings' => 0,
        'Web::Machine'   => 0.15,
        'Web::MREST'     => 0.287,
        'Web::MREST::CLI'     => 0.276,
    },
    requires => {
        'perl'           => 5.012,
        'App::CELL'      => 0.215,
        'App::Dochazka::Common'  => 0.207,
        'Authen::Passphrase::SaltedDigest' => 0.008,
        'Date::Calc'     => 0,
        'Date::Holidays::CZ' => 0.12,
        'DBD::Pg'        => 0,
        'DBI'            => 0,
        'DBIx::Connector' => 0.47,
        'File::ShareDir' => 1.0,
        'JSON'           => 0,
        'Mason'          => 0,
        'Params::Validate' => 1.06,
        'Path::Router'   => 0.12,
        'Plack::Middleware::Session' => 0,
        'Plack::Middleware::StackTrace' => 0,
        'Plack::Runner'  => 0,
        'Pod::Simple::HTML' => 0,
        'Test::Deep::NoTest' => 0,
        'Try::Tiny'      => 0,
        'Web::Machine'   => 0.15,
        'Web::MREST'     => 0.287,
        'Web::MREST::CLI'     => 0.276,
    },
    add_to_cleanup     => [ 'App-Dochazka-REST-*' ],
    # create_makefile_pl => 'traditional',
    recursive_test_files => 1,
);

$builder->create_build_script();
