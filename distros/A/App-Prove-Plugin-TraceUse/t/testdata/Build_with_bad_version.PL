use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Prove::Plugin::TraceUse',
    license             => 'perl',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@diagenic.com>',
    dist_version_from   => 'lib/App/Prove/Plugin/TraceUse.pm',
    requires => {
                 'Test::More' => 0,
                 'version'    => 0,
                 'App::Prove' => '3.15',
                 'Test::Perl::Critic'  => '1.02',
                 'Test::Pod::Coverage' => '1.08',
                 'Test::Most'          => '0.25',
                 'Set::Object'         => '1.26',
                 'Test::Pod'           => '1.45',
                 'File::Slurp'         => '9999.19_2_2',
                 'Tree::Simple'        => 'FOO',
    },
    add_to_cleanup      => [ 'App-Prove-Plugin-TraceUse-*' ],
);

$builder->create_build_script();
