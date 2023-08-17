#!perl
#
# may need to detect lround [C99]; hopefully perl 5.22 or higher has it,
# as that's when POSIX.pm documents adding support for it
use 5.22.0;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Algorithm::Line::Lerp',
    license            => 'bsd',
    dist_author        => 'Jeremy Mates <jmates@thrig.me>',
    dist_version_from  => 'lib/Algorithm/Line/Lerp.pm',
    include_dirs       => ['.'],
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    needs_compiler     => 1,
    release_status     => 'stable',
    sign               => 1,
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    test_requires => { 'Test2::V0' => '0.000060', },
    requires      => {
        'perl' => '5.22.0',              # POSIX lround
    },
    add_to_cleanup => ['Algorithm-Line-Lerp-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources => { repository => 'https://thrig.me/src/Algorithm-Line-Lerp.git' }
    },
);

$builder->create_build_script();
