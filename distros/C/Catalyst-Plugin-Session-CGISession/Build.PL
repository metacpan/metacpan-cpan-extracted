use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::Session::CGISession',
    license             => 'perl',
    dist_author         => 'Thomas L. Shinnick <tshinnic@cpan.org>',
    dist_version_from   => 'lib/Catalyst/Plugin/Session/CGISession.pm',
    requires => {
        'Test::More'        => 0,
        'Catalyst'          => '5.30',
        'CGI::Session'      => 0,
        'NEXT'              => 0,
        'Carp'              => 0,
        'File::Spec'        => 0,
        'URI'               => 0,
        'URI::Find'         => 0,
        'Data::Dumper'      => 0,
    },
    create_makefile_pl => 'passthrough',
    add_to_cleanup      => [ 'Catalyst-Plugin-Session-CGISession-*' ],
    test_files         => [ glob('t/*.t'), glob('t/*/*.t') ]
);

$builder->create_build_script();
