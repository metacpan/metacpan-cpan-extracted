use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CBSSports::Getopt',
    license             => 'perl',
    dist_author         => 'Jeff Bisbee <jbisbee@cpan.org>',
    dist_version_from   => 'lib/CBSSports/Getopt.pm',
    requires => {
        'Test::More'     => 0,
        'Getopt::Long'   => 0,
        'Pod::Usage'     => 0,
        'File::HomeDir'  => 0,
        'File::Basename' => 0,
        'FindBin'        => 0,
    },
    script_files       => [ 'bin/cbssports-script-starter' ],
    add_to_cleanup      => [ 'CBSSports-Getopt-*' ],
);

$builder->create_build_script();
