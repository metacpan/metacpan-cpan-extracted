use strict;
use warnings;
use lib 'lib';
use App::Open;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Open',
    license             => 'bsd',
    dist_author         => 'Erik Hollensbe <erik@hollensbe.org>',
    dist_version        => $App::Open::VERSION,
    script_files => [qw(bin/openit)],
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'YAML::Syck' => 0,
        'URI' => 0,
        'Getopt::Long' => 0,
        'version' => 0,
    },
    recommends => {
        'Mail::Cap' => 0,
        'MIME::Types' => 0,
    },
    add_to_cleanup      => [ 'App-Open-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
