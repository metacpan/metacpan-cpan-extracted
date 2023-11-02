use strict;
use warnings;

use Module::Build;
my $build = Module::Build->new(
    module_name => 'CPANSec-Admin',
    dist_version_from => 'lib/CPANSEC/Admin.pm',
    dynamic_config => 0,
    license  => 'perl',
    script_files => 'script/cpansec-admin',
    meta_merge => {
        x_static_install => 1,
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/CPAN-Security/CPANSEC-Admin/issues/',
            repository  => 'https://github.com/CPAN-Security/CPANSEC-Admin',
        }
    },
    test_requires => {
        'Test2::Suite' => '0',
    },
    requires => {
        'perl'                     => '5.38.0',
        'CPAN::Meta::Requirements' => 0,
        'ENV::Util'                => 0,
        'Getopt::Long'             => 0,
        'JSON'                     => 0,
        'List::Util'               => 0,
        'MetaCPAN::Client'         => 0,
        'Net::NVD'                 => 0,
        'Path::Tiny'               => 0,
        'Pod::Find'                => 0,
        'Pod::Usage'               => 0,
        'Time::Piece'              => 0,
        'URI'                      => 0,
    },
);
$build->create_build_script;
