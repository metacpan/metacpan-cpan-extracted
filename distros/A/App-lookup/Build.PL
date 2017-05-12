use Module::Build;

Module::Build->new(
    module_name    => 'App::lookup',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,

    dist_version_from => 'bin/lookup',
    script_files      => [qw(bin/lookup)],

    configure_requires => {
        'Module::Build' => 0.4004,
    },

    test_requires => {
        'Test::More'   => 0,
        'Test::Output' => 0,
        'FindBin'      => 0,
        'File::Spec'   => 0,
        'Text::Abbrev' => 0,
    },

    requires => {
        'Browser::Open'       => 0,
        'Config::Tiny'        => 0,
        'File::Basename'      => 0,
        'File::Spec'          => 0,
        'Getopt::Long'        => 0,
        'IPC::System::Simple' => 0,
        'List::Util'          => 0,
        'Pod::Usage'          => 0,
        'Text::Abbrev'        => 0,
        'Text::Wrap'          => 0,
        'URI::Encode'         => 0,
    },

    meta_merge => {
        resources => {
            homepage   => 'https://github.com/Syaltut/perl-App-lookup',
            repository => 'git://github.com/Syaltut/perl-App-lookup.git',
        },
    },

    no_index => {
        directory => [qw(etc t )],
    }
)->create_build_script;
