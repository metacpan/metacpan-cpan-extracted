use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Class::DispatchToAll',
    license     => 'perl',
    requires    => {
        'Test::More' => 0,
    },
    add_to_cleanup      => ['Makefile.PL','Class-DispatchToAll-*'],
    create_makefile_pl=>'traditional',
    dist_author         => 'Thomas Klausner <domm@cpan.org>',
);

$build->create_build_script;

