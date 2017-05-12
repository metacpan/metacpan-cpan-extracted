use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'CGI::URI2param',
    license     => 'perl',
    requires    => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CGI-URI2param-*' ],
    create_makefile_pl=>'traditional',
    dist_author         => 'Thomas Klausner <domm@zsi.at>',
);

$build->create_build_script;

