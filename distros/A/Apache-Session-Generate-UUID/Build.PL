use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache::Session::Generate::UUID',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@socklabs.com>',
    dist_version_from   => 'lib/Apache/Session/Generate/UUID.pm',
    requires => {
        'Data::UUID' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Test::Exception' => 0,
        'File::Temp' => 0,
        'Cwd' => 0,
        'Test::Group' => 0,
    },
    add_to_cleanup      => [ 'Apache-Session-Generate-UUID-*' ],
);

$builder->create_build_script();
