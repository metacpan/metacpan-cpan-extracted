use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Untaint::us_date',
    license             => 'perl',
    dist_author         => q{mike south <msouth@gmail.com>},
    dist_version_from   => 'lib/CGI/Untaint/us_date.pm',
    build_requires => {
        'Test::More' => 0,
        'CGI::Untaint::date' => 0,
    },
    add_to_cleanup      => [ 'CGI-Untaint-us_date-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
