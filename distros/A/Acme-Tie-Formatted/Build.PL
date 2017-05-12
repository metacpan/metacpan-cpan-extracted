use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::Formatted',
    license             => 'perl',
    dist_author         => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    dist_version_from   => 'lib/Tie/Formatted.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Tie-Formatted-*' ],
);

$builder->create_build_script();
