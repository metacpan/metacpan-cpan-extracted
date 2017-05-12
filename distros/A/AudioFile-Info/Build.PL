use Module::Build;
my $build = new Module::Build(
    module_name => 'AudioFile::Info',
    license => 'perl',
    requires => {
        perl => '5.6.0',
        YAML => 0
    },
    create_makefile_pl => 'traditional',
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources  => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg/audiofile-info.git',
                web  => 'https://github.com/davorg/audiofile-info',
            },
        },
    },
);
$build->create_build_script;

