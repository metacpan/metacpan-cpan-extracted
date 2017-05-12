use Module::Build;
use lib qw(lib);

my $build_pkg = eval { require Apache::TestMB }
        ? 'Apache::TestMB' : 'Module::Build';

my $build = $build_pkg->new(
    module_name        => 'Apache2::Imager::Resize',
    license            => 'perl',
    dist_author        => 'Alexander Keusch <akeusch@mms.ag>',
    dist_version_from  => 'lib/Apache2/Imager/Resize.pm',
    build_requires     => {
        'Apache::Test' => '1.12',
        'Imager' => 0,
        'Apache2::Request' => 0,
        'File::Basename' => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme => 1,
);
$build->create_build_script;
