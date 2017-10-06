use 5.012000;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'App::MFILE::WWW',
    license              => 'bsd',
    dist_author          => q{Nathan Cutler <ncutler@suse.cz>},
    dist_version_from    => 'lib/App/MFILE/WWW.pm',
    create_license       => 0,
    create_readme        => 0,
    release_status       => 'stable',
    share_dir            => {
        dist => [ 'share' ],
    },
    script_files         => [
        'bin/mfile-www',
    ],
    configure_requires => {
        'Module::Build'  => 0,
    },
    build_requires => {
        'App::CELL'      => 0.222,
        'HTTP::Request'  => 0,
        'Plack::Test'    => 0,
        'Scalar::Util'   => 0,
        'Test::Fatal'    => 0,
        'Test::JSON'     => 0,
    },
    requires => {
        'perl'           => 5.012,
        'App::CELL'      => 0.222,
        'Getopt::Long'   => 0,
        'File::ShareDir' => 0,
        'File::Temp'     => 0,
        'JSON'           => 0,
        'Log::Any::Adapter' => 0,
        'LWP::UserAgent' => 0,
        'Params::Validate' => 1.06,
        'Plack::Builder' => 0,
        'Plack::Middleware::Session' => 0,
        'Plack::Middleware::StackTrace' => 0,
        'Plack::Middleware::Static' => 0,
        'Plack::Runner'  => 0,
        'Scalar::Util'   => 0,
        'Try::Tiny'      => 0,
        'Web::Machine'   => 0.15,
    },
    add_to_cleanup     => [ 'App-MFILE-WWW-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
