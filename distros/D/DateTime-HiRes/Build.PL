use Module::Build;
my $build = new Module::Build (
        module_name         => 'DateTime::HiRes',
        dist_version_from   => 'lib/DateTime/HiRes.pm',
        author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
        license             => 'perl',
        requires            => {
            'DateTime'      => '0.17',
            'Time::HiRes'   => '1.50',
        },
    );
$build->create_build_script;
