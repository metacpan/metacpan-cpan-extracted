use strict;
use warnings;
use Module::Build::SysPath;

use 5.010;

my $builder = Module::Build::SysPath->new(
    module_name       => 'Business::DPD::SK',
    license           => 'perl',
    dist_author       => 'Jozef Kutej',
    dist_version_from => 'lib/Business/DPD/SK.pm',

    configure_requires => {
        'Module::Build'          => '0.3607',
        'Module::Build::SysPath' => '0.20',
    },
    build_requires => {
        'Module::Build::SysPath' => '0.20',
        'Test::More'             => '0.98',
        'Test::Exception'        => 0,
        'File::Temp'             => 0,
        'IO::Compress::Zip'      => 0,
    },
    requires => {
        'perl'                  => '5.010',
        'Moo'                   => 0,
        'Moose'                 => 0,
        'namespace::autoclean'  => 0,
        'Net::SFTP::Foreign'    => 0,
        'IO::Pty'               => 0,    # Net::SFTP::Foreign password authentication
        'Config::INI::Reader'   => 0,
        'IO::Uncompress::Unzip' => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Request'         => 0,
        'JSON::XS'              => 0,
        'Carp'                  => 0,
        'File::Spec'            => 0,
    },
    file_modes => {
        'etc/dpd-sk/geordb.ini' => 0640,    # contains the SFTP password
        'etc/dpd-sk/api.ini'    => 0640,    # contains the API key
    },
    add_to_cleanup => ['Business-DPD-SK-*'],
    create_readme  => 1,
);

$builder->create_build_script();
