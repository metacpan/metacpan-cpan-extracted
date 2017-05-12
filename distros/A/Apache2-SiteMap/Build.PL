use strict;
use warnings;

use Module::Build;
use Apache::TestMB;

my $build_pkg = eval { require Apache::TestMB } ? 'Apache::TestMB' : 'Module::Build';

my $builder = $build_pkg->new(
    module_name         => 'Apache2::SiteMap',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@gerakines.net>',
    dist_version_from   => 'lib/Apache2/SiteMap.pm',
    requires => {
        'WWW::Google::SiteMap' => 0,
        'File::Basename' => 0,
        'Apache2::Module' => 0,
        'Apache2::RequestUtil' => 0,
        'Apache2::RequestRec' => 0,
        'Apache2::RequestIO' => 0,
        'Apache2::Const' => 0,
        'DirHandle' => 0,
        'Data::Dumper' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Apache::TestMB' => 0,
        'Apache::Test' => 0,
        'Apache::TestRequest' => 0,
        'Apache2::Const' => 0,
        'Test::More' => 0,
        'Test::Group' => 0,
    },
    add_to_cleanup => [ 'Apache2-SiteMap-*' ],
    recursive_test_files => 1,
    create_readme => 0,
    test_files => [qw/t/],
    get_options => { },
    PL_files => {
        'conf/extra.last.conf.in.PL' => 't/conf/extra.last.conf.in',
    },
);

$builder->create_build_script();

