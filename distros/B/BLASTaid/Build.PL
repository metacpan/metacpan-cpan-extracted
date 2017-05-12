use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'BLASTaid',
    license             => 'perl',
    dist_author         => 'Todd Wylie <perldev@monkeybytes.org>',
    dist_version_from   => 'lib/BLASTaid.pm',
    script_files        => ['bin/BLASTaid'],                             
    PL_files            => {},                             
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'BLASTaid-*' ],
);

$builder->create_build_script();
