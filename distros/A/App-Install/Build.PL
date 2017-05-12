use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Install',
    license             => 'perl',
    dist_author         => 'Kirrily "Skud" Robert <skud@cpan.org>',
    dist_version_from   => 'lib/App/Install.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Text::Template' => 0,
        'File::ShareDir' => 0,
        'File::Path'     => 0,
    },
    add_to_cleanup      => [ 'App-Install-*' ],
);

$builder->create_build_script();
