use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache::Hadoop::WebHDFS',
    license             => 'apache',
    dist_author         => q{Adam Faris <apache-hadoop-webhdfs@mekanix.org>},
    dist_version_from   => 'lib/Apache/Hadoop/WebHDFS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                   => 5.006,
        'WWW::Mechanize'         => 0,
        'LWP::Authen::Negotiate' => 0,
        'LWP::Debug'             => 0,
        'Carp'                   => 0,
        'parent'                 => 0,
        'File::Map'              => 0,
    },
    add_to_cleanup      => [ 'Apache-Hadoop-WebHDFS-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
