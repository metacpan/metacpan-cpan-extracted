use Module::Build;
my $build = Module::Build->new(
    module_name => 'Data::Transform::ExplicitMetadata',
    license  => 'perl',
    dist_author => 'Anthony Brummett <brummett@cpan.org>',
    build_requires => {
        'Test::More'    => 0,
        'File::Temp'    => 0,
        'IO::Handle'    => 0,
    },
    requires => {
        'perl'          => '5.8.0',

        # Should come with perl
        'Exporter'      => 0,
        'Scalar::Util'  => 0,
        'Symbol'        => 0,
        'Carp'          => 0,
    },
    recommends => {
        'FileHandle::Fmode' => '0.14',
    },
);
$build->create_build_script;
