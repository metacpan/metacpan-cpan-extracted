use Module::Build;
my $build = new Module::Build
    (
        module_name         => 'DateTime::Calendar::Mayan',
        dist_version_from   => 'lib/DateTime/Calendar/Mayan.pm',
        author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
        license             => 'perl',
        requires            => {
            DateTime            => '0.15',
            Params::Validate    => '0.64',
        },
    );
$build->create_build_script;
