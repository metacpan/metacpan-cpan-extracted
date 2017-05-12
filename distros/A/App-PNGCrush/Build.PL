use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::PNGCrush',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/App/PNGCrush.pm',
    configure_requires => { 'Module::Build' => 0 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                  => 1.04,
        'Proc::Reliable'        => 1.16,
        'Devel::TakeHashArgs'   => 0.003,
        'Class::Data::Accessor' => 0.04001,
        perl                    => '5.006',
    },
    add_to_cleanup      => [ 'App-PNGCrush-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
