use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Spoor',
    license             => 'artistic_2',
    dist_author         => q{Rory McKinley <rorymckinley@capefox.co>},
    dist_version_from   => 'lib/App/Spoor.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More'          => '0',
        'Test::SetupTeardown' => '0.004',
        'Test::MockTime'      => '0.16',
        'Test::LWP::UserAgent' => '0.033',
    },
    requires => {
        'Path::Tiny'                 => '0.108',
        'YAML::Tiny'        => '1.70',
        'File::Tail'        => '1.3',
        'File::Touch'         => '0.11',
        'DateTime::Format::Strptime' =>  '1.75',
        'JSON'                       =>  '2.97001',
        'LWP::Protocol::https'       => '6.07'
    },
    add_to_cleanup     => [ 'App-Spoor-*' ],
);

$builder->create_build_script();
