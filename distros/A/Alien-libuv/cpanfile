on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'base';
    requires 'Alien::Base' => '1.00';
};

on 'build' => sub {
    requires 'Alien::Build' => '1.00';
    requires 'Alien::Build::Plugin::Build::Make';
    requires 'Config';
    requires 'ExtUtils::MakeMaker';
    requires 'IPC::Cmd';
#    if ($^O eq 'MSWin32') {
#        requires 'Alien::Build::Plugin::Build::CMake';
#        requires 'Alien::cmake3';
#        requires 'Path::Tiny';
#    }
#    else {
#        requires 'Alien::Autotools';
#    };
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
