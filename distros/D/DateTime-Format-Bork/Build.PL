use Module::Build;
my $build = new Module::Build
    (
        module_name         => 'DateTime::Format::Bork',
        dist_version_from   => 'lib/DateTime/Format/Bork.pm',
        author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
        license             => 'perl',
        requires            => {
            DateTime                    => '0.1503',
            DateTime::Format::Builder   => '0.75',
        },
    );
$build->create_build_script;
