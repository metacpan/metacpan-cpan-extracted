on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'base';
    requires 'Alien::Base' => '2.40';
};

on 'configure' => sub {
    requires 'Alien::Build' => '2.40';
    requires 'Alien::Build::MM' => '2.40';
    requires 'Alien::Build::Plugin::Build::Make' => '2.40';
    requires 'Alien::Build::Plugin::Probe::Vcpkg' => '2.40';
    requires 'ExtUtils::MakeMaker' => '7.62';
};

on 'build' => sub {
    requires 'Alien::Build' => '2.40';
    requires 'Alien::Build::Plugin::Build::Autoconf' => '2.40';
    requires 'Alien::Build::Plugin::Build::Make' => '2.40';
	requires 'Alien::gmake';
    requires 'Alien::Build::Plugin::Probe::Vcpkg' => '2.40';
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
};