use v5.40;
use Alien::Xrepo::MB;
Alien::Xrepo::MB->new(
    module_name        => 'Alien::SDL3',
    dist_abstract      => 'Build & install the SDL3 library family (libsdl3, image, ttf, mixer) via xrepo',
    dist_author        => 'Sanko Robinson',
    dist_version       => 'v1.0.0',
    license            => 'artistic_2',
    xrepo_update_repo  => 1,
    requires           => { 'perl'             => 'v5.40.0', 'Alien::Xrepo::Runtime' => 'v1.0.4', 'File::ShareDir' => '1.00' },
    configure_requires => { 'Alien::Xrepo::MB' => 'v1.0.4', 'Module::Build' => 0 },
    build_requires     => { 'Alien::Xrepo::MB' => 'v1.0.4' },
    test_requires      => { 'Test2::V0'        => 0 },
    recommends         => { 'Affix'            => 0 }
)->create_build_script;
