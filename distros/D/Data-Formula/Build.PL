use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Data::Formula',
    license             => 'perl',
    requires            => {
        'List::MoreUtils' => 0,
        'Moose'           => 0,
    },
    build_requires => {
        'Test::Most' => 0,
    },
    configure_requires  => { 'Module::Build' => '0.38' },
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    create_readme       => 1,
    add_to_cleanup      => [ 'Data-Formula-*' ],
    meta_merge => {
        resources => {
            repository => 'http://github.com/meon/Data-Formula',
            bugtracker => 'http://github.com/meon/Data-Formula/issues',
        },
        keywords => [ qw/ formula calculation variables / ],
    },
);
$build->create_build_script;

