use v5.40;
use strict;
use warnings;
use Alien::Xrepo::MB;
#
Alien::Xrepo::MB->new(
    module_name        => 'Exotic::SQLite3',
    dist_abstract      => 'Build & install sqlite3 (a static lib for Inline::C-era consumers) via xrepo',
    dist_author        => 'Sanko Robinson',
    dist_version       => 'v1.0.0',
    license            => 'artistic_2',
    requires           => { 'perl'             => 'v5.40.0', 'Alien::Xrepo::Runtime' => 0, 'File::ShareDir' => '1.00' },
    configure_requires => { 'Alien::Xrepo::MB' => 0, 'Module::Build' => 0 },
    build_requires     => { 'Alien::Xrepo::MB' => 0 },
    test_requires      => { 'Test2::V0'        => 0 }
)->create_build_script;
