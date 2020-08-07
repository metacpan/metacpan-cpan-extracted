on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'base';
    requires 'Alien::Base' => '2.15';
};

on 'configure' => sub {
    requires 'Alien::Build' => '2.15';
    requires 'Alien::Build::MM' => '0.32';
    requires 'Alien::Build::Plugin::Build::Make' => '0.01';
    requires 'Alien::Build::Plugin::Probe::Vcpkg' => '2.15';
    requires 'ExtUtils::MakeMaker' => '6.52';
};

on 'build' => sub {
    requires 'Alien::Build' => '2.15';
    requires 'Alien::Build::Plugin::Build::Autoconf' => '0.04';
    requires 'Alien::Build::Plugin::Build::Make';
    requires 'Alien::Build::Plugin::Probe::Vcpkg' => '2.15';
    requires 'Config';
    requires 'ExtUtils::MakeMaker';
    requires 'IPC::Cmd';
    requires 'Sort::Versions';
};

on 'test' => sub {
    requires 'Test::Alien';
    requires 'Test::More' => '0.88';
    requires 'Test2::Suite';
    requires 'Test2::V0';

    recommends 'FFI::Platypus';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
