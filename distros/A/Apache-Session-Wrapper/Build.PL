use strict;
use Module::Build;

my $build_pkg =
    eval { require Apache::TestMB; 1; } ? 'Apache::TestMB' : 'Module::Build';

my $build =
    $build_pkg->new
        ( module_name     => 'Apache::Session::Wrapper',
          license         => 'perl',
          sign            => 1,
          requires        => { 'Apache::Session'  => 1.81,
                               'Class::Container' => 0,
                               'Exception::Class' => 0,
                               'Params::Validate' => 0.70,
                               'Scalar::Util'     => 0,
                             },
          build_requires => { 'File::Spec'    => 0,
                              'File::Temp'    => 0,
                              'Module::Build' => 0,
                            },
          create_makefile_pl => 'traditional',
        );

$build->create_build_script;
$build->add_to_cleanup( qw( t/session t/conf/apreq2.conf t/conf/skip ) );
