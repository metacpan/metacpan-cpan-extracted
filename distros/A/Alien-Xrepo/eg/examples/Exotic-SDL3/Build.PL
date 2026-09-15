use v5.40;
use Alien::Xrepo::MB;
Alien::Xrepo::MB->new(
    module_name        => 'Exotic::SDL3',
    dist_abstract      => 'Build & install the SDL3 library family (libsdl3, image, ttf, mixer) via xrepo',
    dist_author        => 'Sanko Robinson',
    dist_version       => 'v1.0.0',
    license            => 'artistic_2',
    xrepo_update_repo  => 1,
    requires           => { 'perl'             => 'v5.40.0', 'Alien::Xrepo::Runtime' => 0, 'File::ShareDir' => '1.00' },
    configure_requires => { 'Alien::Xrepo::MB' => 0, 'Module::Build' => 0 },
    build_requires     => { 'Alien::Xrepo::MB' => 0 },
    test_requires      => { 'Test2::V0'        => 0 }
)->create_build_script;
