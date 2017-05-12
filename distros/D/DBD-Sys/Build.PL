use Module::Build;

# See perldoc Module::Build for details of how this works

my $build = Module::Build->new(
        module_name       => 'DBD::Sys',
        dist_author       => 'Jens Rehsack <rehsack@cpan.org>, Alexander Breibach <alexander.breibach@googlemail.com>',
        dist_version_from => 'lib/DBD/Sys.pm',
        license           => 'perl',
        build_required    => { 'Test::More' => 0, },
        requires          => {
                      'DBI'               => '1.612',
                      'Module::Pluggable' => '3.9',
                      'Params::Util'      => '1.00',
                      'Scalar::Util'      => '1.00',
                      'SQL::Statement'    => '1.28',
                      ( $^O eq 'MSWin32' ? ( 'Win32::pwent' => 0.01, ) : () ),
                    },
        recommends => {
                        'DBI'            => '1.612',
                        'SQL::Statement' => '1.28',
                      },
        auto_features => {
            filesys_tables => {
                                description => "Tables containing file system data",
                                requires    => {
                                              'Sys::Filesystem'     => '1.0',
                                              'Filesys::DfPortable' => '0.83',
                                            },
                                recommends => {
                                                'Sys::Filesystem'     => '1.30',
                                                'Filesys::DfPortable' => '0.85',
                                                ( $^O eq 'MSWin32' ? ( 'Win32::DriveInfo' => 0.06, ) : () ),
                                              },
                              },
            proc_tables => {
                description => "Tables containing process information",
                requires =>
                  { ( $^O eq 'MSWin32' ? ( 'Win32::Process::Info' => 1.015, ) : ( 'Proc::ProcessTable' => '0.45' ) ), },
                recommends => { ( $^O eq 'MSWin32' ? ( 'Win32::Process::CommandLine' => 0, ) : () ), },
            },
            network_tables => {
                                description => "Tables containing network information",
                                requires    => {
                                              'Net::Interface' => '1.0000',
                                              'Socket6'        => 0,
                                            },
                                recommends => {
                                                'Net::Interface'         => '1.0012',
                                                'Net::Ifconfig::Wrapper' => '0.11',
						'NetAddr::IP'            => '4.028',
                                              },
                              },
            (
              $^O ne 'MSWin32'
              ? (
                  login_table => {
                                   description => "Table containing logged on users",
                                   requires    => { 'Sys::Utmp' => '1.6', },
                                 },
                  openfiles_table => {
                                       description => "Table containing open files",
                                       requires    => { 'Unix::Lsof' => '0.0.5', },
                                       recommends  => { 'Sys::Filesystem::MountPoint' => '1.02', },
                                     },
                )
              : ()
            ),
        },
        create_makefile_pl => 'traditional',
);
$build->create_build_script;
