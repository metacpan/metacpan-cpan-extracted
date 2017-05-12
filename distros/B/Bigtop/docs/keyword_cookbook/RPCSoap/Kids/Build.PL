use strict;
use Gantry::Build;

my $build = Gantry::Build->new(
    build_web_directory => 'html',
    install_web_directories =>  {
        # XXX unix specific paths
        'dev'   => '/home/httpd/html/Kids',
        'qual'  => '/home/httpd/html/Kids',
        'prod'  => '/home/httpd/html/Kids',
    },
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Kids',
    requires           => {
        'perl'      => '5',
        'Gantry'    => '3.0',
        'HTML::Prototype' => '0',
    },
    create_makefile_pl  => 'passthrough',

    # XXX unix specific paths
    script_files        => [ glob('bin/*') ],
    'recursive_test_files' => 1,

    # XXX unix specific paths
    install_path        => { script => '/usr/local/bin' },
);

$build->create_build_script;
