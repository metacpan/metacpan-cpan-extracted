#!perl
# was at 5.010, but some Windows smoke box ignored the MIN_PERL_VERSION
# and then failed all over the 5.14 features in a *.t file.
use 5.014000;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'App::MusicTools',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@cpan.org>},
    dist_version_from  => 'lib/App/MusicTools.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Test2::Tools::Command' => '0.11',
        'Test2::V0'             => '0.000060',
        'perl'                  => '5.14.0',
    },
    requires => {
        'Carp'                    => 0,
        'File::Spec'              => 0,
        'File::Temp'              => 0,
        'Getopt::Long'            => 0,
        'IPC::Run3'               => 0,
        'JSON'                    => 0,
        'List::Util'              => 0,
        'Music::AtonalUtil'       => 1.17,
        'Music::Canon'            => 2.00,
        'Music::Chord::Positions' => 0,
        'Music::LilyPondUtil'     => 0.10,
        'Music::Scala'            => 0.84,
        'Music::Scales'           => 0,
        'Music::Tempo'            => 0,
        'Music::Tension'          => 0.60,
        'Parse::Range'            => 0,
        'Scalar::Util'            => 0,
        'Text::Roman'             => 0,
        'Text::Wrap'              => 0,
        'perl'                    => '5.14.0',
    },
    sign           => 1,
    add_to_cleanup => ['App-MusicTools-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://thrig.me/src/App-MusicTools.git' } },
);

$builder->create_build_script();
