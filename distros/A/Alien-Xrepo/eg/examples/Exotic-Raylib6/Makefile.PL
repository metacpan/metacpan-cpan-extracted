use v5.40;
use Alien::Xrepo::MM;
#
Alien::Xrepo::MM->new(
    module_name        => 'Exotic::Raylib6',
    dist_abstract      => 'Build & install raylib 6 (a C game/multimedia library) via xrepo',
    dist_author        => 'Sanko Robinson',
    dist_version       => 'v1.0.0',
    license            => 'zlib',
    xrepo_update_repo  => 1,
    requires           => { 'perl'             => 'v5.40.0', 'Alien::Xrepo::Runtime' => 0, 'File::ShareDir' => '1.00' },
    configure_requires => { 'Alien::Xrepo::MM' => 0, 'ExtUtils::MakeMaker' => 0 },
    build_requires     => { 'Alien::Xrepo::MM' => 0 },
    test_requires      => { 'Test2::V0'        => 0 }
)->Write;
