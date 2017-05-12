use Module::Build;

Module::Build->new(
    module_name       => 'App::perldolicious',
    license           => 'perl',
    dist_version_from => 'bin/perldolicious',
    create_license    => 1,
    create_readme     => 1,
    script_files      => ['bin/perldolicious'],
    requires          => {
        'File::Path'       => 0,
        'File::Spec'       => 0,
        'File::Temp'       => 0,
        'IO::Zlib'         => '1.10',
        'Module::CoreList' => '2.91',
        'Module::Path'     => '0.09',
        'Mojolicious'      => '4.07',
        'Mojo::UserAgent'  => 0,
        'Mojo::JSON'       => 0,
        'Pod::Cpandoc'     => '0.15',
        'Scalar::Util'     => 0,
        'Storable'         => 0,
    },
    test_requires => {
        'File::Spec'  => 0,
        'File::Which' => 0,
        'FindBin'     => 0,
        'Test::Mojo'  => 0,
        'Test::More'  => 0,
    },
    meta_merge => {
        resources => {
            homepage => 'https://github.com/Syaltut/perl-App-perldolicious',
            repository =>
              'git://github.com/Syaltut/perl-App-perldolicious.git',
        }
      }

)->create_build_script;
